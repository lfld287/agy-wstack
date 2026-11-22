#!/usr/bin/env bash
# Worktree prune audit. Classifies worktrees by size, merge state, uncommitted
# work, remote/PR state, and the most recent chat that operated in them. Emits
# a table sorted by size with a suggested bucket. For an origin/* base, it
# runs git fetch by default to update the remote-tracking ref. It uses mktemp
# to store PR data. Worktree deletion stays a human-gated step in the playbook.
#
# Usage: worktree-audit.sh [-b|--base <ref>] [--no-fetch] [repo-path]
#   repo-path defaults to the current repo.
#   -b sets the ref the MERGED column checks against (e.g. origin/integration).
#   --no-fetch skips git fetch and uses local refs. PR lookups still run.
#   Without it the base is origin/HEAD, then origin/main, then origin/master.
#   origin/HEAD is the remote's default branch, not necessarily the branch PRs
#   merge into; pass -b when they differ.
set -u

base=""
fetch=1
while [ $# -gt 0 ]; do
	case "$1" in
	-b|--base) [ $# -ge 2 ] || { echo "error: $1 needs a ref" >&2; exit 2; }; base="$2"; shift 2 ;;
	--no-fetch) fetch=0; shift ;;
	-h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
	-*) echo "error: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not a git repo: $repo" >&2; exit 1; }

# Main worktree is the first entry; everything else is a candidate.
main_wt=$(git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /, ""); print; exit}')

if [ -z "$base" ]; then
	for cand in "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" origin/main origin/master; do
		[ -n "$cand" ] && git rev-parse --verify --quiet "$cand^{commit}" >/dev/null && { base="$cand"; break; }
	done
	[ -z "$base" ] && { echo "error: no base ref (origin/HEAD, origin/main, origin/master all missing); pass -b <ref>" >&2; exit 1; }
	echo "warn: no -b given; MERGED checks against $base" >&2
fi

