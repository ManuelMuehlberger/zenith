#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
import urllib.request


RELEASES_URL = "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"


def fetch_release_index() -> dict:
    with urllib.request.urlopen(RELEASES_URL) as response:
        return json.load(response)


def resolve_release(index: dict, channel: str, version: str | None) -> dict:
    releases = index.get("releases", [])
    if version:
        for release in releases:
            if release.get("channel") == channel and release.get("version") == version:
                return release
        raise SystemExit(
            f"Unable to find Flutter {channel} release for version {version}."
        )

    current_hash = index.get("current_release", {}).get(channel)
    if not current_hash:
        raise SystemExit(f"No current Flutter release hash found for channel {channel}.")

    for release in releases:
        if release.get("channel") == channel and release.get("hash") == current_hash:
            return release

    raise SystemExit(
        f"Unable to resolve current Flutter release for channel {channel}."
    )


def build_payload(index: dict, release: dict) -> dict[str, str]:
    base_url = index.get("base_url", "").rstrip("/")
    archive = release["archive"]
    return {
        "archive": archive,
        "channel": release["channel"],
        "dart_sdk_arch": release["dart_sdk_arch"],
        "dart_sdk_version": release["dart_sdk_version"],
        "download_url": f"{base_url}/{archive}",
        "hash": release["hash"],
        "release_date": release["release_date"],
        "sha256": release["sha256"],
        "version": release["version"],
    }


def emit_shell(payload: dict[str, str]) -> None:
    for key, value in payload.items():
        print(f"{key}={value}")


def emit_json(payload: dict[str, str]) -> None:
    json.dump(payload, sys.stdout, indent=2, sort_keys=True)
    print()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Resolve Flutter stable release metadata for CI image builds."
    )
    parser.add_argument(
        "--channel",
        default="stable",
        help="Flutter release channel to resolve. Defaults to stable.",
    )
    parser.add_argument(
        "--version",
        help="Exact Flutter version to resolve within the selected channel.",
    )
    parser.add_argument(
        "--output",
        choices=("github", "json", "shell"),
        default="shell",
        help="Output format. 'github' and 'shell' both emit KEY=value lines.",
    )
    args = parser.parse_args()

    index = fetch_release_index()
    release = resolve_release(index, args.channel, args.version)
    payload = build_payload(index, release)

    if args.output in {"github", "shell"}:
        emit_shell(payload)
    else:
        emit_json(payload)


if __name__ == "__main__":
    main()