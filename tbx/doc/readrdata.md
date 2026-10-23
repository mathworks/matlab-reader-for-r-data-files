# readrdata

Read named objects from an R&reg; RData or RDA workspace file.

## Syntax

```matlab 
workspace = readrdata(filename) 
[workspace, metadata] = readrdata(filename) 
``` 

`workspace` is a MATLAB&reg; dictionary. Each key is the original name of an
object saved in the R workspace.
Duplicate object names raise `rdata:DuplicateNames` instead of discarding data.

Retrieve an object with its R name, including a name that is not a valid
MATLAB identifier:

```matlab 
object = workspace{"object name"}; 
``` 

The options `TextType`, `IntegerType`, `PreserveUnsupported`, and
`AttachMetadata` have the same meaning as for `readrds`.

## See Also

[readrds](readrds.md), [rdata2table](rdata2table.md),
[rdatainfo](rdatainfo.md)

<!-- Copyright 2026 The MathWorks, Inc. -->
