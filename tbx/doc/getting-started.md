# Getting Started

Import R&reg; data into MATLAB&reg; as tables, arrays, or dictionaries. These
examples download public data from the AER package when run. The toolbox does
not distribute the downloaded data or saved numeric output.

## Import a table from a URL

```matlab
url = "https://raw.githubusercontent.com/cran/AER/master/data/OECDGrowth.rda";
options = weboptions(Timeout=30, ContentReader=@rdata2table);
T = webread(url, options);
head(T)
```

## Inspect a workspace

```matlab
url = "https://raw.githubusercontent.com/cran/AER/master/data/USMacroSW.rda";
options = weboptions(Timeout=30, ContentReader=@readrdata);
workspace = webread(url, options);
workspace.keys
head(workspace{"USMacroSW"})
```

## Inspect missing-value metadata

```matlab
metadata = T.Properties.CustomProperties.RDataVariableMetadata;
metadata(:, ["VariableName", "RType", "MissingMask"])
```

For local files, use `rdata2table("data.rds")`, `readrds("data.rds")`,
`readrdata("workspace.RData")`, or `rdatainfo("data.rds")`.

The installed toolbox also includes the interactive Live Script
[GettingStarted.m](mfiles/GettingStarted.m). Running it displays results in your
session. Saved third-party outputs must be cleared before redistributing it.

## Next steps

[readrds](readrds.md) describes conversion and missing-value options.
[rdata2table](rdata2table.md) explains tables and timetables.

<!-- Copyright 2026 The MathWorks, Inc. -->
