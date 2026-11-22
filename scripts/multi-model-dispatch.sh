#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
用法
  multi-model-dispatch.sh --help
  multi-model-dispatch.sh --check
  multi-model-dispatch.sh --engine <codex|pi> --model <slug-or-profile>
    --cwd <目录> --mode <readonly|write> --output <文件>
    (--prompt-file <文件> | --prompt <文本>) [--skip-git-check]

  --check            检查本地 CLI、Codex 登录和 Pi 模型目录，不发起推理。
                     Pi 在临时空目录探测，无模型条目时报告 catalog-empty。
  --model            Codex 可用 profile:<名称>，Pi 可用 provider/model:high。
  --cwd              模型的工作目录。
  --mode             readonly 限制模型工具，write 允许执行实现任务。
  --output           预先创建父目录，每次任务使用独立结果文件。
  --prompt-file      读取提示词文件，与 --prompt 二选一。两种引擎均从 stdin 读取。
  --skip-git-check   仅 Codex 可用。允许在非 Git 目录运行。
  -h, --help         显示此帮助。

相对路径以调用脚本时的目录为基准。诊断信息由各 CLI 输出，
分发时透传进程退出码。--check 只报告状态，退出码为 0。

readonly 模式
  Codex 使用 read-only 沙箱。mcp list 失败或存在启用的 MCP 时拒绝启动。
  禁用可写 MCP 后确认清单无 enabled 项，或选择只读 profile:reviewer-codex。
  Pi 仅开放 read,grep,find,ls 并停用扩展，项目需要迁移 .pi/commands 时拒绝启动。
  Pi 仅在成功退出后替换输出文件。
EOF
}

die() {
  printf 'multi-model-dispatch: %s\n' "$*" >&2
  exit 2
}

