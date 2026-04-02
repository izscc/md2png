# md2png

一个可公开安装的技能仓库：把本地 Markdown 文件通过托管的远程 `marknative` 渲染服务转换为分页 PNG 或 SVG。

> 本仓库是 **纯远程调用版 Skill**：  
> - 默认调用 `https://api.zscc.in/marknative`  
> - 不包含本地 Bun / Docker / SQLite / 管理后台 / 部署脚本  
> - 不会在用户本地启动端到端渲染服务

## 一句话安装

### 通用 Shell 安装器

```bash
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash
```

默认会安装到常见 CLI 的全局技能目录：
- Codex：`~/.codex/skills`
- Claude Code：`~/.claude/skills`
- OpenCode：`~/.config/opencode/skills`
- OpenClaw：自动探测 `~/.openclaw/skills` / `~/.openclaw/workspace/skills` / `~/.moltbot/skills`

如果只想安装给某一个 CLI：

```bash
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent claude-code
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent opencode
curl -fsSL https://raw.githubusercontent.com/izscc/md2png/main/install.sh | bash -s -- --agent openclaw
```

### Codex Python 安装方式

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py --url https://github.com/izscc/md2png/tree/main/skills/marknative-renderer
```

安装完成后请重启对应的 Agent CLI。

## API Key 获取方式

出于安全原因，仓库**不内置默认 key**。

可通过以下方式获取：
- 飞书私信 **船长**
- 在知识船仓的 **AI船效社** 群中查找该项目的公开 key

## 环境变量设置

```bash
export MARKNATIVE_API_URL="https://api.zscc.in/marknative"
export MARKNATIVE_API_KEY="你的 key"
```

说明：
- `MARKNATIVE_API_URL` 默认就是远程地址 `https://api.zscc.in/marknative`
- `MARKNATIVE_API_KEY` 需要你自行提供
- Skill 本身只负责“读取本地 md → 调用远程 API → 写回本地 png/svg”

## 使用方式

### 在 Agent 中使用

你可以直接对 Agent 说：
- “把 `/absolute/path/demo.md` 渲染成 png”
- “把 `/absolute/path/demo.md` 渲染成 svg”

### 直接命令行调用

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

## 输出结果

默认会把渲染结果写到源 Markdown 同级目录：

- `demo.marknative/demo-01.png`
- `demo.marknative/demo-02.png`
- 或对应的 `.svg` 文件

Skill 会返回所有生成文件的绝对路径。

## 仓库内容说明

这个公开仓库只包含 Skill 包装层：
- `install.sh`
- `skills/marknative-renderer/SKILL.md`
- `skills/marknative-renderer/agents/openai.yaml`
- `skills/marknative-renderer/scripts/render_marknative.py`

不包含后端服务、管理后台、部署脚本、本地端到端服务或任何默认密钥。
