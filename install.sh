#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-izscc/md2png}"
REF="${REF:-main}"
SKILL_NAME="${SKILL_NAME:-marknative-renderer}"
RAW_BASE="${RAW_BASE:-}"
KEY_HINT="请通过飞书私信船长，或者在知识船仓的 AI船效社 群中查找该项目的公开 key。"

declare -a REQUESTED_AGENTS=()
declare -a INSTALLED_TARGETS=()
CUSTOM_PATH=""

usage() {
  cat <<'EOF'
将 marknative-renderer 技能安装到一个或多个 Agent CLI 的技能目录。

用法：
  bash install.sh [--all]
  bash install.sh --agent claude-code
  bash install.sh --agent opencode --agent openclaw
  bash install.sh --path ~/.claude/skills

参数：
  --agent <name>   指定目标 Agent：codex、claude-code、opencode、openclaw
  --all            安装到所有受支持的全局技能目录
  --path <dir>     安装到自定义技能根目录
  --ref <ref>      指定下载的 Git 引用（默认：main）
  --repo <owner/repo>
                   指定下载的 GitHub 仓库（默认：izscc/md2png）
  -h, --help       显示这段帮助信息

示例：
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent claude-code
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --all
EOF
}

info() {
  printf '[md2png] %s\n' "$*"
}

fail() {
  printf '[md2png] 错误：%s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "缺少必要命令：$1"
}

append_unique() {
  local value="$1"
  shift || true
  local existing
  for existing in "$@"; do
    if [[ "$existing" == "$value" ]]; then
      return 0
    fi
  done
  REQUESTED_AGENTS+=("$value")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      [[ $# -ge 2 ]] || fail "--agent requires a value"
      append_unique "$2" "${REQUESTED_AGENTS[@]-}"
      shift 2
      ;;
    --all)
      REQUESTED_AGENTS=(codex claude-code opencode openclaw)
      shift
      ;;
    --path)
      [[ $# -ge 2 ]] || fail "--path requires a value"
      CUSTOM_PATH="$2"
      shift 2
      ;;
    --ref)
      [[ $# -ge 2 ]] || fail "--ref requires a value"
      REF="$2"
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || fail "--repo requires a value"
      REPO="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "未知参数：$1"
      ;;
  esac
done

if [[ -z "$RAW_BASE" ]]; then
  RAW_BASE="https://raw.githubusercontent.com/${REPO}/${REF}"
fi

require_cmd curl
require_cmd mktemp

resolve_openclaw_root() {
  local candidates=(
    "${HOME}/.openclaw/skills"
    "${HOME}/.openclaw/workspace/skills"
    "${HOME}/.moltbot/skills"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  printf '%s\n' "${HOME}/.openclaw/skills"
}

agent_root() {
  case "$1" in
    codex) printf '%s\n' "${HOME}/.codex/skills" ;;
    claude-code) printf '%s\n' "${HOME}/.claude/skills" ;;
    opencode) printf '%s\n' "${HOME}/.config/opencode/skills" ;;
    openclaw) resolve_openclaw_root ;;
    *) return 1 ;;
  esac
}

download_file() {
  local source_path="$1"
  local target_path="$2"
  mkdir -p "$(dirname "$target_path")"
  curl -fsSL "${RAW_BASE}/${source_path}" -o "$target_path"
}

install_to_root() {
  local root_dir="$1"
  local target_dir="${root_dir%/}/${SKILL_NAME}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  download_file "skills/${SKILL_NAME}/SKILL.md" "${tmp_dir}/SKILL.md"
  download_file "skills/${SKILL_NAME}/agents/openai.yaml" "${tmp_dir}/agents/openai.yaml"
  download_file "skills/${SKILL_NAME}/scripts/render_marknative.py" "${tmp_dir}/scripts/render_marknative.py"
  chmod +x "${tmp_dir}/scripts/render_marknative.py"

  mkdir -p "$root_dir"
  rm -rf "$target_dir"
  mkdir -p "$(dirname "$target_dir")"
  mv "$tmp_dir" "$target_dir"
  INSTALLED_TARGETS+=("$target_dir")
  trap - RETURN
}

if [[ -n "$CUSTOM_PATH" ]]; then
  info "安装到自定义路径：$CUSTOM_PATH"
  install_to_root "$CUSTOM_PATH"
else
  if [[ ${#REQUESTED_AGENTS[@]} -eq 0 ]]; then
    REQUESTED_AGENTS=(codex claude-code opencode openclaw)
  fi

  for agent in "${REQUESTED_AGENTS[@]}"; do
    root="$(agent_root "$agent")" || fail "不支持的 Agent：$agent"
    info "为 ${agent} 安装 -> ${root}"
    install_to_root "$root"
  done
fi

printf '\n已安装 %s 到：\n' "$SKILL_NAME"
for target in "${INSTALLED_TARGETS[@]}"; do
  printf '  - %s\n' "$target"
done

cat <<EOF

下一步：
  1. 先设置 API 环境变量：
     export MARKNATIVE_API_URL="https://api.zscc.in/marknative"
     export MARKNATIVE_API_KEY="YOUR_KEY"
  2. 如果 Agent CLI 已经在运行，请重启后再使用。

API key获取说明：
  ${KEY_HINT}
EOF
