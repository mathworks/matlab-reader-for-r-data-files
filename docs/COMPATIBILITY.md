# Compatibility and Validation

The runtime reader requires MATLAB&reg; R2025a or later. It uses MATLAB only;
R&reg; is used for development fixtures and oracle comparisons. The TOML
project, help generation, and toolbox build require R2026b.

## Validation matrix

The version 0.1.0 GitHub&reg; validation passed on Windows&reg; and Linux&reg;
with released R2025a and R2026b builds on 23 October 2026:

| MATLAB build | Platform | Passed | Failed | Incomplete |
| --- | --- | ---: | ---: | ---: |
| R2025a Update 1 / 25.1.0.2973910 | Windows | 157 | 0 | 0 |
| R2025a Update 1 / 25.1.0.2973910 | Linux | 157 | 0 | 0 |
| R2026b / 26.2.0.3386108 | Windows | 157 | 0 | 0 |
| R2026b / 26.2.0.3386108 | Linux | 157 | 0 | 0 |

See the [completed validation matrix](https://github.com/mathworks/matlab-reader-for-r-data-files/actions/runs/39948867182)
and [release build](https://github.com/mathworks/matlab-reader-for-r-data-files/actions/runs/39951352447).
These results describe version 0.1.0; check the latest workflow run for later
changes.

Run `addpath("tools"); runValidation` from a source checkout to generate
`public/validation.json`, JUnit results, and coverage XML. On R2025a use a
disposable checkout, because the helper creates a local project definition.

## Format coverage

The suite covers binary XDR and native serialization, versions 2 and 3,
uncompressed/gzip files, missing values, arrays, factors, dates, tables,
lists, references, and unsupported-object diagnostics. Rejected compression
and serialization formats are tested. Duplicate names and timetable metadata
have 13 explicit regression cases. The suite also includes public-corpus checks,
the large Zenodo smoke test, million-element arrays, and a million-row table.

Local R2026b validation measured 855/936 covered lines (91.35%) and 81.04%
branch coverage. CI collects coverage on the fast suite and runs the large
smoke test separately without coverage instrumentation; each test runs once.

Large-vector and table tests verify correctness; their ordinary test results
are not timing benchmarks. Use the separate performance task for timings.
macOS&reg; is not in the current validation matrix.

## Package validation

The toolbox was installed and used to import a synthetic data frame with the
source project closed. The release workflow verifies that the package includes
the BSD license, security statement, static HTML help, search index, and
Getting Started script without saved third-party output. Downloaded datasets
and development-only files are excluded from the installer.

<!-- Copyright 2026 The MathWorks, Inc. -->
