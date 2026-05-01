#!/usr/bin/env python3

from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


ALLOW_COMPLEXITY = 'policy: allow-complexity'
ALLOW_BOUNDARY = 'policy: allow-boundary'
ALLOW_PUBLIC_API = 'policy: allow-public-api'
ALLOW_NO_TEST = 'policy: no-test-needed'

MAX_FUNCTION_LINES = 80
MAX_DECISION_POINTS = 10
MAX_BRACE_NESTING = 5
NON_TRIVIAL_CHANGE_LINES = 5

UI_ROOTS = ('lib/screens/', 'lib/widgets/')
NON_UI_ROOTS = ('lib/services/', 'lib/utils/', 'lib/models/', 'lib/constants/')
FRONTEND_EXEMPT_TEST_ADJACENCY = ('lib/theme/', 'lib/main.dart')
UI_IMPORT_PATTERNS = (
    'package:zenith/screens/',
    'package:zenith/widgets/',
    'package:zenith/main.dart',
)
PERSISTENCE_IMPORT_PATTERNS = (
    'package:zenith/services/dao/',
    'package:zenith/services/database_helper.dart',
    'package:zenith/services/database_service.dart',
)
INSIGHTS_PERSISTENCE_IMPORT_PATTERNS = (
    'package:zenith/services/dao/',
    'package:zenith/services/database_helper.dart',
    'package:zenith/services/database_service.dart',
)

TYPE_DECLARATION_RE = re.compile(
    r'^\s*(?:abstract\s+|base\s+|final\s+|sealed\s+|interface\s+)*'
    r'(class|enum|mixin|extension|typedef)\s+([A-Za-z][A-Za-z0-9_]*)\b'
)
EXPORT_RE = re.compile(r'^\s*export\s+[\'"]')
TOP_LEVEL_FUNCTION_RE = re.compile(
    r'^\s*(?:[A-Za-z_<>,?\[\] ]+\s+)?([a-zA-Z][A-Za-z0-9_]*)\s*\([^;]*\)\s*'
    r'(?:async\s*)?(?:=>|\{)$'
)
CONTROL_DECLARATION_RE = re.compile(
    r'^\s*(if|for|while|switch|catch|try|else|do|class|enum|mixin|extension|typedef)\b'
)
DECISION_RE = re.compile(r'\b(if|for|while|case|catch|switch)\b')


@dataclass
class FileDiff:
    path: str
    added_lines: list[tuple[int, str]]
    changed_line_numbers: set[int]
    logical_change_count: int


@dataclass
class Violation:
    file_path: str
    heading: str
    details: list[str]


def run_git(repo_root: Path, args: list[str]) -> str:
    result = subprocess.run(
        ['git', *args],
        cwd=repo_root,
        check=True,
        text=True,
        capture_output=True,
    )
    return result.stdout


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Check changed Dart files for maintainability policy violations.',
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--staged', action='store_true')
    mode.add_argument('--all', action='store_true')
    mode.add_argument('--range', nargs=2, metavar=('FROM_REF', 'TO_REF'))
    return parser.parse_args()


def collect_changed_files(repo_root: Path, args: argparse.Namespace) -> list[str]:
    if args.staged:
      output = run_git(
          repo_root,
          ['diff', '--cached', '--name-only', '--diff-filter=ACMR', '--', '*.dart'],
      )
      return [line for line in output.splitlines() if line]
    if args.range:
      from_ref, to_ref = args.range
      output = run_git(
          repo_root,
          ['diff', '--name-only', '--diff-filter=ACMR', from_ref, to_ref, '--', '*.dart'],
      )
      return [line for line in output.splitlines() if line]
    return sorted(
        str(path.relative_to(repo_root))
        for root in ('lib', 'test')
        for path in (repo_root / root).rglob('*.dart')
    )


