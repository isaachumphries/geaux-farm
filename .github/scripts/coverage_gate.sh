#!/usr/bin/env bash
# Filters generated code out of an lcov report, writes a per-file and total
# line coverage table as Markdown, and fails when the total is below the
# threshold.
#
# Usage: coverage_gate.sh <lcov.info> <min-percent> [summary.md]
#   - Rewrites <lcov.info> in place without any `*.g.dart` records.
#   - Appends the table to [summary.md] (defaults to $GITHUB_STEP_SUMMARY,
#     or stdout when that is unset).
#   - Exits 1 when total line coverage < <min-percent>.
set -euo pipefail

lcov_file="${1:?usage: coverage_gate.sh <lcov.info> <min-percent> [summary.md]}"
min_percent="${2:?usage: coverage_gate.sh <lcov.info> <min-percent> [summary.md]}"
summary="${3:-${GITHUB_STEP_SUMMARY:-/dev/stdout}}"

if [[ ! -s "$lcov_file" ]]; then
  echo "::error::Coverage report $lcov_file is missing or empty."
  exit 1
fi

# Drop every record (SF: ... end_of_record) whose source file is generated.
filtered="$(mktemp)"
awk '
  /^SF:/ { skip = ($0 ~ /\.g\.dart$/) }
  !skip { print }
  /^end_of_record$/ { skip = 0 }
' "$lcov_file" >"$filtered"
mv "$filtered" "$lcov_file"

# Count instrumented (DA) lines per file; a line is hit when its count > 0.
# Keyed by file:line so a file reported twice is not double counted.
awk -v min="$min_percent" -v summary="$summary" '
  /^SF:/ { file = substr($0, 4); files[file] = 1; next }
  /^DA:/ {
    split(substr($0, 4), da, ",")
    key = file SUBSEP da[1]
    if (!(key in seen)) { seen[key] = 0; found[file]++ }
    if (da[2] + 0 > 0 && !seen[key]) { seen[key] = 1; hit[file]++ }
  }
  END {
    total_found = 0; total_hit = 0
    for (f in files) { total_found += found[f]; total_hit += hit[f] }
    if (total_found == 0) {
      print "::error::Coverage report has no instrumented lines after removing *.g.dart."
      exit 1
    }
    pct = 100 * total_hit / total_found
    status = (pct + 1e-9 >= min) ? "passed" : "failed"

    printf "## Line coverage (hand-written code, `*.g.dart` excluded)\n\n" >> summary
    printf "**Total: %.2f%%** (%d / %d lines), minimum %s%%: **%s**\n\n", \
      pct, total_hit, total_found, min, status >> summary
    printf "<details><summary>Per-file coverage (lowest first)</summary>\n\n" >> summary
    printf "| File | Lines hit | Lines | Coverage |\n|---|---:|---:|---:|\n" >> summary
    # Lowest coverage first so gaps are visible without scrolling.
    close(summary)
    cmd = "sort -t \"\t\" -k1,1n -k2,2 | cut -f3- >> \"" summary "\""
    for (f in files) {
      n = found[f] + 0; h = hit[f] + 0
      p = (n > 0) ? 100 * h / n : 100
      printf "%09.4f\t%s\t| `%s` | %d | %d | %.1f%% |\n", p, f, f, h, n, p | cmd
    }
    close(cmd)
    printf "\n</details>\n" >> summary

    printf "Total line coverage: %.2f%% (%d / %d), minimum %s%%\n", \
      pct, total_hit, total_found, min
    if (status == "failed") {
      printf "::error::Hand-written line coverage %.2f%% is below the %s%% minimum. Add tests for the uncovered code (see the job summary for per-file numbers).\n", \
        pct, min
      exit 1
    }
  }
' "$lcov_file"
