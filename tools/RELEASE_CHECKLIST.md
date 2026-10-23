# Release Checklist

Use this checklist before tagging a release. Paths are relative to the
repository root.

## Scope

- Confirm `README.md` describes the implemented support matrix.
- Confirm unsupported compression, serialization formats, and R&reg; runtime
  objects are documented as limitations.
- Confirm `PreserveUnsupported="raw"` is described as an advanced diagnostic
  output, not a stable interchange format.
- Confirm the Open in MATLAB&reg; Online&trade; link points to the final public
  GitHub&reg; repository.
- Confirm repository topics are set: `matlab`, `r`, `rstats`, `rdata`, `rds`,
  `data-import`, `data-conversion`, `statistical-computing`,
  `reproducible-research`, and `matlab-tools`.

## Documentation

- Run each example in `tbx/doc`.
- Check `README.md` getting-started instructions from a fresh MATLAB session.
- Check `docs/TROUBLESHOOTING.md` for the current public error identifiers.
- Confirm copyright notices are present in source and documentation files.
- Confirm first prominent product-name uses are trademark marked in public
  documentation.
- Confirm downloaded third-party corpus files are not committed or attached to
  release assets.
- Confirm the Getting Started Live Script and generated help contain no saved
  third-party data output.
- Inspect the built toolbox for the license, security statement, and generated
  HTML help. Confirm test fixtures and converter resources are excluded.
- Check that package metadata and README both require R2025a or later.
- Run the complete suite and record exact builds in the release validation
  report. Confirm all jobs in the platform/release CI matrix pass.
- For each model adapter, verify the documented R class, package and version
  contract against its fixtures and R-oracle results.
- Confirm no editable Word or PowerPoint documents, compiled code, or
  pseudo-compiled code are included.
- Confirm no ownership, maintenance, or technical-support promise appears in
  public documentation.

Run Code Analyzer on changed `.m` files and fix actionable warnings.

## Tag

- Tag the release, for example `v0.1.0`.
- In the release notes, state that runtime importing does not require R.
- In the release notes, state the supported file formats and R object classes.

<!-- Copyright 2026 The MathWorks, Inc. -->