def build_file_diff(repo_root: Path, args: argparse.Namespace, file_path: str) -> FileDiff:
    if args.all:
        file_text = (repo_root / file_path).read_text()
        lines = file_text.splitlines()
        return FileDiff(
            path=file_path,
            added_lines=[(index + 1, line) for index, line in enumerate(lines)],
            changed_line_numbers={index + 1 for index in range(len(lines))},
            logical_change_count=sum(is_logical_change_line(line) for line in lines),
        )

    diff_args = ['diff', '--unified=0', '--', file_path]
    if args.staged:
        diff_args.insert(1, '--cached')
    else:
        from_ref, to_ref = args.range
        diff_args[1:1] = [from_ref, to_ref]

    diff_output = run_git(repo_root, diff_args)
    added_lines: list[tuple[int, str]] = []
    changed_line_numbers: set[int] = set()
    logical_change_count = 0
    current_line = 0

    for raw_line in diff_output.splitlines():
        if raw_line.startswith('@@'):
            match = re.search(r'\+(\d+)', raw_line)
            if match is not None:
                current_line = int(match.group(1))
            continue
        if raw_line.startswith('+++') or raw_line.startswith('---'):
            continue
        if raw_line.startswith('+'):
            line_text = raw_line[1:]
            added_lines.append((current_line, line_text))
            changed_line_numbers.add(current_line)
            logical_change_count += int(is_logical_change_line(line_text))
            current_line += 1
            continue
        if raw_line.startswith('-'):
            logical_change_count += int(is_logical_change_line(raw_line[1:]))
            continue
        if raw_line.startswith(' '):
            current_line += 1

    return FileDiff(
        path=file_path,
        added_lines=added_lines,
        changed_line_numbers=changed_line_numbers,
        logical_change_count=logical_change_count,
    )


def is_logical_change_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return False
    if stripped in {'{', '}', '];', '),', ')', '],', '};'}:
        return False
    if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
        return False
    if stripped.startswith(('import ', 'export ', 'library ', 'part ')):
        return False
    return True


def has_file_marker(lines: list[str], marker: str) -> bool:
    return any(marker in line for line in lines)


def has_line_marker(lines: list[str], line_number: int, marker: str) -> bool:
    start = max(0, line_number - 3)
    end = min(len(lines), line_number)
    return any(marker in lines[index] for index in range(start, end))


def import_target(import_line: str) -> str | None:
    match = re.search(r'[\'"]([^\'"]+)[\'"]', import_line)
    if match is None:
        return None
    return match.group(1)


def relative_import_resolves_to(file_path: str, import_value: str) -> str | None:
    if not import_value.startswith('.'):
        return None
    resolved = (REPO_ROOT / Path(file_path).parent / import_value).resolve()
    try:
        return str(resolved.relative_to(REPO_ROOT))
    except ValueError:
        return None


def matches_any_path(candidate: str | None, patterns: tuple[str, ...]) -> bool:
    if candidate is None:
        return False
    return any(candidate.startswith(pattern) for pattern in patterns)


def architecture_violations(
    repo_root: Path,
    file_path: str,
    lines: list[str],
) -> list[Violation]:
    if has_file_marker(lines, ALLOW_BOUNDARY):
        return []

    violations: list[Violation] = []
    imports = [
        (index + 1, line, import_target(line))
        for index, line in enumerate(lines)
        if line.strip().startswith('import ')
    ]

    if file_path.startswith(NON_UI_ROOTS):
        matched = []
        for line_number, line, target in imports:
            resolved = relative_import_resolves_to(file_path, target or '')
            if matches_any_path(target, UI_IMPORT_PATTERNS) or matches_any_path(
                resolved,
                ('lib/screens/', 'lib/widgets/', 'lib/main.dart'),
            ):
                matched.append(f'{line_number}: {line.strip()}')
        if matched:
            violations.append(
                Violation(
                    file_path=file_path,
                    heading='Non-UI layers must not import screens, widgets, or main.dart',
                    details=matched,
                ),
            )

    if file_path.startswith(UI_ROOTS):
        matched = []
        for line_number, line, target in imports:
            resolved = relative_import_resolves_to(file_path, target or '')
            if matches_any_path(target, PERSISTENCE_IMPORT_PATTERNS) or matches_any_path(
                resolved,
                (
                    'lib/services/dao/',
                    'lib/services/database_helper.dart',
                    'lib/services/database_service.dart',
                ),
            ):
                matched.append(f'{line_number}: {line.strip()}')
        if matched:
            violations.append(
                Violation(
                    file_path=file_path,
                    heading='Screens and widgets must not import DAOs or low-level database services directly',
                    details=matched,
                ),
            )

    if file_path.startswith('lib/services/insights/'):
        matched = []
        for line_number, line, target in imports:
            resolved = relative_import_resolves_to(file_path, target or '')
            if matches_any_path(target, INSIGHTS_PERSISTENCE_IMPORT_PATTERNS) or matches_any_path(
                resolved,
                (
                    'lib/services/dao/',
                    'lib/services/database_helper.dart',
                    'lib/services/database_service.dart',
                ),
            ):
                matched.append(f'{line_number}: {line.strip()}')
        if matched:
            violations.append(
                Violation(
                    file_path=file_path,
                    heading='Insights code must not reach directly into persistence internals',
                    details=matched,
                ),
            )

    return violations


