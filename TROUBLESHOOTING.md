# Troubleshooting

## Unsupported Compression

`rdata:UnsupportedCompression` means the file is compressed with bzip2, xz, or
zstd. The reader supports uncompressed and gzip-compressed R&reg; serialization
streams using documented MATLAB&reg; functionality. Re-save the file from R with
gzip or no compression:

```r
save(obj, file = "data.RData", compress = "gzip", version = 3)
saveRDS(obj, file = "data.rds", compress = "gzip", version = 3)
```

## Unsupported Serialization Format

`rdata:UnsupportedSerializationFormat` usually means the file uses R ASCII
serialization. Re-save with the default XDR binary format:

```r
saveRDS(obj, file = "data.rds", ascii = FALSE, version = 3)
```

## Unsupported R Object Type

`rdata:UnsupportedRType` means the file contains an R runtime object that this
reader does not reconstruct, such as a function, formula, environment, promise,
external pointer, bytecode object, or package-specific object.

Use `rdatainfo(filename)` to inspect the file. If you still want to keep a
placeholder for unsupported objects, use:

```matlab
x = readrds(filename, PreserveUnsupported="opaque");
```

## Missing Rscript During Tests

R is not required to import files. It is only used for fixture regeneration
and oracle tests. If `rdata:MissingRscript` occurs, either install R or set:

```matlab
setenv("RDATA_RSCRIPT", "path-to-Rscript")
```

## Name Changes

Original R names are retained, including spaces and punctuation. Duplicate
names raise `rdata:DuplicateNames`; no values are overwritten. Empty, missing,
or reserved table column names (`:`, `Properties`, `Row`, `Variables`) raise
`rdata:InvalidTableVariableName`. Rename those columns or list elements in R
before saving. There is no `VariableNamingRule` option.

## Metadata Differences from CSV Baselines

CSV, TSV, XLSX, and MAT comparison files often lose R-specific metadata such as
factor levels, classes, encodings, and R missing-value distinctions. Use the
metadata output from `readrds`, `readrdata`, or `rdatainfo` for R-specific
details.

<!-- Copyright 2026 The MathWorks, Inc. -->
