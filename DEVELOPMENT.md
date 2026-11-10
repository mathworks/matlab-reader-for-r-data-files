# Development

This repository is scoped as a MATLAB&reg; reader for common analytical R&reg;
data files. Keep changes aligned with the support matrix in `README.md`.

## Development Setup

Use MATLAB R2026b for the TOML project and release build. Runtime importing
supports R2025a and later. From the repository root:

```matlab
openProject("matlab.toml")
```

R is not required at runtime. `Rscript` is only needed to regenerate synthetic
fixtures or run live R oracle validation. The generated fixtures under
`tests/testdata/synthetic` are ignored by Git.

The optional real-world validation corpus is downloaded on demand:

```matlab
rdata.test.downloadValidationCorpus()
```

The download helper writes to `tests/testdata/corpus`, verifies byte counts and
SHA-256 hashes, and creates the manifest used by `realWorldCorpusTest`.

Regenerate synthetic fixtures when R fixture definitions change:

```matlab
openProject('matlab.toml')
rdata.test.generateSyntheticFixtures(string(pwd), Force=true);
```

This command works on Windows&reg; and Linux&reg; when `Rscript` is on `PATH`. Set
`RDATA_RSCRIPT` to the full executable path when it is not.

## Validate and package

For a complete suite with JUnit and coverage reports, run:

```matlab
addpath("tools")
results = runValidation;
```

This runs each test once. Coverage is measured on the fast suite; the large
downloaded smoke test runs separately without coverage instrumentation.

On R2025a, use a disposable source checkout: this command creates a local
project because that release cannot open TOML project definitions. CI tests
R2025a and R2026b on Windows and Linux. See
[compatibility and validation](docs/COMPATIBILITY.md).

For a release build in R2026b:

```matlab
openProject("matlab.toml")
setenv("RDATAREADER_VERSION", "v0.1.0")
buildtool archive
```

Before building, install the static-help dependency with
`python -m pip install -r tools/requirements-build.txt`. The build runs the full
test suite and static analysis, generates help locally, and creates
`releases/rDataReader.mltbx`. Python&reg; and markdown-it-py are build dependencies
only. Generated help uses this repository's stylesheet; no converter code,
third-party CSS, or JavaScript is packaged. Set `RDATA_PYTHON` if the Python
executable is not named `python` on PATH.

The archive explicitly includes runtime code, help, `LICENSE.txt`, and
`SECURITY.md`. Generated/downloaded datasets and test code are excluded.
Never save third-party numeric output into the distributed Getting Started
Live Script. Help generation does not execute examples. Run examples locally
to validate them without saving their output.

Check the actual archive with
`python tools/verify_package.py releases/rDataReader.mltbx`.
The tag workflow verifies the archive, creates the GitHub&reg; release, and attaches the package. Test
reports are workflow artifacts; GitHub Pages is not required.

To validate changes to release tooling, manually run the **Release** workflow
and supply a version such as `v0.1.0`. A manual run exercises Python setup, the
full toolbox build, and package verification, then uploads a `toolbox-validation`
artifact. It does not create or update a release. Only a version-tag push
publishes the package. The ordinary **Test** workflow does not exercise the
Python setup step used for release builds.

## Repository layout

The installer contains the reader and its help. The source repository also
contains the files needed to test and reproduce a release:

| Path | Purpose |
| --- | --- |
| `tbx/` | Reader functions and installed documentation |
| `docs/` | Repository guides, release notes, and the overview diagram |
| `tests/` | Regression tests, fixture generators, and validation downloads |
| `tools/` | Build/validation helpers, release checklist, Contents template, and Python build requirements |
| `buildfile.m` | Build-tool entry point for testing and packaging |
| `matlab.toml` | Development project paths and test folders |
| `.github/` | Automated tests, release publishing, and dependency updates |
| `.gitignore` | Excludes generated files and downloaded data from source control |
| `.gitattributes` | Consistent text line endings across platforms |

`tools/Contents.inc` is a build template, not a file that users run. The release
build stamps it with the version/date to create `tbx/rdatareader/Contents.m`,
which provides MATLAB's function and version listing. Only the generated
Contents.m is installed with the toolbox.

## Model object scope

[Model object support](docs/MODEL_ADAPTERS.md) describes the current limits of model
data import. Validate changes to that behavior against the originating
application, with explicit class/version and missing-value coverage.

## Handoff Checklist

Use the [release checklist](tools/RELEASE_CHECKLIST.md) before tagging a release.

- run `buildtool test`
- update the README support matrix when behavior changes
- update examples or troubleshooting notes when user-facing behavior changes

<!-- Copyright 2026 The MathWorks, Inc. -->
