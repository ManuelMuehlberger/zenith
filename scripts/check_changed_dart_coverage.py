#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
FRONTEND_EXEMPT_ROOTS = (
    'lib/screens/',
    'lib/widgets/',
    'lib/theme/',
    'lib/main.dart',
)
DEFAULT_MIN_COVERAGE = os.environ.get('ZENITH_MIN_CHANGED_FILE_COVERAGE', '80')
COVERAGE_EXCEPTIONS = {
    'lib/models/typedefs.dart',
    'lib/services/insights/insight_data_provider.dart',
}

COVERAGE_DIR = REPO_ROOT / 'coverage'
COVERAGE_REPORT = COVERAGE_DIR / 'lcov.info'
CACHE_DIR = REPO_ROOT / '.dart_tool' / 'coverage_gate'
CACHE_REPORT = CACHE_DIR / 'lcov.info'
CACHE_FINGERPRINT = CACHE_DIR / 'fingerprint.txt'


@dataclass(frozen=True)
class CoverageRecord:
    hit: int
    found: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            'Run the full Flutter test suite with coverage when needed, require '
            'that all tests pass, and enforce changed-file coverage thresholds '
            'for non-frontend Dart files.'
        ),
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--staged', action='store_true')
    mode.add_argument('--range', nargs=2, metavar=('FROM_REF', 'TO_REF'))
    mode.add_argument('--all', action='store_true')
    parser.add_argument('--min', default=DEFAULT_MIN_COVERAGE)
    return parser.parse_args()


def run_git(args: list[str]) -> str:
    result = subprocess.run(
        ['git', *args],
        cwd=REPO_ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout


def validate_min_coverage(raw_value: str) -> float:
    try:
        return float(raw_value)
    except ValueError as exc:
        raise SystemExit(
            f'Coverage threshold must be numeric, got: {raw_value}'
        ) from exc


def collect_changed_files(args: argparse.Namespace) -> list[str]:
    if args.staged:
        output = run_git(
            ['diff', '--cached', '--name-only', '--diff-filter=ACMR', '--', '*.dart'],
        )
        return [line for line in output.splitlines() if line]

    if args.range:
        from_ref, to_ref = args.range
        output = run_git(
            ['diff', '--name-only', '--diff-filter=ACMR', from_ref, to_ref, '--', '*.dart'],
        )
        return [line for line in output.splitlines() if line]

    return sorted(
        str(path.relative_to(REPO_ROOT))
        for path in (REPO_ROOT / 'lib').rglob('*.dart')
    )


def is_frontend_file(file_path: str) -> bool:
    return any(file_path.startswith(prefix) for prefix in FRONTEND_EXEMPT_ROOTS)


def files_requiring_coverage(changed_files: list[str]) -> list[str]:
    required: list[str] = []
    for file_path in changed_files:
        if not file_path.startswith('lib/'):
            continue
        if is_frontend_file(file_path):
            continue
        if file_path in COVERAGE_EXCEPTIONS:
            continue
        required.append(file_path)
    return required


def iter_fingerprint_sources() -> list[str]:
    sources = [
        *(str(path.relative_to(REPO_ROOT)) for path in (REPO_ROOT / 'lib').rglob('*.dart')),
        *(str(path.relative_to(REPO_ROOT)) for path in (REPO_ROOT / 'test').rglob('*.dart')),
        'pubspec.yaml',
        'scripts/check_changed_dart_coverage.py',
        'scripts/check_changed_dart_coverage.sh',
    ]
    if (REPO_ROOT / 'pubspec.lock').exists():
        sources.append('pubspec.lock')
    return sorted(sources)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(65536), b''):
            digest.update(chunk)
    return digest.hexdigest()


def build_fingerprint() -> str:
    digest = hashlib.sha256()
    for relative_path in iter_fingerprint_sources():
        absolute_path = REPO_ROOT / relative_path
        if not absolute_path.exists():
            continue
        digest.update(f'{file_sha256(absolute_path)}  {relative_path}\n'.encode())
    return digest.hexdigest()


def print_cache_debug(current: str, cached: str | None) -> None:
    if os.environ.get('ZENITH_COVERAGE_CACHE_DEBUG'):
        cached_value = cached if cached else 'missing'
        print(
            f'Coverage cache fingerprint: current={current} cached={cached_value}'
        )


