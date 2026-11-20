"""Check the actual release archive before publishing it."""
# Copyright 2026 The MathWorks, Inc.

from pathlib import Path, PurePosixPath
import hashlib
import json
import sys
from urllib.parse import urlsplit
import zipfile
import xml.etree.ElementTree as ET

from markdown_it import MarkdownIt


def verify_package(filename):
    root = Path(__file__).resolve().parents[1]
    with zipfile.ZipFile(filename) as archive:
        names = set(archive.namelist())
        required = {"fsroot/README.md", "fsroot/LICENSE.txt", "fsroot/SECURITY.md",
                    "fsroot/resources/mpackage.json",
                    "fsroot/doc/index.html", "fsroot/doc/getting-started.html",
                    "fsroot/doc/readrds.html", "fsroot/doc/readrdata.html",
                    "fsroot/doc/rdata2table.html", "fsroot/doc/rdatainfo.html",
                    "fsroot/doc/help.css", "fsroot/doc/helptoc.xml",
                    "fsroot/doc/info.xml", "fsroot/doc/mfiles/GettingStarted.m",
                    "fsroot/rdatareader/readrds.m", "fsroot/rdatareader/readrdata.m",
                    "fsroot/rdatareader/rdata2table.m", "fsroot/rdatareader/rdatainfo.m"}
        assert required <= names, f"Missing files: {sorted(required - names)}"
        for name in ["LICENSE.txt", "SECURITY.md"]:
            assert archive.read("fsroot/" + name) == (root / name).read_bytes(), name
        package_metadata = json.loads(archive.read("fsroot/resources/mpackage.json"))
        assert package_metadata.get("readme") == "README.md", "Missing package README metadata"
        readme = archive.read("fsroot/README.md").decode("utf-8")
        assert readme.strip(), "Blank package README"
        assert archive.read("fsroot/README.md") == (root / "tbx" / "README.md").read_bytes(), "Stale package README"
        for token in MarkdownIt().parse(readme):
            for child in token.children or []:
                target = child.attrGet("href") or child.attrGet("src")
                if target:
                    assert urlsplit(target).scheme in {"https", "http"} or target.startswith("#"), (
                        f"Package README link depends on the repository layout: {target}"
                    )
        assert any("/helpsearch-v" in n for n in names), "No searchable help"
        for name in names:
            if not name.startswith("fsroot/") or name.endswith("/"):
                continue
            p = PurePosixPath(name)
            assert p.suffix.lower() not in {".rds", ".rda", ".rdata", ".docx", ".pptx", ".exe", ".p"}, name
            assert not ({"tests", "testdata", ".git"} & set(p.parts)), name
            assert not name.startswith("fsroot/doc/resources/"), name
            if p.suffix in {".m", ".md", ".html", ".css", ".txt"}:
                text = archive.read(name).decode("utf-8")
                assert "%[output:" not in text and '"outputData"' not in text, name
        requirements = ET.fromstring(archive.read("metadata/systemRequirements.xml"))
        release = requirements.find("{*}releaseCompatibility")
        assert release is not None and release.get("start") == "R2023a", "Wrong minimum release"
        properties = ET.fromstring(archive.read("metadata/coreProperties.xml"))
        version = properties.find("{*}version").text
        info = {"package": Path(filename).name, "version": version,
                "readme": package_metadata["readme"], "readme_characters": len(readme),
                "sha256": hashlib.sha256(Path(filename).read_bytes()).hexdigest(),
                "bytes": Path(filename).stat().st_size,
                "entries": len(names), "verified": True}
        print(json.dumps(info, indent=2))
        return info


if __name__ == "__main__":
    verify_package(sys.argv[1])
