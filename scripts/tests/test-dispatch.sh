#!/usr/bin/env bash
set -euo pipefail

dispatch=$(cd -- "$(dirname -- "$0")/.." && pwd)/multi-model-dispatch.sh
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
cd -P -- "$scratch"
scratch=$(pwd -P)
mkdir -p bin 'work dir' results
export PATH="bin:$PATH"
export DISPATCH_TEST_TRACE="$scratch"

cat > bin/codex <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1-} == -p || ${1-} == mcp ]]; then
  printf '%s\n' "$PWD" "$@" > "$DISPATCH_TEST_TRACE/mcp.argv"
  if IFS= read -r line || [[ -n $line ]]; then
    echo 'mcp list read the model prompt' >&2
    exit 99
  fi
  [[ ${DISPATCH_TEST_MCP:-disabled} != error ]] || exit 42
  printf '%-12s  %-12s  %-8s  %s\n' Name Command Status Auth
  printf '%-12s  %-12s  %-8s  %s\n' enabled enabled disabled Unsupported
  printf '%-12s  %-12s  %-8s  %s\n' server server "${DISPATCH_TEST_MCP:-disabled}" Unsupported
  exit 0
fi
printf '%s\n' "$@" > "$DISPATCH_TEST_TRACE/codex.argv"
[[ $1 == exec ]] || exit 99
while [[ $# -gt 0 ]]; do
  if [[ $1 == -o ]]; then
    cat > "$2"
    exit
  fi
  shift
done
exit 99
EOF

cat > bin/pi <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$PWD" "$@" > "$DISPATCH_TEST_TRACE/pi.argv"
cat
exit "${DISPATCH_TEST_PI_EXIT:-0}"
EOF
chmod +x bin/codex bin/pi

fail() {
  printf 'FAIL dispatch: %s\n' "$*" >&2
  exit 1
}

expect_exit() {
  local expected=$1 actual=0
  shift
  "$dispatch" "$@" > stdout 2> stderr || actual=$?
  if [[ $actual != "$expected" ]]; then
    cat stdout stderr >&2
    fail "expected exit $expected, got $actual for $*"
  fi
}

expect_exit 0 --help
rg -q 'readonly' stdout
expect_exit 2 --engine
expect_exit 2 --engine codex --model --cwd 'work dir'
expect_exit 2 --prompt one --prompt-file two

codex=(--engine codex --model profile:reviewer-codex --cwd './work dir' --mode readonly)
pi=(--engine pi --model provider/model:high --cwd './work dir' --mode readonly)
expect_exit 2 "${pi[@]}" --skip-git-check --output results/pi --prompt test

printf 'first line\nlast line\n\n' > 'prompt file'
printf 'before\000after\n' > nul-prompt
expect_exit 2 "${codex[@]}" --output results/codex --prompt-file nul-prompt
rg -q 'NUL' stderr
expect_exit 2 "${codex[@]}" --output './prompt file' --prompt-file 'prompt file'
rg -q '同一个文件' stderr
[[ ! -e mcp.argv && ! -e codex.argv && ! -e pi.argv ]] || fail 'invalid arguments started an engine'

expect_exit 0 "${codex[@]}" --output results/codex --prompt-file 'prompt file' --skip-git-check
cmp 'prompt file' results/codex
printf '%s\n' "$scratch/work dir" -p reviewer-codex mcp list | diff -u - mcp.argv
printf '%s\n' exec -s read-only -C "$scratch/work dir" --ephemeral -o "$scratch/results/codex" \
  -p reviewer-codex --skip-git-repo-check - | diff -u - codex.argv

rm -- codex.argv
for state in enabled error; do
  export DISPATCH_TEST_MCP=$state
  expect_exit 2 --engine codex --model sample --cwd 'work dir' --mode readonly \
    --output results/rejected --prompt test
  rg -q 'MCP|mcp list' stderr
  printf '%s\n' "$scratch/work dir" mcp list | diff -u - mcp.argv
  [[ ! -e codex.argv && ! -e results/rejected ]] || fail "started Codex after MCP preflight: $state"
done
unset DISPATCH_TEST_MCP

printf 'old output\n' > results/pi
expect_exit 0 "${pi[@]}" --output results/pi --prompt-file 'prompt file'
cmp 'prompt file' results/pi
printf '%s\n' "$scratch/work dir" -p --no-session --model provider/model:high \
  --tools read,grep,find,ls --no-extensions | diff -u - pi.argv

export DISPATCH_TEST_PI_EXIT=37
expect_exit 37 "${pi[@]}" --output results/pi --prompt 'failed with partial stdout'
cmp 'prompt file' results/pi
expect_exit 37 "${pi[@]}" --output results/absent --prompt 'failed with partial stdout'
[[ ! -e results/absent ]] || fail 'failed Pi invocation created its output'
[[ $(find results -type f | sort) == $'results/codex\nresults/pi' ]] || fail 'temporary output was not cleaned up'
unset DISPATCH_TEST_PI_EXIT
rm -- pi.argv

mkdir -p 'work dir/.pi/commands'
expect_exit 2 "${pi[@]}" --output results/refused --prompt test
rg -q '\.pi/commands' stderr
[[ ! -e pi.argv && ! -e results/refused ]] || fail 'started Pi with legacy commands'

echo 'PASS dispatch: arguments, prompt bytes and paths, Codex MCP, and Pi readonly/output'
