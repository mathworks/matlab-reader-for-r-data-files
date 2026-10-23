# R Data Reader

Import serialized R&reg; data files into MATLAB&reg; without running R at import time.
The reader supports RDS files containing one object and RData or RDA workspace
files containing named objects.

## Start Here

- [Getting Started](getting-started.md) downloads example data when run.
- [readrds](readrds.md) imports one object from an RDS file.
- [readrdata](readrdata.md) imports named objects from an R workspace.
- [rdata2table](rdata2table.md) imports a data frame or tibble as a table.
- [rdatainfo](rdatainfo.md) inspects file metadata without conversion.

## Main Concepts

R vectors, arrays, factors, dates, datetimes, durations, lists, data frames,
and tibbles convert to corresponding MATLAB values where supported. Named R
lists and workspace objects become dictionaries, preserving unique R names.
Duplicate names raise `rdata:DuplicateNames` instead of discarding values.

The reader preserves metadata such as R type, class, missing-value masks,
encodings, dimensions, and table variable names. Tables store this information
in `Properties.CustomProperties.RDataVariableMetadata` and
`Properties.UserData.RDataMetadata`.

R runtime objects such as functions and environments are not executable in
MATLAB. By default they produce an error; use `PreserveUnsupported="opaque"`
when structural diagnostics are useful.

<!-- Copyright 2026 The MathWorks, Inc. -->
