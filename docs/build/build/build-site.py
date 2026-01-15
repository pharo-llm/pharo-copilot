#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import shutil

import pypandoc
from bs4 import BeautifulSoup
from jinja2 import Template

# -----------------------------
# CONFIG
# -----------------------------
REPO_ROOT = Path(__file__).resolve().parents[3]
DOCS_DIR = REPO_ROOT / "docs"

SRC_DIR = DOCS_DIR / "build"
OUT_DIR = DOCS_DIR

SRC_ASSETS = SRC_DIR / "assets"
OUT_ASSETS = OUT_DIR / "assets"

BASE_URL = "https://omarabedelkader.github.io/Pharo-Copilot/"  # change to your site URL

# External resources shown in the top navbar (edit these!)
RESOURCES: list[tuple[str, str]] = [
    ("GitHub", "https://github.com/omarabedelkader/Pharo-Copilot"),
    ("Hugging Face", "https://huggingface.co/Pharo-Copilot"),
    ("Ollama", "https://ollama.com/omarabedelkader"),
]

# -----------------------------
# PAGE TEMPLATE (SEO-READY)
# -----------------------------
PAGE_TEMPLATE = Template(
    """<!doctype html>
<html lang="en" data-bs-theme="light">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>{{ title }}</title>
  <meta name="description" content="{{ description }}">
  <meta name="keywords" content="{{ keywords }}">
  <link rel="canonical" href="{{ canonical_url }}">

  <!-- Open Graph -->
  <meta property="og:title" content="{{ title }}">
  <meta property="og:description" content="{{ description }}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="{{ canonical_url }}">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{{ title }}">
  <meta name="twitter:description" content="{{ description }}">

  <!-- JSON-LD Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "TechArticle",
    "headline": "{{ title }}",
    "description": "{{ description }}",
    "url": "{{ canonical_url }}",
    "author": { "@type": "Organization", "name": "{{ site_name }}" }
  }
  </script>

  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="{{ asset_prefix }}/css.css" rel="stylesheet">
</head>
<body>

<header class="border-bottom">
  <div class="container-xxl py-3 d-flex justify-content-between align-items-center">

    <a class="fw-semibold text-decoration-none" href="{{ home_href }}">{{ site_name }}</a>

    <div class="d-flex gap-3 align-items-center">

      <!-- Desktop: show direct resource links -->
      <nav class="d-none d-md-flex gap-3 align-items-center" aria-label="Resources">
        {% for label, url in resources %}
          <a class="link-secondary small"
             href="{{ url }}"
             target="_blank"
             rel="noopener noreferrer">
            {{ label }}
          </a>
        {% endfor %}
      </nav>

      <!-- Mobile: dropdown -->
      <div class="dropdown d-md-none">
        <button class="btn btn-sm btn-outline-secondary dropdown-toggle"
                type="button"
                data-bs-toggle="dropdown"
                aria-expanded="false">
          Resources
        </button>
        <ul class="dropdown-menu dropdown-menu-end">
          {% for label, url in resources %}
            <li>
              <a class="dropdown-item"
                 href="{{ url }}"
                 target="_blank"
                 rel="noopener noreferrer">
                {{ label }}
              </a>
            </li>
          {% endfor %}
        </ul>
      </div>

      <button
        id="theme-toggle"
        class="btn btn-sm btn-outline-secondary"
        type="button"
        aria-label="Toggle theme">
        🌙
      </button>
    </div>
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

<!-- Scroll to top button -->
<button
  id="scroll-top"
  class="btn btn-primary scroll-top"
  type="button"
  aria-label="Scroll to top">
  ↑
</button>

<!-- Bootstrap JS bundle needed for dropdown -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="{{ asset_prefix }}/js.js"></script>
</body>
</html>
"""
)

# -----------------------------
# DATACLASS
# -----------------------------
@dataclass(frozen=True)
class Page:
    src: Path
    rel_md: Path
    rel_html: Path
    title: str

# -----------------------------
# UTILITIES
# -----------------------------
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

def convert_one(md_path: Path) -> tuple[str, str]:
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

    # Avoid injecting a nested <body> tag inside <article>
    body_html = body.decode_contents() if getattr(body, "name", None) == "body" else str(body)
    return toc_html, body_html

def extract_description_and_keywords(md_path: Path) -> tuple[str, str]:
    text = md_path.read_text(errors="ignore")

    # Description = first non-empty paragraph
    description = ""
    for para in text.split("\n\n"):
        stripped = para.strip()
        if stripped:
            description = stripped.replace("\n", " ")
            break
    if not description:
        description = guess_title(md_path)

    # Keywords = headings
    keywords = []
    for line in text.splitlines():
        if line.startswith("#"):
            keywords.append(line.lstrip("#").strip())
    keywords_str = ", ".join(keywords[:10])

    return description, keywords_str

def canonical_url_for(rel_html: Path) -> str:
    return f"{BASE_URL}/{str(rel_html).replace(os.sep, '/')}"

def copy_assets() -> None:
    OUT_ASSETS.mkdir(parents=True, exist_ok=True)
    if SRC_ASSETS.exists():
        for p in SRC_ASSETS.rglob("*"):
            if p.is_file():
                dest = OUT_ASSETS / p.relative_to(SRC_ASSETS)
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(p, dest)

# -----------------------------
# MAIN
# -----------------------------
def main() -> int:
    copy_assets()
    md_files = list_markdown_files()

    for md in md_files:
        rel_md = md.relative_to(SRC_DIR)
        rel_html = md_rel_to_html_rel(rel_md)
        out = OUT_DIR / rel_html
        out.parent.mkdir(parents=True, exist_ok=True)

        toc_html, body_html = convert_one(md)
        description, keywords = extract_description_and_keywords(md)
        asset_prefix = os.path.relpath(OUT_ASSETS, out.parent)
        home_href = os.path.relpath(OUT_DIR / "index.html", out.parent)
        canonical_url = canonical_url_for(rel_html)

        title = guess_title(md)

        html = PAGE_TEMPLATE.render(
            site_name="Pharo-Copilot Documentation",
            title=title,
            description=description,
            keywords=keywords,
            canonical_url=canonical_url,
            toc_html=toc_html,
            body_html=body_html,
            asset_prefix=asset_prefix,
            home_href=home_href,
            resources=RESOURCES,
        )

        out.write_text(html, encoding="utf-8")
        print("Wrote", out)

    return 0

if __name__ == "__main__":
    raise SystemExit(main())
