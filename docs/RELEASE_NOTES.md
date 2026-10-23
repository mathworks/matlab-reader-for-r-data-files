# Release Notes

## 0.1.0

Initial release of MATLAB&reg; Reader for R&reg; Data Files.

- Import RDS objects and RData/RDA workspaces without running R.
- Convert analytical vectors, arrays, factors, dates, lists, and data frames.
- Inspect serialization metadata and unsupported objects.
- Preserve missing-value metadata, including separate timetable row-time
  metadata.
- Reject duplicate and unrepresentable table names explicitly to prevent
  silent data loss.
- Include an interactive Getting Started guide and searchable HTML help.

Requires MATLAB R2025a or later. Supports uncompressed/gzip binary XDR and
native serialization, versions 2 and 3. See [README.md](../README.md) for the
support matrix and limitations, and [COMPATIBILITY.md](COMPATIBILITY.md) for
validation details.

<!-- Copyright 2026 The MathWorks, Inc. -->
