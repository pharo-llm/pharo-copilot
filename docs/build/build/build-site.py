#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import shutil

import pypandoc
from bs4 import BeautifulSoup
from jinja2 import Template


REPO_ROOT = Path(__file__).resolve().parents[3]
DOCS_DIR = REPO_ROOT / "docs"

SRC_DIR = DOCS_DIR / "build"
OUT_DIR = DOCS_DIR

SRC_ASSETS = SRC_DIR / "assets"
OUT_ASSETS = OUT_DIR / "assets"


PAGE_TEMPLATE = Template(
    """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>{{ title }}</title>

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="{{ asset_prefix }}/css.css" rel="stylesheet">
</head>
<body>

<header class="border-bottom">
  <div class="container-xxl py-3 d-flex justify-content-between">
    <div class="fw-semibold">{{ site_name }}</div>
    <a href="{{ home_href }}">Home</a>
  </div>
</header>

<main class="container-xxl my-4">
  <div class="row g-4">

    {% if toc_html %}
    <aside class="col-12 col-lg-3">
      <div id="sidebar" class="border rounded-3 p-3">
        <div class="fw-semibold mb-2">On this page</div>
        {{ toc_html | safe }}
      </div>
    </aside>
    {% endif %}

    <section class="col">
      <article class="border rounded-3 p-4">
        {{ body_html | safe }}
      </article>
    </section>

  </div>
</main>

<script src="{{ asset_prefix }}/js.js"></script>
</body>
</html>"""
)


@dataclass(frozen=True)
class Page:
    src: Path
    rel_md: Path
    rel_html: Path
    title: str


def list_markdown_files() -> list[Path]:
    return sorted(p for p in SRC_DIR.rglob("*.md") if SRC_ASSETS not in p.parents)


def guess_title(md_path: Path) -> str:
    for line in md_path.read_text(errors="ignore").splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return md_path.stem.replace("-", " ").title()


def md_rel_to_html_rel(rel_md: Path) -> Path:
    return Path("index.html") if rel_md.name.lower() == "index.md" else rel_md.with_suffix(".html")


def clean_toc(toc_html: str) -> str:
    soup = BeautifulSoup(toc_html, "html.parser")
    nav = soup.find("nav", id="TOC")
    if not nav:
        return ""

    nav["class"] = ["toc"]
    for ul in nav.find_all("ul"):
        ul["class"] = ["list-unstyled"]

    for a in nav.find_all("a"):
        a["class"] = ["toc-link"]

    return str(nav)


def rewrite_internal_links(soup: BeautifulSoup) -> None:
    for a in soup.find_all("a"):
        href = a.get("href")
        if not href or href.startswith(("http", "#", "mailto")):
            continue
        if href.endswith(".md"):
            a["href"] = href[:-3] + ".html"


def convert_one(md_path: Path, title: str) -> tuple[str, str]:
    html = pypandoc.convert_file(
        str(md_path),
        to="html5",
        format="md",
        extra_args=["--standalone", "--toc", "--toc-depth=3"],
    )

    soup = BeautifulSoup(html, "html.parser")

    toc_html = ""
    toc = soup.find("nav", id="TOC")
    if toc:
        toc_html = clean_toc(str(toc))
        toc.decompose()

    body = soup.body or soup
    rewrite_internal_links(body)

    return toc_html, str(body)


def copy_assets() -> None:
    OUT_ASSETS.mkdir(parents=True, exist_ok=True)
    if SRC_ASSETS.exists():
        for p in SRC_ASSETS.rglob("*"):
            if p.is_file():
                dest = OUT_ASSETS / p.relative_to(SRC_ASSETS)
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(p, dest)


def main() -> int:
    copy_assets()

    md_files = list_markdown_files()
    for md in md_files:
        rel_md = md.relative_to(SRC_DIR)
        rel_html = md_rel_to_html_rel(rel_md)

        out = OUT_DIR / rel_html
        out.parent.mkdir(parents=True, exist_ok=True)

        toc_html, body_html = convert_one(md, guess_title(md))

        asset_prefix = os.path.relpath(OUT_ASSETS, out.parent)
        home_href = os.path.relpath(OUT_DIR / "index.html", out.parent)

        html = PAGE_TEMPLATE.render(
            site_name="Pharo-Copilot Documentation",
            title=guess_title(md),
            toc_html=toc_html,
            body_html=body_html,
            asset_prefix=asset_prefix,
            home_href=home_href,
        )

        out.write_text(html, encoding="utf-8")
        print("Wrote", out)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
