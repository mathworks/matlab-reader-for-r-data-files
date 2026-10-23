# Release Validation

Validation for version 0.1.0, performed on 23 October 2026 with MATLAB&reg;
on Windows&reg;. R&reg; 4.6.1 generated synthetic fixtures and oracle results.

| MATLAB release / exact build | Passed | Failed | Incomplete |
| --- | ---: | ---: | ---: |
| R2026b / 26.2.0.3386108 | 157 | 0 | 0 |


The GitHub&reg; workflow is configured to validate the released R2025a and R2026b
builds on both Windows and Linux&reg;; those remote results must be checked after
publication. Additional local compatibility checks passed, but are not a
substitute for the released-build CI results.

The suite includes synthetic conversion tests, R-oracle comparisons, public
corpus checks, the large Zenodo smoke test, million-element arrays, a
million-row table, and 13 new name/metadata regression cases.

Measured R2026b line coverage was 855/936 lines (91.35%); branch coverage was
81.04%. Ordinary performance-class test runs verify correctness, not timing
benchmarks. Subsequent CI runs instrument the fast suite and run the large
smoke test separately, once, without coverage overhead.

The generated toolbox was installed and used to import a synthetic data frame
with the source project closed. The archive includes the BSD license, security
statement, static HTML help, search index, and output-free Getting Started
script. The release workflow verifies package contents before attaching it to
a release.

<!-- Copyright 2026 The MathWorks, Inc. -->