def extract_function_blocks(lines: list[str]) -> list[tuple[str, int, int, int, int]]:
    blocks: list[tuple[str, int, int, int, int]] = []
    line_count = len(lines)
    for index, line in enumerate(lines, start=1):
        if '{' not in line and '=>' not in line:
            continue
        statement_parts = []
        statement_start = index
        cursor = index
        while cursor >= 1 and index - cursor < 6:
            fragment = lines[cursor - 1].strip()
            if not fragment:
                break
            statement_parts.append(fragment)
            statement_start = cursor
            if fragment.endswith((';', '{', '=>')) and cursor != index:
                break
            cursor -= 1
        statement = ' '.join(reversed(statement_parts))
        if not statement or CONTROL_DECLARATION_RE.match(statement):
            continue
        if TYPE_DECLARATION_RE.match(statement):
            continue
        match = TOP_LEVEL_FUNCTION_RE.match(statement)
        if match is None:
            continue
        name = match.group(1)
        if '=>' in statement and '{' not in statement:
            blocks.append((name, statement_start, index, 0, len(DECISION_RE.findall(statement))))
            continue

        brace_depth = 0
        max_depth = 0
        decision_points = 0
        end_line = index
        started = False
        for inner_index in range(index, line_count + 1):
            current_line = lines[inner_index - 1]
            decision_points += len(DECISION_RE.findall(current_line))
            for character in current_line:
                if character == '{':
                    brace_depth += 1
                    started = True
                    max_depth = max(max_depth, brace_depth - 1)
                elif character == '}':
                    brace_depth -= 1
                    if started and brace_depth == 0:
                        end_line = inner_index
                        blocks.append((name, statement_start, end_line, max_depth, decision_points))
                        break
            if started and brace_depth == 0:
                break
    deduped: list[tuple[str, int, int, int, int]] = []
    seen: set[tuple[int, int, str]] = set()
    for block in blocks:
        key = (block[1], block[2], block[0])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(block)
    return deduped


def complexity_violations(
    file_path: str,
    lines: list[str],
    file_diff: FileDiff,
) -> list[Violation]:
    if has_file_marker(lines, ALLOW_COMPLEXITY):
        return []

    violations: list[Violation] = []
    details: list[str] = []
    for name, start_line, end_line, max_nesting, decision_points in extract_function_blocks(lines):
        if file_diff.changed_line_numbers and not any(
            start_line <= changed_line <= end_line
            for changed_line in file_diff.changed_line_numbers
        ):
            continue
        function_length = end_line - start_line + 1
        if function_length > MAX_FUNCTION_LINES:
            details.append(
                f'{start_line}: {name} spans {function_length} lines (max {MAX_FUNCTION_LINES})'
            )
        if max_nesting > MAX_BRACE_NESTING:
            details.append(
                f'{start_line}: {name} reaches nesting depth {max_nesting} (max {MAX_BRACE_NESTING})'
            )
        if decision_points > MAX_DECISION_POINTS:
            details.append(
                f'{start_line}: {name} has {decision_points} decision points (max {MAX_DECISION_POINTS})'
            )

    if details:
        violations.append(
            Violation(
                file_path=file_path,
                heading='Changed functions exceed the complexity budget',
                details=details,
            ),
        )
    return violations


