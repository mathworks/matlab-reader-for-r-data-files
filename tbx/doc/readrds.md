# readrds

Read one object from an RDS file.

## Syntax

```matlab
value = readrds(filename) 
[value, metadata] = readrds(filename) 
```

`readrds` converts supported R&reg; objects to their natural MATLAB&reg;
representations. For example, R data frames become tables, named lists become
dictionaries, and character vectors become string arrays.

## Options

```matlab
value = readrds(filename, TextType="cellstr"); 
value = readrds(filename, IntegerType="int32"); 
value = readrds(filename, PreserveUnsupported="opaque"); 
```

`TextType` is `"string"` by default. `IntegerType` is `"double"` by default,
which represents missing R integers as `NaN`. `PreserveUnsupported` is
`"error"` by default; `"opaque"` returns a diagnostic placeholder and `"raw"`
returns an unstable internal representation.

`AttachMetadata=true` (default) attaches per-variable metadata to every
converted table, including nested tables. Set it to `false` to omit that
attached metadata. The separate second output is still returned if requested.

Missing logical values become `false`. With `TextType="cellstr"`, missing
and empty strings both become `''`. With `IntegerType="int32"`, missing
integers retain `intmin("int32")`. Use the separate metadata or a table's
`Properties.CustomProperties.RDataVariableMetadata.MissingMask` to distinguish
these cases. Double arrays use `NaN` for missing integers and reals; metadata
distinguishes an R missing real from an ordinary NaN.

Duplicate names in data frames, named lists, or workspaces raise
`rdata:DuplicateNames`. Empty, missing, or reserved table column names
(`:`, `Properties`, `Row`, `Variables`) raise `rdata:InvalidTableVariableName`.
Other names are preserved, including punctuation. Rename rejected columns or
list elements in R before saving the file.

The optional `metadata` output records the file format and the imported
object's R type, class, names, dimensions, encoding, missing-value mask, and
attributes.

## See Also

[readrdata](readrdata.md), [rdata2table](rdata2table.md),
[rdatainfo](rdatainfo.md)

<!-- Copyright 2026 The MathWorks, Inc. -->
