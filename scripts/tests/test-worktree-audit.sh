#!/usr/bin/env bash
set -euo pipefail

audit=$(cd -- "$(dirname -- "$0")/../../skills/poteto-mode/scripts" && pwd)/worktree-audit.sh
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
cd -- "$scratch"
scratch=$(pwd -P)
mkdir bin
export PATH="$scratch/bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=file
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
export AUDIT_TEST_PRS="$scratch/prs.json"

cat > bin/origin <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ ${AUDIT_TEST_FORGE:-gh} == origin ]] || exit 1
[[ $* == 'pr list --author @me --state all --limit 1000 --json number,status,headRef,baseRef,headRefOid' ]] || exit 2
jq '[.[] | {number, status: .state, headRef: .headRefName, baseRef: .baseRefName, headRefOid}]' "$AUDIT_TEST_PRS"
EOF
cat > bin/gh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ ${AUDIT_TEST_FORGE:-gh} == gh ]] || exit 1
[[ $* == 'pr list --author @me --state all --limit 1000 --json number,state,headRefName,baseRefName,headRefOid' ]] || exit 2
cat "$AUDIT_TEST_PRS"
EOF
chmod +x bin/origin bin/gh

git init -q -b main repo
cd repo
tree=$(git mktree </dev/null)
root=$(git commit-tree "$tree" -m root)
base=$(git commit-tree "$tree" -p "$root" -m base)
squash_head=$(git commit-tree "$tree" -p "$root" -m 'original PR head')
new_head=$(git commit-tree "$tree" -p "$squash_head" -m 'additional local work')
git update-ref refs/heads/main "$base"
git update-ref refs/heads/behind "$base"
git update-ref refs/heads/diverged "$base"
git clone -q --bare . "$scratch/remote.git"
git remote add origin "$scratch/remote.git"
git fetch -q origin
git update-ref refs/heads/behind "$root"
git update-ref refs/heads/diverged "$squash_head"

git worktree add -q -b ancestor "$scratch/already merged" "$root"
git worktree add -q -b closed "$scratch/closed" "$squash_head"
git worktree add -q -b new-commit "$scratch/new commit" "$new_head"
git worktree add -q -b squash "$scratch/squash" "$squash_head"
git worktree add -q -b wrong-base "$scratch/wrong base" "$squash_head"
git worktree add -q -b missing-oid "$scratch/missing oid" "$squash_head"
git worktree add -q "$scratch/behind" behind
git worktree add -q "$scratch/diverged" diverged
git worktree add -q -b missing "$scratch/missing" "$root"
rm -rf -- "$scratch/missing"
git worktree list --porcelain | rg 'prunable ' >/dev/null

cat > "$AUDIT_TEST_PRS" <<EOF
[
  {"number":17,"state":"CLOSED","headRefName":"closed","baseRefName":"main","headRefOid":"$squash_head"},
  {"number":18,"state":"MERGED","headRefName":"new-commit","baseRefName":"main","headRefOid":"$squash_head"},
  {"number":19,"state":"MERGED","headRefName":"squash","baseRefName":"main","headRefOid":"$squash_head"},
  {"number":20,"state":"MERGED","headRefName":"wrong-base","baseRefName":"other","headRefOid":"$squash_head"},
  {"number":21,"state":"MERGED","headRefName":"missing-oid","baseRefName":"main","headRefOid":null}
]
EOF

for forge in gh origin; do
  output="$scratch/audit-$forge"
  AUDIT_TEST_FORGE=$forge "$audit" -b origin/main --no-fetch "$scratch/repo" > "$output"
  rg -q '^# note: AGY transcripts not scanned;' "$output"
  if ! awk -F '\t' -v scratch="$scratch" '
    function check(path, merged, remote, pr, bucket) {
      path = scratch "/" path
      expected[path] = merged FS remote FS pr FS bucket
    }
    BEGIN {
      check("already merged", "YES", "no-remote", "-", "safe")
      check("closed", "no", "no-remote", "#17/closed", "review")
      check("new commit", "no", "no-remote", "#18/merged", "review")
      check("squash", "no", "no-remote", "#19/merged", "safe")
      check("wrong base", "no", "no-remote", "#20/merged", "review")
      check("missing oid", "no", "no-remote", "#21/merged", "review")
      check("behind", "YES", "behind1", "-", "safe")
      check("diverged", "no", "ahead1/behind1", "-", "review")
      check("missing", "no", "detached", "-", "review")
    }
    /^#/ || /^SIZE\t/ { next }
    {
      if (NF != 9 || $1 == "" || $7 != "unchecked:agy" ||
          !($9 in expected) || ($3 FS $5 FS $6 FS $8) != expected[$9] ||
          ($9 == scratch "/missing" && $1 != "-")) {
        print "unexpected row: " $0 > "/dev/stderr"
        failed = 1
      }
      delete expected[$9]
    }
    END {
      for (path in expected) {
        print "missing row: " path > "/dev/stderr"
        failed = 1
      }
      exit failed
    }
  ' "$output"; then
    cat "$output" >&2
    exit 1
  fi
done

echo 'PASS worktree audit: ancestry, PR state/base/head, remote divergence, prunable size, AGY notice'
