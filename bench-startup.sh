#!/bin/zsh
# Benchmark zsh startup time over multiple iterations.
# Usage: ./bench-startup.sh [--threshold MS] [--iterations N] [--warmup N]
#
# Exit 1 if median exceeds threshold (for CI).
set -e

ITERATIONS=20
WARMUP=3
THRESHOLD=""  # ms, empty = no assertion

while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)  THRESHOLD=$2; shift 2 ;;
    --iterations) ITERATIONS=$2; shift 2 ;;
    --warmup)     WARMUP=$2; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--threshold MS] [--iterations N] [--warmup N]"
      echo "  --threshold   Fail if median startup exceeds this (ms)"
      echo "  --iterations  Number of timed runs (default: 20)"
      echo "  --warmup      Warmup runs before timing (default: 3)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

export TERM=${TERM:-xterm-256color}
export PATH="$HOME/.local/bin:$PATH"

# Warmup: prime caches, compinit dump, p10k instant prompt
echo "Warming up ($WARMUP runs)..."
for ((i = 1; i <= WARMUP; i++)); do
  zsh -i -c exit 2>/dev/null
done

# Collect timings using zsh's built-in EPOCHREALTIME
echo "Benchmarking ($ITERATIONS runs)..."
times=()
for ((i = 1; i <= ITERATIONS; i++)); do
  # Use zsh -c with EPOCHREALTIME to measure from inside
  t=$(zsh -c '
    zmodload zsh/datetime
    start=$EPOCHREALTIME
    # Source the full interactive init
    emulate zsh -c "source ~/.zshrc" 2>/dev/null
    end=$EPOCHREALTIME
    printf "%.1f" $(( (end - start) * 1000 ))
  ' 2>/dev/null)
  times+=($t)
  printf "  run %2d: %s ms\n" "$i" "$t"
done

# Sort numerically
sorted=(${(n)times})

# Stats
n=${#sorted}
median=${sorted[$(( (n + 1) / 2 ))]}
p95=${sorted[$(( n * 95 / 100 + 1 > n ? n : n * 95 / 100 + 1 ))]}
min=${sorted[1]}
max=${sorted[$n]}

# Mean (use awk for float division)
sum=0
for t in $times; do sum=$(( sum + t )); done
mean=$(printf "%s %s" "$sum" "$n" | awk '{printf "%.1f", $1 / $2}')

echo ""
echo "=== Results (${n} runs) ==="
echo "  min:    ${min} ms"
echo "  max:    ${max} ms"
echo "  mean:   ${mean} ms"
echo "  median: ${median} ms"
echo "  p95:    ${p95} ms"

if [[ -n $THRESHOLD ]]; then
  echo ""
  # Compare using awk to handle floats
  result=$(printf "%s %s" "$median" "$THRESHOLD" | awk '{print ($1 > $2) ? "FAIL" : "PASS"}')
  if [[ $result == "FAIL" ]]; then
    echo "FAIL: median ${median} ms exceeds threshold ${THRESHOLD} ms"
    exit 1
  else
    echo "PASS: median ${median} ms <= threshold ${THRESHOLD} ms"
  fi
fi
