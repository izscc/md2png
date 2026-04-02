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
Install the marknative-renderer skill into one or more agent CLI skill directories.

Usage:
  bash install.sh [--all]
  bash install.sh --agent claude-code
  bash install.sh --agent opencode --agent openclaw
  bash install.sh --path ~/.claude/skills

Options:
  --agent <name>   Target agent: codex, claude-code, opencode, openclaw
  --all            Install to all supported global agent directories
  --path <dir>     Install into a custom skills root directory
  --ref <ref>      Git ref to download from (default: main)
  --repo <owner/repo>
                   GitHub repository to download from (default: izscc/md2png)
  -h, --help       Show this help message

Examples:
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent claude-code
  curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --all
EOF
}

info() {
  printf '[md2png] %s\n' "$*"
}

fail() {
  printf '[md2png] ERROR: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
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
      fail "unknown argument: $1"
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
  info "installing to custom path: $CUSTOM_PATH"
  install_to_root "$CUSTOM_PATH"
else
  if [[ ${#REQUESTED_AGENTS[@]} -eq 0 ]]; then
    REQUESTED_AGENTS=(codex claude-code opencode openclaw)
  fi

  for agent in "${REQUESTED_AGENTS[@]}"; do
    root="$(agent_root "$agent")" || fail "unsupported agent: $agent"
    info "installing for ${agent} -> ${root}"
    install_to_root "$root"
  done
fi

printf '\nInstalled %s to:\n' "$SKILL_NAME"
for target in "${INSTALLED_TARGETS[@]}"; do
  printf '  - %s\n' "$target"
done

cat <<EOF

Next steps:
  1. Export your API key:
     export MARKNATIVE_API_URL="https://api.zscc.in/marknative"
     export MARKNATIVE_API_KEY="YOUR_KEY"
  2. Restart your agent CLI if it is already running.

API key获取说明：
  ${KEY_HINT}
EOF
