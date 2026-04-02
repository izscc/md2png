#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

DEFAULT_API_URL = "https://api.zscc.in/marknative"
KEY_HINT = "请通过飞书私信船长，或者在知识船仓的 AI船效社 群中查找该项目的公开 key。"


def render_markdown_file(
    *,
    input_path: Path,
    format: str,
    output_dir: Path | None,
    api_url: str,
    api_key: str,
    retention_days: int | None,
) -> dict[str, Any]:
    if format not in {"png", "svg"}:
        raise ValueError("format must be png or svg")
    if not input_path.is_file():
        raise FileNotFoundError(f"markdown file not found: {input_path}")
    if not api_key.strip():
        raise ValueError(f"missing API key. Set MARKNATIVE_API_KEY or pass --api-key. {KEY_HINT}")

    markdown = input_path.read_text(encoding="utf-8")
    target_dir = output_dir or input_path.parent / f"{input_path.stem}.marknative"
    target_dir.mkdir(parents=True, exist_ok=True)

    payload: dict[str, Any] = {
        "markdown": markdown,
        "format": format,
        "basename": input_path.stem,
    }
    if retention_days is not None:
        payload["retentionDays"] = retention_days

    request = Request(
        _render_url(api_url),
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )

    try:
        with urlopen(request) as response:
            body = response.read().decode("utf-8")
    except HTTPError as error:
        error_body = error.read().decode("utf-8", errors="replace") if hasattr(error, "read") else ""
        raise RuntimeError(f"marknative render request failed: HTTP {error.code} {error_body}".strip()) from error
    except URLError as error:
        raise RuntimeError(f"marknative render request failed: {error.reason}") from error
    except Exception as error:  # noqa: BLE001
        raise RuntimeError(f"marknative render request failed: {error}") from error

    response_payload = json.loads(body)
    files: list[str] = []
    for page in response_payload.get("pages", []):
        filename = page["filename"]
        page_bytes = base64.b64decode(page["dataBase64"])
        output_path = target_dir / filename
        output_path.write_bytes(page_bytes)
        files.append(str(output_path.resolve()))

    return {
        "jobId": response_payload.get("jobId"),
        "format": response_payload.get("format"),
        "expiresAt": response_payload.get("expiresAt"),
        "files": files,
    }


def _render_url(api_url: str) -> str:
    return api_url.rstrip("/") + "/render"


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a Markdown file through the hosted marknative service.")
    parser.add_argument("--input", required=True, help="Absolute or relative path to the input Markdown file")
    parser.add_argument("--format", choices=["png", "svg"], required=True, help="Output format")
    parser.add_argument("--output-dir", help="Directory for output files (defaults to <stem>.marknative beside the input)")
    parser.add_argument("--retention-days", type=int, help="Optional override for hosted retention period in days")
    parser.add_argument("--api-url", default=os.environ.get("MARKNATIVE_API_URL", DEFAULT_API_URL), help="Base API URL")
    parser.add_argument("--api-key", default=os.environ.get("MARKNATIVE_API_KEY", ""), help="API key")
    args = parser.parse_args()

    result = render_markdown_file(
        input_path=Path(args.input).expanduser().resolve(),
        format=args.format,
        output_dir=Path(args.output_dir).expanduser().resolve() if args.output_dir else None,
        api_url=args.api_url,
        api_key=args.api_key,
        retention_days=args.retention_days,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
