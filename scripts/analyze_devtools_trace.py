#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            'Summarize Flutter DevTools Performance and CPU Profiler exports.'
        ),
    )
    parser.add_argument('paths', nargs='+', help='One or more DevTools JSON files')
    parser.add_argument(
        '--top',
        type=int,
        default=10,
        help='How many top frames/hotspots to print (default: 10)',
    )
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    with path.open() as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f'{path} does not contain a top-level JSON object')
    return data


def percentile(values: list[int], quantile: float) -> int:
    if not values:
        return 0
    sorted_values = sorted(values)
    index = max(0, min(len(sorted_values) - 1, int(len(sorted_values) * quantile) - 1))
    return sorted_values[index]


def summarize_performance(path: Path, payload: dict[str, Any], top: int) -> str:
    performance = payload['performance']
    frames = performance.get('flutterFrames', [])
    if not frames:
      return f'FILE {path.name}\nTYPE performance\nNo flutterFrames found.\n'

    refresh_rate = performance.get('displayRefreshRate') or 60
    frame_budget = 1_000_000 / refresh_rate
    raster = [frame['raster'] for frame in frames]
    build = [frame['build'] for frame in frames]
    elapsed = [frame['elapsed'] for frame in frames]
    over_raster = [frame for frame in frames if frame['raster'] > frame_budget]
    over_build = [frame for frame in frames if frame['build'] > frame_budget]
    over_elapsed = [frame for frame in frames if frame['elapsed'] > frame_budget]

    lines = [
        f'FILE {path.name}',
        'TYPE performance',
        f'refresh_hz {refresh_rate}',
        f'frame_budget_us {frame_budget:.2f}',
        f'frame_count {len(frames)}',
        f'raster_over_budget {len(over_raster)}',
        f'build_over_budget {len(over_build)}',
        f'elapsed_over_budget {len(over_elapsed)}',
        f'avg_build_us {statistics.mean(build):.1f}',
        f'avg_raster_us {statistics.mean(raster):.1f}',
        f'p95_build_us {percentile(build, 0.95)}',
        f'p95_raster_us {percentile(raster, 0.95)}',
        f'max_build_us {max(build)}',
        f'max_raster_us {max(raster)}',
        f'max_elapsed_us {max(elapsed)}',
        f'selected {performance.get("selectedFrameId")}',
        '',
        'WORST_BY_RASTER',
    ]

    for frame in sorted(frames, key=lambda item: item['raster'], reverse=True)[:top]:
        lines.append(
            ' '.join(
                [
                    str(frame['number']),
                    f'elapsed {frame["elapsed"]}',
                    f'build {frame["build"]}',
                    f'raster {frame["raster"]}',
                    f'vsync {frame.get("vsyncOverhead")}',
                ],
            ),
        )

    lines.append('')
    lines.append('WORST_BY_BUILD')
    for frame in sorted(frames, key=lambda item: item['build'], reverse=True)[:top]:
        lines.append(
            ' '.join(
                [
                    str(frame['number']),
                    f'elapsed {frame["elapsed"]}',
                    f'build {frame["build"]}',
                    f'raster {frame["raster"]}',
                    f'vsync {frame.get("vsyncOverhead")}',
                ],
            ),
        )

    selected_frame = next(
        (
            frame
            for frame in frames
            if frame.get('number') == performance.get('selectedFrameId')
        ),
        None,
    )
    lines.append('')
    lines.append(f'SELECTED {selected_frame}')
    lines.append('')
    return '\n'.join(lines)


def stack_frame_url(stack_frame: dict[str, Any]) -> str:
    return (stack_frame.get('packageUri') or stack_frame.get('resolvedUrl') or '').strip()


def summarize_cpu(path: Path, payload: dict[str, Any], top: int) -> str:
    cpu = payload['cpu-profiler']
    stack_frames: dict[str, dict[str, Any]] = cpu.get('stackFrames', {})
    trace_events = cpu.get('traceEvents', [])

    top_files: Counter[str] = Counter()
    top_app_frames: Counter[str] = Counter()
    top_leaf_names: Counter[str] = Counter()
    report_task_ids: defaultdict[str, Counter[str]] = defaultdict(Counter)

    for event in trace_events:
        frame_id = event.get('sf')
        if frame_id in stack_frames:
            frame = stack_frames[frame_id]
            leaf_name = frame.get('name', 'unnamed')
            top_leaf_names[leaf_name] += 1
            report_task_ids[leaf_name][frame_id] += 1

        current = frame_id
        seen: set[str] = set()
        while current and current != 'cpuProfileRoot' and current not in seen:
            seen.add(current)
            frame = stack_frames.get(current)
            if frame is None:
                break
            url = stack_frame_url(frame)
            if 'package:zenith/' in url:
                top_files[url] += 1
                top_app_frames[current] += 1
            current = frame.get('parent')

    lines = [
        f'FILE {path.name}',
        'TYPE cpu-profiler',
        f'sampleCount {cpu.get("sampleCount")}',
        f'traceEvents {len(trace_events)}',
        '',
        'TOP_APP_FILES',
    ]

    for url, count in top_files.most_common(top):
        lines.append(f'{count} {url}')

    lines.append('')
    lines.append('TOP_APP_FRAMES')
    for frame_id, count in top_app_frames.most_common(top):
        frame = stack_frames.get(frame_id, {})
        lines.append(
            f'{count} {frame.get("name", "unnamed")} | '
            f'{stack_frame_url(frame)} {frame.get("sourceLine")}'
        )

    lines.append('')
    lines.append('TOP_LEAF_NAMES')
    for name, count in top_leaf_names.most_common(top):
        lines.append(f'{count} {name}')

    lines.append('')
    lines.append('REPORT_TASK_EVENT_PATHS')
    for frame_id, count in report_task_ids.get('_reportTaskEvent', Counter()).most_common(top):
        current = frame_id
        seen: set[str] = set()
        path_parts: list[str] = []
        while current and current != 'cpuProfileRoot' and current not in seen and len(path_parts) < 12:
            seen.add(current)
            frame = stack_frames.get(current)
            if frame is None:
                break
            path_parts.append(frame.get('name', 'unnamed'))
            current = frame.get('parent')
        lines.append(f'{count} {" -> ".join(path_parts)}')

    lines.append('')
    return '\n'.join(lines)


def summarize(path: Path, top: int) -> str:
    payload = load_json(path)
    if 'performance' in payload:
        return summarize_performance(path, payload, top)
    if 'cpu-profiler' in payload:
        return summarize_cpu(path, payload, top)
    return f'FILE {path.name}\nTYPE unsupported\nKeys: {sorted(payload.keys())}\n'


def main() -> int:
    args = parse_args()
    outputs: list[str] = []
    for raw_path in args.paths:
        path = Path(raw_path).expanduser().resolve()
        outputs.append(summarize(path, args.top))
    print('\n'.join(outputs).rstrip())
    return 0


if __name__ == '__main__':
    raise SystemExit(main())