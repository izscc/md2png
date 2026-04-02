# md2png

Public Codex skill for rendering local Markdown files to paginated PNG or SVG through the hosted `marknative` render service.

## One-line install

### Universal shell installer

```bash
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash
```

默认会安装到常见全局技能目录：
- Codex: `~/.codex/skills`
- Claude Code: `~/.claude/skills`
- OpenCode: `~/.config/opencode/skills`
- OpenClaw: 自动探测 `~/.openclaw/skills` / `~/.openclaw/workspace/skills` / `~/.moltbot/skills`

如只安装给某一个 CLI：

```bash
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent claude-code
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent opencode
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent openclaw
```

### Codex Python installer
```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py --url https://github.com/izscc/md2png/tree/main/skills/marknative-renderer
```

Install complete后请重启 Codex 以加载新 skill。

## API key

出于安全原因，仓库**不内置默认 key**。

获取方式：
- 通过飞书私信 **船长**
- 或在知识船仓的 **AI船效社** 群中查找该项目的公开 key

## Setup

```bash
export MARKNATIVE_API_URL="https://api.zscc.in/marknative"
export MARKNATIVE_API_KEY="你的 key"
```

## Usage

### In Agent

直接对 Agent 说：
- “把 `/absolute/path/demo.md` 渲染成 png”
- “把 `/absolute/path/demo.md` 渲染成 svg”

### Direct CLI

```bash
python3 ~/.codex/skills/marknative-renderer/scripts/render_marknative.py \
  --input /absolute/path/demo.md \
  --format svg
```

可选参数：
- `--output-dir /absolute/path/out`
- `--retention-days N`
- `--api-url https://api.zscc.in/marknative`
- `--api-key YOUR_KEY`

## Output

默认会把结果写到源 Markdown 同级目录下：

- `demo.marknative/demo-01.png`
- `demo.marknative/demo-02.png`
- 或对应的 `.svg`

Skill 会返回所有生成文件的绝对路径。
