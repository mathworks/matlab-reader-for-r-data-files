# Compatibility and Validation

The runtime reader requires MATLAB&reg; R2025a or later. It uses MATLAB only;
R&reg; is used for development fixtures and oracle comparisons. The TOML
project, help generation, and toolbox build require R2026b.

## Validation matrix

The GitHub&reg; workflow runs the complete suite on Windows&reg; and Linux&reg; with
R2025a and R2026b. This includes generated synthetic fixtures, R-oracle
comparisons, public corpus checks, and large-array correctness tests.

| Environment | Validation |
| --- | --- |
| Windows, R2026b | 157/157 passed locally; build 26.2.0.3386108 |
| Windows, released R2025a | Configured CI matrix; released-build result pending |
| Linux, R2025a and R2026b | Configured CI matrix; consult the published workflow results |

See [VALIDATION.md](VALIDATION.md) for exact results and qualifications.
CI configuration is not evidence that a remote run passed.

Run `addpath("tools"); runValidation` from a source checkout to generate
`public/validation.json`, JUnit results, and coverage XML. On R2025a use a
disposable checkout, because the helper creates a local project definition.

## Format coverage

The suite covers binary XDR and native serialization, versions 2 and 3,
uncompressed/gzip files, missing values, arrays, factors, dates, tables,
lists, references, and unsupported-object diagnostics. Rejected compression
and serialization formats are tested. Duplicate names and timetable metadata
have explicit regression coverage.

Large-vector and table tests verify correctness; their ordinary test results
are not timing benchmarks. Use the separate performance task for timings.
macOS&reg; is not in the current validation matrix.

<!-- Copyright 2026 The MathWorks, Inc. -->
