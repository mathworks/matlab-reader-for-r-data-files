# rdata2table

Read a tabular R&reg; object as a MATLAB&reg; table or timetable.

## Syntax

```matlab 
T = rdata2table(filename) 
TT = rdata2table(filename, OutputType="timetable", RowTimes="Time") 
``` 

The input can be an RDS file containing one tabular object or an RData/RDA
file containing exactly one tabular object. File type is determined from its
contents.

`OutputType` is `"table"` by default. Set it to `"timetable"` and provide the
name of the table variable to use as row times through `RowTimes` (default
`"Time"`). The variable must contain datetimes or durations. The selected
variable becomes row times and is removed from the data variables.

The same conversion options as `readrds` apply. Per-variable metadata is
stored in `T.Properties.CustomProperties.RDataVariableMetadata`; table-level
metadata is stored in `T.Properties.UserData.RDataMetadata`.
For a timetable, metadata for row times is stored separately in
`TT.Properties.CustomProperties.RDataRowTimeMetadata`; variable metadata
contains only the remaining variables in their output order.
`AttachMetadata=false` omits both custom properties.

Duplicate names raise `rdata:DuplicateNames`. Empty, missing, or reserved
table names raise `rdata:InvalidTableVariableName`. Other column names are
retained unchanged. See [readrds](readrds.md) for the name and missing-value
rules.

## See Also

[readrds](readrds.md), [readrdata](readrdata.md),
[rdatainfo](rdatainfo.md)

<!-- Copyright 2026 The MathWorks, Inc. -->
