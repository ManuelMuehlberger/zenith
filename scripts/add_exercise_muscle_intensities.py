#!/usr/bin/env python3
"""Populate per-exercise muscle activation maps in the exercise TOML asset.

The script calls an OpenAI-compatible endpoint. For OpenRouter, set:

  OPENROUTER_API_KEY=...

It writes compact TOML fields on each exercise:

  muscle_activation = { "Quads" = 1.0, "Glutes" = 0.85, "Core" = 0.55 }
  exercise_intensity = 0.95
"""

from __future__ import annotations

import argparse
import ast
import json
import math
import os
from pathlib import Path
import re
from typing import Any

import toml
from openai import OpenAI


DEFAULT_INPUT = Path("assets/gym_exercises_complete.toml")
DEFAULT_MODEL = "google/gemini-2.5-flash"
DEFAULT_BASE_URL = "https://openrouter.ai/api/v1"

ALLOWED_MUSCLE_GROUPS = [
    "Chest",
    "Triceps",
    "Front Deltoids",
    "Core",
    "Lateral Deltoids",
    "Rear Deltoids",
    "Shoulders",
    "Biceps",
    "Lats",
    "Rotator Cuffs",
    "Quads",
    "Hamstrings",
    "Glutes",
    "Abductors",
    "Adductors",
    "Lower Back",
    "Trapezius",
    "Forearm Flexors",
    "Forearms",
    "Calves",
    "Abs",
    "Obliques",
    "Back",
    "Legs",
    "Cardio",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Add muscle_activation maps and exercise_intensity to gym_exercises_complete.toml.",
    )
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--model", default=os.getenv("OPENROUTER_MODEL", DEFAULT_MODEL))
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args()


def openrouter_client() -> OpenAI:
    api_key = os.getenv("OPENROUTER_API_KEY") or os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("Set OPENROUTER_API_KEY before running this script.")
    return OpenAI(
        api_key=api_key,
        base_url=os.getenv("OPENROUTER_BASE_URL", DEFAULT_BASE_URL),
    )


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return toml.load(handle)


def save_toml(path: Path, data: dict[str, Any]) -> None:
    header = (
        "### THE EXERCISES ARE PULLED FROM HERE FOR NOW: "
        "https://www.strengthlog.com/exercise-directory/ ###\n\n"
    )
    with path.open("w", encoding="utf-8") as handle:
        handle.write(header)
        toml.dump(data, handle)


def exercise_payload(items: list[tuple[str, dict[str, Any]]]) -> dict[str, Any]:
    payload: dict[str, Any] = {}
    for key, exercise in items:
        payload[key] = {
            "name": exercise.get("name", ""),
            "slug": exercise.get("slug", ""),
            "equipment": exercise.get("equipment", ""),
            "bodyweight": exercise.get("bodyweight", False),
            "cardio": exercise.get("cardio", False),
            "timed": exercise.get("timed", False),
            "primary_muscle_group": exercise.get("primary_muscle_group", ""),
            "secondary_muscle_groups": exercise.get("secondary_muscle_groups", []),
            "instructions": exercise.get("instructions", []),
        }
    return payload


def build_prompt(batch: dict[str, Any]) -> str:
    return f"""
You are producing structured exercise intensity data for a workout app.

For each exercise, return a `muscle_activation` map using only these muscle names:
{json.dumps(ALLOWED_MUSCLE_GROUPS)}

Rules:
- Also return `exercise_intensity` as a normalized whole-exercise scalar from 0.0 to 1.0.
- `exercise_intensity` should capture whole-body demand, systemic load, coordination,
  stability demand, and typical external loading potential.
- A barbell squat, deadlift, clean, thruster, or burpee should usually score much
  higher than a curl, triceps pushdown, or lateral raise.
- Values are normalized muscle-specific intensities from 0.0 to 1.0.
- Include the primary muscle and every meaningful secondary/stabilizer muscle.
- Compound exercises should include multiple high or moderate values. Example:
  barbell squat can include Quads 1.0, Glutes 0.85, Hamstrings 0.55,
  Core 0.55, Lower Back 0.35, Calves 0.2.
- Isolation exercises should stay narrow. Example:
  dumbbell biceps curl can include Biceps 1.0, Forearms 0.3, Front Deltoids 0.05.
- Do not inflate values for muscles that only hold posture trivially.
- Prefer biomechanical accuracy over matching the existing secondary list exactly,
  but keep the primary muscle at or near 1.0 unless the exercise is cardio/timed.
- For cardio exercises, include Cardio plus the main moving muscles.
- Round values to two decimals.

Return strictly valid JSON with this shape:
{{
  "exercise_key": {{
    "exercise_intensity": 0.0,
    "muscle_activation": {{
      "Muscle Name": 0.0
    }}
  }}
}}

Input exercises:
{json.dumps(batch, indent=2)}
"""