def candidate_tests(repo_root: Path, file_path: str) -> list[str]:
    relative_without_extension = file_path[len('lib/'):-len('.dart')]
    pattern = f'test/{relative_without_extension}*_test.dart'
    return sorted(
        str(path.relative_to(repo_root))
        for path in repo_root.glob(pattern)
    )


def test_adjacency_violations(
    repo_root: Path,
    file_path: str,
    lines: list[str],
    file_diff: FileDiff,
    changed_files: set[str],
) -> list[Violation]:
    if file_diff.logical_change_count < NON_TRIVIAL_CHANGE_LINES:
        return []
    if file_path.startswith(FRONTEND_EXEMPT_TEST_ADJACENCY):
        return []
    if has_file_marker(lines, ALLOW_NO_TEST):
        return []

    candidates = candidate_tests(repo_root, file_path)
    if not candidates:
        return [
            Violation(
                file_path=file_path,
                heading='Non-trivial production changes require an adjacent test file',
                details=['No matching test/<path>*_test.dart file exists for this production file.'],
            ),
        ]

    if any(candidate in changed_files for candidate in candidates):
        return []

    return [
        Violation(
            file_path=file_path,
            heading='Non-trivial production changes require an adjacent test delta',
            details=[
                'Expected one of these test files to change in the same diff:',
                *candidates,
            ],
        ),
    ]


def public_api_violations(
    file_path: str,
    lines: list[str],
    file_diff: FileDiff,
) -> list[Violation]:
    if not file_diff.added_lines:
        return []

    violations: list[str] = []
    for line_number, line_text in file_diff.added_lines:
        if line_text != line_text.lstrip():
            continue
        stripped = line_text.strip()
        if not stripped or stripped.startswith('//'):
            continue
        if has_line_marker(lines, line_number, ALLOW_PUBLIC_API):
            continue
        if EXPORT_RE.match(stripped):
            violations.append(f'{line_number}: new export requires {ALLOW_PUBLIC_API}')
            continue
        type_match = TYPE_DECLARATION_RE.match(stripped)
        if type_match is not None and not type_match.group(2).startswith('_'):
            violations.append(
                f'{line_number}: new public {type_match.group(1)} {type_match.group(2)} requires {ALLOW_PUBLIC_API}'
            )
            continue
        function_match = TOP_LEVEL_FUNCTION_RE.match(stripped)
        if function_match is not None and not function_match.group(1).startswith('_'):
            violations.append(
                f'{line_number}: new public top-level function {function_match.group(1)} requires {ALLOW_PUBLIC_API}'
            )

    if not violations:
        return []

    return [
        Violation(
            file_path=file_path,
            heading='New public API surface must be explicitly annotated',
            details=violations,
        ),
    ]


def report(violations: list[Violation]) -> int:
    if not violations:
        return 0
    for violation in violations:
        print(f'ERROR: {violation.heading}')
        print(f'  {violation.file_path}')
        for detail in violation.details:
            print(f'    {detail}')
    return len(violations)


def main() -> int:
    args = parse_args()
    repo_root = REPO_ROOT
    changed_files = collect_changed_files(repo_root, args)
    if not changed_files:
        print('No changed Dart files to check for maintainability violations.')
        return 0

    print('Checking changed Dart files for maintainability violations:')
    for file_path in changed_files:
        print(f'  {file_path}')

    changed_set = set(changed_files)
    failure_count = 0
    diff_mode = not args.all
    if args.all:
        print('Note: --all runs architecture and complexity checks; diff-only checks are skipped.')

    for file_path in changed_files:
        if not file_path.startswith('lib/'):
            continue
        lines = (repo_root / file_path).read_text().splitlines()
        file_diff = build_file_diff(repo_root, args, file_path)

        failure_count += report(architecture_violations(repo_root, file_path, lines))
        failure_count += report(complexity_violations(file_path, lines, file_diff))

        if diff_mode:
            failure_count += report(
                test_adjacency_violations(repo_root, file_path, lines, file_diff, changed_set)
            )
            failure_count += report(public_api_violations(file_path, lines, file_diff))

    if failure_count > 0:
        print(f'Maintainability errors: {failure_count}')
        return 1

    print('No blocking maintainability violations found.')
    return 0


if __name__ == '__main__':
    sys.exit(main())