def ensure_test_and_coverage_report() -> None:
    fingerprint = build_fingerprint()
    cached_fingerprint = None
    if CACHE_FINGERPRINT.exists():
        cached_fingerprint = CACHE_FINGERPRINT.read_text().strip() or None

    print_cache_debug(fingerprint, cached_fingerprint)

    COVERAGE_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    cache_enabled = not os.environ.get('ZENITH_DISABLE_COVERAGE_CACHE')
    if (
        cache_enabled
        and CACHE_REPORT.exists()
        and cached_fingerprint == fingerprint
    ):
        shutil.copy2(CACHE_REPORT, COVERAGE_REPORT)
        print('Reusing cached full-suite test+coverage report.')
        return

    print('Refreshing full-suite test+coverage report with flutter test --coverage...')
    result = subprocess.run(
        ['flutter', 'test', '--coverage'],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        if result.stdout:
            sys.stderr.write(result.stdout)
        if result.stderr:
            sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode)

    if not COVERAGE_REPORT.exists():
        raise SystemExit(f'{COVERAGE_REPORT.relative_to(REPO_ROOT)} was not generated.')

    shutil.copy2(COVERAGE_REPORT, CACHE_REPORT)
    CACHE_FINGERPRINT.write_text(f'{fingerprint}\n')


def parse_lcov(report_path: Path) -> dict[str, CoverageRecord]:
    records: dict[str, CoverageRecord] = {}
    current_file: str | None = None
    found: int | None = None
    hit: int | None = None

    for raw_line in report_path.read_text().splitlines():
        if raw_line.startswith('SF:'):
            current_file = raw_line[3:]
            found = None
            hit = None
            continue
        if current_file is None:
            continue
        if raw_line.startswith('LF:'):
            found = int(raw_line[3:])
            continue
        if raw_line.startswith('LH:'):
            hit = int(raw_line[3:])
            continue
        if raw_line == 'end_of_record':
            if found is not None and hit is not None:
                records[current_file] = CoverageRecord(hit=hit, found=found)
            current_file = None
            found = None
            hit = None

    return records


def report_coverage_failures(
    files_to_check: list[str],
    coverage_records: dict[str, CoverageRecord],
    min_coverage: float,
) -> int:
    failure_count = 0

    for file_path in files_to_check:
        record = coverage_records.get(file_path)
        if record is None:
            print(
                f'FAIL: {file_path} is missing from coverage/lcov.info. '
                'Add or update tests that exercise it.'
            )
            failure_count += 1
            continue

        if record.found == 0:
            print(f'SKIP: {file_path} has no executable lines in coverage output.')
            continue

        percent = (100.0 * record.hit) / record.found
        if percent >= min_coverage:
            print(
                f'PASS: {file_path} coverage {percent:.2f}% '
                f'({record.hit}/{record.found})'
            )
            continue

        print(
            f'FAIL: {file_path} coverage {percent:.2f}% '
            f'({record.hit}/{record.found}) is below {min_coverage:.0f}%'
        )
        failure_count += 1

    return failure_count


def main() -> int:
    args = parse_args()
    min_coverage = validate_min_coverage(args.min)
    changed_files = collect_changed_files(args)

    if not changed_files:
        print('No changed Dart files require test or coverage validation.')
        return 0

    files_to_check = files_requiring_coverage(changed_files)

    if files_to_check:
        print(
            'Checking changed non-frontend Dart files for minimum coverage '
            f'({min_coverage:.0f}%):'
        )
        for file_path in files_to_check:
            print(f'  {file_path}')
    else:
        print('No changed non-frontend Dart files require coverage enforcement.')

    ensure_test_and_coverage_report()

    if not files_to_check:
        print('All Dart tests passed.')
        return 0

    coverage_records = parse_lcov(COVERAGE_REPORT)
    failure_count = report_coverage_failures(
        files_to_check,
        coverage_records,
        min_coverage,
    )
    if failure_count:
        print(f'Coverage enforcement failures: {failure_count}')
        return 1

    print('All Dart tests passed and changed non-frontend Dart files meet the coverage threshold.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())