def parse_response(content: str) -> dict[str, Any]:
    decoded = _parse_json_like_object(content)
    if "exercises" in decoded and isinstance(decoded["exercises"], dict):
        decoded = decoded["exercises"]
    if not isinstance(decoded, dict):
        raise ValueError("Expected a JSON object keyed by exercise id")
    return decoded


def _parse_json_like_object(content: str) -> dict[str, Any]:
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        pass

    candidate = _extract_braced_object(content)
    normalized = re.sub(r",(\s*[}\]])", r"\1", candidate)

    try:
        return json.loads(normalized)
    except json.JSONDecodeError:
        pass

    literal = ast.literal_eval(normalized)
    if not isinstance(literal, dict):
        raise ValueError("Model response did not contain an object")
    return literal


def _extract_braced_object(content: str) -> str:
    start = content.find("{")
    end = content.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("Model response did not contain a JSON object")
    return content[start : end + 1]


def request_batch(
    client: OpenAI,
    model: str,
    batch_items: list[tuple[str, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    try:
        return _request_batch_once(client, model, batch_items)
    except Exception:
        if len(batch_items) == 1:
            raise
        midpoint = len(batch_items) // 2
        left = request_batch(client, model, batch_items[:midpoint])
        right = request_batch(client, model, batch_items[midpoint:])
        merged = dict(left)
        merged.update(right)
        return merged


def _request_batch_once(
    client: OpenAI,
    model: str,
    batch_items: list[tuple[str, dict[str, Any]]],
) -> dict[str, dict[str, Any]]:
    batch = exercise_payload(batch_items)
    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": "Return only valid JSON. Do not include markdown.",
            },
            {"role": "user", "content": build_prompt(batch)},
        ],
        response_format={"type": "json_object"},
    )
    content = response.choices[0].message.content or "{}"
    raw = parse_response(content)
    return {key: clean_exercise_payload(value) for key, value in raw.items()}


def clean_exercise_payload(value: Any) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError("Missing exercise payload")

    activation = value.get("muscle_activation") if isinstance(value, dict) else None
    if not isinstance(activation, dict):
        raise ValueError("Missing muscle_activation map")

    cleaned: dict[str, float] = {}
    for muscle, intensity in activation.items():
        if muscle not in ALLOWED_MUSCLE_GROUPS:
            continue
        numeric = float(intensity)
        cleaned[muscle] = round(min(max(numeric, 0.0), 1.0), 2)
    if not cleaned:
        raise ValueError("Empty muscle_activation map")

    raw_intensity = value.get("exercise_intensity", 1.0)
    exercise_intensity = round(min(max(float(raw_intensity), 0.0), 1.0), 2)
    return {
        "muscle_activation": cleaned,
        "exercise_intensity": exercise_intensity,
    }


def exercises_to_process(
    data: dict[str, Any],
    overwrite: bool,
) -> list[tuple[str, dict[str, Any]]]:
    items: list[tuple[str, dict[str, Any]]] = []
    for key, value in data.items():
        if not key.startswith("exercise_") or not isinstance(value, dict):
            continue
        if value.get("muscle_activation") and value.get("exercise_intensity") and not overwrite:
            continue
        items.append((key, value))
    return items


def main() -> None:
    args = parse_args()
    data = load_toml(args.input)
    items = exercises_to_process(data, args.overwrite)
    if args.limit is not None:
        items = items[: args.limit]

    if not items:
        print("No exercises need muscle_activation updates.")
        return

    client = openrouter_client()
    total_batches = math.ceil(len(items) / args.batch_size)
    print(f"Processing {len(items)} exercises in {total_batches} batches")

    for index in range(0, len(items), args.batch_size):
        batch_items = items[index : index + args.batch_size]
        batch_number = index // args.batch_size + 1
        print(f"Batch {batch_number}/{total_batches}")
        result = request_batch(client, args.model, batch_items)
        for key, _exercise in batch_items:
            if key in result:
                data[key]["muscle_activation"] = result[key]["muscle_activation"]
                data[key]["exercise_intensity"] = result[key]["exercise_intensity"]

        if not args.dry_run:
            save_toml(args.input, data)

    if args.dry_run:
        print(
            json.dumps(
                {
                    key: {
                        "exercise_intensity": data[key].get("exercise_intensity"),
                        "muscle_activation": data[key].get("muscle_activation"),
                    }
                    for key, _ in items
                },
                indent=2,
            )
        )
    else:
        print(f"Updated {args.input}")


if __name__ == "__main__":
    main()