normalize_path() {
  local rest=${PATH-}: entry normalized=
  while [[ $rest == *:* ]]; do
    entry=${rest%%:*}
    rest=${rest#*:}
    [[ $entry == /* ]] || entry=${PWD%/}/${entry:-.}
    normalized=${normalized:+$normalized:}$entry
  done
  export PATH=$normalized
}

resolve_engine() {
  local binary
  binary=$(command -v "$1") || return 1
  [[ $binary == /* ]] || binary=$PWD/$binary
  [[ -f $binary && -x $binary ]] || return 1
  printf '%s\n' "$binary"
}

probe_catalog() (
  local probe_dir
  probe_dir=$(mktemp -d) || return 1
  [[ $probe_dir == /* ]] || probe_dir=$PWD/$probe_dir
  trap 'rm -rf -- "$probe_dir"' EXIT
  cd -- "$probe_dir" || return 1
  "$@" </dev/null
)

check_engines() {
  local engine binary catalog
  printf '%-7s %-15s %s\n' ENGINE STATUS DETAIL
  for engine in codex pi; do
    if ! binary=$(resolve_engine "$engine"); then
      printf '%-7s %-15s %s\n' "$engine" missing 'PATH 中找不到命令'
    elif ! "$binary" --version >/dev/null 2>&1; then
      printf '%-7s %-15s %s\n' "$engine" unavailable '--version 执行失败'
    else
      case "$engine" in
        codex)
          if "$binary" login status >/dev/null 2>&1; then
            printf '%-7s %-15s %s\n' "$engine" ready 'codex login status 成功'
          else
            printf '%-7s %-15s %s\n' "$engine" auth-unverified 'codex login status 失败，请单独检查登录或配置'
          fi
          ;;
        pi)
          if ! catalog=$(NO_COLOR=1 FORCE_COLOR=0 probe_catalog "$binary" --list-models 2>/dev/null); then
            printf '%-7s %-15s %s\n' "$engine" unavailable '已安装，模型目录探测失败'
          elif [[ $catalog != *[![:space:]]* || $catalog == *'No models available.'* ]]; then
            printf '%-7s %-15s %s\n' "$engine" catalog-empty '模型目录没有条目'
          else
            printf '%-7s %-15s %s\n' "$engine" catalog-ok '模型目录可读取，指定模型和凭证仍需确认'
          fi
          ;;
      esac
    fi
  done
}

normalize_path
if [[ $# -eq 1 ]]; then
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --check) check_engines; exit 0 ;;
  esac
fi
[[ $# -gt 0 ]] || die '缺少参数，请查看 --help'

engine= model= cwd= mode= output= prompt= prompt_file= prompt_kind=
skip_git_check=false
while [[ $# -gt 0 ]]; do
  option=$1
  shift
  case "$option" in
    --skip-git-check)
      [[ $skip_git_check == false ]] || die "--skip-git-check 重复指定"
      skip_git_check=true
      continue
      ;;
    --engine|--model|--cwd|--mode|--output|--prompt-file|--prompt)
      [[ $# -gt 0 && -n $1 ]] || die "$option 缺少参数值"
      [[ $option == --prompt || $1 != --* ]] || die "$option 缺少参数值"
      ;;
    -h|--help|--check) die "$option 必须单独使用" ;;
    *) die "未知参数 ${option}，请查看 --help" ;;
  esac

  case "$option" in
    --engine) [[ -z $engine ]] || die "$option 重复指定"; engine=$1 ;;
    --model) [[ -z $model ]] || die "$option 重复指定"; model=$1 ;;
    --cwd) [[ -z $cwd ]] || die "$option 重复指定"; cwd=$1 ;;
    --mode) [[ -z $mode ]] || die "$option 重复指定"; mode=$1 ;;
    --output) [[ -z $output ]] || die "$option 重复指定"; output=$1 ;;
    --prompt-file|--prompt)
      [[ -z $prompt_kind ]] || die '--prompt-file 与 --prompt 只能指定一次且互斥'
      prompt_kind=$option
      if [[ $prompt_kind == --prompt-file ]]; then
        prompt_file=$1
      else
        prompt=$1
      fi
      ;;
  esac
  shift
done

case "$engine" in
  codex|pi) ;;
  '') die '缺少 --engine' ;;
  *) die "不支持的引擎 ${engine}，应为 codex 或 pi" ;;
esac
case "$mode" in
  readonly) sandbox=read-only ;;
  write) sandbox=workspace-write ;;
  '') die '缺少 --mode' ;;
  *) die "不支持的模式 ${mode}，应为 readonly 或 write" ;;
esac
[[ -n $model && $model != -* && $model != *[[:space:]]* ]] || die '请指定有效的 --model'
if [[ $model == profile:* ]]; then
  profile=${model#profile:}
  [[ $engine == codex && -n $profile && $profile != -* ]] ||
    die 'profile:<名称> 仅适用于 Codex，且名称不能为空或以 - 开头'
fi
[[ $skip_git_check == false || $engine == codex ]] || die '--skip-git-check 仅适用于 Codex'
[[ -n $cwd ]] || die '缺少 --cwd'
[[ $cwd == /* ]] || cwd=$PWD/$cwd
[[ -d $cwd ]] && cwd=$(CDPATH= cd -P -- "$cwd" && pwd -P) || die "无法进入工作目录 $cwd"
[[ -n $output ]] || die '缺少 --output'
[[ $output == /* ]] || output=$PWD/$output
output_parent=${output%/*}
[[ -d ${output_parent:-/} && -w ${output_parent:-/} && -x ${output_parent:-/} ]] ||
  die "输出文件的父目录不可写 $output"
[[ $output != */ && ! -L $output && ( ! -e $output || ( -f $output && -w $output ) ) ]] ||
  die "输出路径必须可写且指向普通文件 $output"

[[ -n $prompt_kind ]] || die '需指定 --prompt-file 或 --prompt'
if [[ $prompt_kind == --prompt-file ]]; then
  [[ -f $prompt_file && -r $prompt_file ]] || die "无法读取提示词文件 $prompt_file"
  [[ ! $prompt_file -ef $output ]] || die '提示词和输出不能指向同一个文件'
  if IFS= read -r -d '' prompt < "$prompt_file"; then
    die "提示词文件含有 NUL 字节 $prompt_file"
  fi
fi
[[ $prompt == *[![:space:]]* ]] || die '提示词不能为空'
binary=$(resolve_engine "$engine") || die "PATH 中找不到 $engine"
exec < <(printf '%s' "$prompt")

case "$engine" in
  codex)
    if [[ $mode == readonly ]]; then
      mcp_args=(mcp list)
      if [[ $model == profile:* ]]; then
        mcp_args=(-p "$profile" "${mcp_args[@]}")
      fi
      if ! mcp=$(cd -- "$cwd" && "$binary" "${mcp_args[@]}" </dev/null); then
        die 'Codex mcp list 失败，只读模式拒绝启动。请检查配置或使用 profile:reviewer-codex'
      fi
      # Both stdio and HTTP tables end in Status and Auth, separated by padding.
      mcp_enabled=$(awk -F '[[:blank:]][[:blank:]]+' '
        { sub(/[[:blank:]]+$/, "") }
        NF > 1 && $(NF - 1) == "enabled" { print "enabled"; exit }
      ' <<< "$mcp")
      [[ -z $mcp_enabled ]] ||
        die 'Codex 有 enabled MCP，只读模式拒绝启动。请禁用可写 MCP，或使用 profile:reviewer-codex'
    fi
    args=(exec -s "$sandbox" -C "$cwd" --ephemeral -o "$output")
    if [[ $model == profile:* ]]; then
      args+=(-p "$profile")
    else
      args+=(-m "$model")
    fi
    if [[ $skip_git_check == true ]]; then
      args+=(--skip-git-repo-check)
    fi
    exec "$binary" "${args[@]}" -
    ;;
  pi)
    args=(-p --no-session --model "$model")
    if [[ $mode == readonly ]]; then
      if [[ -e $cwd/.pi/commands && ! -e $cwd/.pi/prompts ]]; then
        die "Pi 的 runMigrations(cwd) 会将 $cwd/.pi/commands 重命名为 .pi/prompts，只读模式拒绝启动"
      fi
      args+=(--tools read,grep,find,ls --no-extensions)
    fi
    cd -- "$cwd"
    tmp_output=$(mktemp "${output_parent%/}/.multi-model-dispatch.XXXXXX")
    trap 'rm -f -- "$tmp_output"' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    "$binary" "${args[@]}" > "$tmp_output" || exit $?
    mv -f -- "$tmp_output" "$output"
    ;;
esac
