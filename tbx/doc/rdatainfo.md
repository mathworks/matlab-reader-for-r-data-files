# rdatainfo

Inspect an R&reg; data file from MATLAB&reg; without converting its values.

## Syntax

```matlab 
info = rdatainfo(filename) 
``` 

`info` reports the detected file type, compression, serialization format and
version, writer version, minimum reader version, and native encoding.

`info.Objects` is a table that summarizes top-level objects with their name,
R type, R class, size, and whether the representation is recognized. This is
useful for deciding whether to import a file with `readrds`, `readrdata`, or
`rdata2table`.

## See Also

[readrds](readrds.md), [readrdata](readrdata.md),
[rdata2table](rdata2table.md)

<!-- Copyright 2026 The MathWorks, Inc. -->
