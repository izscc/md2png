---
name: marknative-renderer
description: Render a user-specified Markdown file to paginated PNG or SVG outputs through the hosted marknative service. Use when the user wants an md file converted into PNG pages or SVG pages.
license: MIT
metadata:
  github_url: https://github.com/liyown/marknative
  github_hash: a7ebc5ac970d6bd4e3834ff6337a0370d23924ba
  version: 0.1.0
  created_at: 2026-04-02T00:00:00Z
  entry_point: scripts/render_marknative.py
  dependencies:
    - python3
---

# Marknative Renderer

## Overview

Use the bundled Python wrapper to send a local Markdown file to the hosted marknative render service, then write all returned PNG or SVG pages to local files.

This skill is **remote-only**:
- it defaults to `https://api.zscc.in/marknative`
- it does not start any local renderer service
- it does not bundle Bun, Docker, SQLite, or admin/backend code

## Workflow

1. Confirm the user has provided a Markdown file path.
2. Choose `png` or `svg` based on the user's request.
3. Ensure `MARKNATIVE_API_KEY` is available, or pass `--api-key` explicitly.
4. Run the wrapper script:
   - `python3 scripts/render_marknative.py --input /absolute/path/file.md --format png`
   - or `python3 scripts/render_marknative.py --input /absolute/path/file.md --format svg`
5. If the user wants a custom output directory, add `--output-dir /absolute/path/out`.
6. If the user wants a custom retention window for the hosted copy, add `--retention-days N`.
7. Return the produced absolute file paths to the user.

## Defaults

- API URL: `MARKNATIVE_API_URL` or `https://api.zscc.in/marknative`
- API key: `MARKNATIVE_API_KEY` or `--api-key`
- Default local output directory: `<markdown-stem>.marknative` beside the source file
- Output filenames: `<stem>-01.png`, `<stem>-02.png`, ... or SVG equivalents

## API key

This public skill does **not** include a default key.

To obtain a usable key:
- 通过飞书私信 **船长**
- 或在知识船仓的 **AI船效社** 群中查找该项目的公开 key

## Notes

- The hosted service may return multiple pages; always surface every output path.
- The local files written by this skill are not auto-deleted.
- This public skill only calls the hosted API and does not provide local end-to-end rendering.
