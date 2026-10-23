"""Build static toolbox help without executing examples or using remote APIs."""
# Copyright 2026 The MathWorks, Inc.

from html import escape
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from markdown_it import MarkdownIt


def build_help():
    root = Path(__file__).resolve().parents[1] / "tbx" / "doc"
    markdown = MarkdownIt("commonmark", {"html": True}).enable("table")
    for source in sorted(root.glob("*.md")):
        text = source.read_text(encoding="utf-8")
        title = text.splitlines()[0].lstrip("# ")
        body = markdown.render(text)
        body = re.sub(r'(href="[^"#]+)\.md([#"][^"]*)', r'\1.html\2', body)
        html = (
            '<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<title>{escape(title)}</title><link rel="stylesheet" href="help.css">'
            '</head><body><main>' + body + '</main></body></html>\n'
        )
        source.with_suffix(".html").write_text(html, encoding="utf-8")

    info = ET.Element("productinfo")
    for key, value in {
        "matlabrelease": "R2025a",
        "name": "MATLAB Reader for R Data Files",
        "type": "toolbox",
        "icon": "$toolbox/matlab/icons/bookicon.gif",
        "help_location": ".",
    }.items():
        ET.SubElement(info, key).text = value
    info.append(ET.Comment(" Copyright 2026 The MathWorks, Inc. "))
    ET.ElementTree(info).write(root / "info.xml", encoding="utf-8", xml_declaration=True)

    toc = ET.Element("toc", {"version": "2.0"})
    overview = ET.SubElement(toc, "tocitem", {"target": "index.html"})
    overview.text = "MATLAB Reader for R Data Files"
    for label, target in re.findall(r"\[([^\]]+)\]\(([^)]+)\)",
                                    (root / "helptoc.md").read_text(encoding="utf-8")):
        if target == "index.md":
            continue
        ET.SubElement(overview, "tocitem", {"target": target.replace(".md", ".html")}).text = label
    toc.append(ET.Comment(" Copyright 2026 The MathWorks, Inc. "))
    ET.ElementTree(toc).write(root / "helptoc.xml", encoding="utf-8", xml_declaration=True)
    print(f"Built {len(list(root.glob('*.md')))} static help pages.")


if __name__ == "__main__":
    build_help()