# The base drives the merge check. The fetch is best-effort (stale is fine for
# a first pass) and runs before the check, since -b may name a branch not
# fetched yet. The explicit refspec creates it even in a single-branch clone.
case "$fetch:$base" in
1:origin/*) git fetch origin "+refs/heads/${base#origin/}:refs/remotes/$base" --quiet 2>/dev/null \
	|| echo "warn: could not fetch $base; merged column may be stale" >&2 ;;
esac
git rev-parse --verify --quiet "$base^{commit}" >/dev/null 2>&1 || { echo "error: base ref not found: $base" >&2; exit 1; }

# GNU coreutils (Linux, Homebrew gnubin) reads `stat -f` as file system status
# and `date -r` as a file, so pick the stat and date flags once.
if stat -c %Y / >/dev/null 2>&1; then
	stat_fmt=(-c '%Y %n'); fmt_day() { date -d "@$1" '+%Y-%m-%d'; }
else
	stat_fmt=(-f '%m %N'); fmt_day() { date -r "$1" '+%Y-%m-%d'; }
fi

# Normalize both forge responses with lowercase state.
prs=$(mktemp) || exit 1
trap 'rm -f "$prs"' EXIT
if command -v origin >/dev/null 2>&1 \
	&& raw=$(origin pr list --author "@me" --state all --limit 1000 \
		--json number,status,headRef,baseRef,headRefOid 2>/dev/null); then
	printf '%s' "$raw" | jq '[.[] | {number, state: (.status | ascii_downcase),
		head: .headRef, base: .baseRef, headOid: .headRefOid}]' > "$prs" 2>/dev/null
elif raw=$(gh pr list --author "@me" --state all --limit 1000 \
	--json number,state,headRefName,baseRefName,headRefOid 2>/dev/null); then
	printf '%s' "$raw" | jq '[.[] | {number, state: (.state | ascii_downcase),
		head: .headRefName, base: .baseRefName, headOid: .headRefOid}]' > "$prs" 2>/dev/null
fi
[ -s "$prs" ] || echo "[]" > "$prs"

# Chat transcript dirs for a path, per harness: Cursor, Claude Code, Pi.
# Codex and OpenCode don't group sessions by project, so they aren't searched.
# Verify pinned and active AGY sessions via steps 2–3 of worktree-cleanup.md.
slash_slug() { printf '%s' "$1" | sed 's#^/##; s#/#-#g'; }
claude_slug() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g'; }
transcript_dirs() {
	for d in "$HOME/.cursor/projects/$(slash_slug "$1")/agent-transcripts" \
		"$HOME/.claude/projects/$(claude_slug "$1")" \
		"$HOME/.pi/agent/sessions/--$(slash_slug "$1")--"; do
		[ -d "$d" ] && printf '%s\n' "$d"
	done
}
now=$(date +%s)

echo "# base: $base"
echo "# note: AGY transcripts not scanned; verify pinned/active AGY sessions"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /, ""); print}' | while IFS= read -r wt; do
	[ "$wt" = "$main_wt" ] && continue

	if [ -d "$wt" ] && size=$(du -sh "$wt" 2>/dev/null) && [ -n "$size" ]; then
		size=${size%%[[:space:]]*}
	else
		size="-"
	fi
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash merges need PR evidence in addition to this ancestry check.
	git merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

	# Track local files even when status.showUntrackedFiles hides them by default.
	if ! porcelain=$(GIT_OPTIONAL_LOCKS=0 git -C "$wt" status --porcelain --ignored=matching --untracked-files=normal 2>/dev/null); then
		dirty=unknown
	elif [ -z "$porcelain" ]; then
		dirty=clean
	else
		dirty=$(printf '%s\n' "$porcelain" | awk '
			/^\?\? / { scratch++; next }
			/^!! / { ignored++; next }
			{ wip++ }
			END {
				if (wip) { print "wip:" wip; exit }
				if (scratch) printf "scratch:%d", scratch
				if (ignored) printf "%signored:%d", scratch ? "," : "", ignored
			}')
	fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	if [ -z "$branch" ]; then remote=detached
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		if counts=$(git -C "$wt" rev-list --left-right --count "$head...refs/remotes/origin/$branch" 2>/dev/null); then
			IFS=$'\t' read -r ahead behind <<< "$counts"
			remote=""
			[ "$ahead" = 0 ] || remote="ahead$ahead"
			[ "$behind" = 0 ] || remote="${remote:+$remote/}behind$behind"
			remote=${remote:-pushed}
		else remote=unknown; fi
	else remote=no-remote; fi

	IFS=$'\t' read -r pr pr_state pr_base pr_head < <(
		[ -n "$branch" ] && jq -r --arg b "$branch" '
			first(.[] | select(.head == $b))
			| ["#\(.number)/\(.state)", .state, .base, .headOid] | @tsv
		' "$prs" 2>/dev/null
	)
	pr=${pr:--}

	# Most recent chat whose transcript operated in this worktree. Match path
	# followed by "/" or a quote so glint-482 does not match glint-482-r37.
	# Search the main repo's transcript dirs and the worktree's own.
	last="unchecked:agy"; last_ts=0
	dirs=$( { transcript_dirs "$main_wt"; transcript_dirs "$wt"; } | sort -u)
	if [ -n "$dirs" ]; then
		f=$(printf '%s\n' "$dirs" | tr '\n' '\0' | xargs -0 rg -l -0 -F -e "${wt}/" -e "${wt}\"" 2>/dev/null \
			| xargs -0 stat "${stat_fmt[@]}" 2>/dev/null | sort -rn | head -1)
		if [ -n "$f" ]; then last_ts=$(echo "$f" | awk '{print $1}')
			last=$(fmt_day "$last_ts" 2>/dev/null) || last="unchecked:agy"; fi
	fi
	recent=$([ "$last_ts" -gt 0 ] 2>/dev/null && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)

	case "$dirty" in wip:*) bucket=hold-wip ;; *)
		case "$pr" in */open|*/draft) bucket=hold-open-pr ;; *)
			if [ "$recent" = yes ]; then bucket=verify-recent-chat
			elif [ "$dirty" != clean ]; then bucket=review
			elif [ "$merged" = YES ]; then bucket=safe
			elif [ "$pr_state" = merged ] && [ "$pr_base" = "${base#origin/}" ] &&
				[ -n "$pr_head" ] && [ "$pr_head" = "$head" ]; then bucket=safe
			else bucket=review; fi ;;
		esac ;;
	esac

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh
