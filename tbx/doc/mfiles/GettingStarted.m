%[text] # Import R Data Files
%[text] R Data Reader imports serialized R® data files into MATLAB® without requiring R at import time. It reads RDS files containing one object and R workspace files, including RData and RDA files, containing named objects.
%[text] This guide uses public economic data files from the AER package. The examples import an OECD growth cross section and a U.S. macroeconomic time-series workspace without shipping any data files in the toolbox.
%%
%[text] ## Import a Table
%[text] Use `rdata2table` when the R file contains a data frame, tibble, or other supported tabular object. The `OECDGrowth` data set contains country-level growth variables, including GDP in 1960 and 1985, investment, schooling, research and development, and population growth.
%[text] `webread` can pass downloaded content directly to R Data Reader by using a `ContentReader`.
growthUrl = "https://raw.githubusercontent.com/cran/AER/master/data/OECDGrowth.rda";
readerOptions = weboptions(Timeout=30, ContentReader=@rdata2table);
T = webread(growthUrl, readerOptions)
%%
%[text] ## Download a File for Reuse
%[text] Use `websave` when you want to keep a local copy before importing it. This is useful when a workflow needs repeatable local access to the same economic data snapshot.
downloadFolder = fullfile(tempdir, "rdatareader-examples");
if ~isfolder(downloadFolder)
    mkdir(downloadFolder)
end
localFile = fullfile(downloadFolder, "OECDGrowth.rda");
websave(localFile, growthUrl);
savedTable = rdata2table(localFile)
%%
%[text] ## Import an R Workspace
%[text] Use `readrdata` for an RData or RDA workspace file. The `USMacroSW` file stores one U.S. quarterly macroeconomic series object as an R workspace variable, and `readrdata` returns a dictionary keyed by that R object name.
macroUrl = "https://raw.githubusercontent.com/cran/AER/master/data/USMacroSW.rda";
workspaceOptions = weboptions(Timeout=30, ContentReader=@readrdata);
workspace = webread(macroUrl, workspaceOptions);
workspace.keys
head(workspace{"USMacroSW"})
%%
%[text] ## Inspect a File Before Importing
%[text] Use `rdatainfo` to inspect the file format and top-level objects without converting their contents. Here it reports that `USMacroSW` is a supported multivariate R time-series object with 193 observations and 7 variables.
infoOptions = weboptions(Timeout=30, ContentReader=@rdatainfo);
info = webread(macroUrl, infoOptions);
info.Objects
%%
%[text] ## Inspect Table Metadata
%[text] R missing values are preserved where MATLAB has a native missing value. Per-variable metadata records the R type, class, and a missing-value mask. Table-level metadata is available in `T.Properties.UserData.RDataMetadata`.
variableMetadata = T.Properties.CustomProperties.RDataVariableMetadata;
variableMetadata(:, ["VariableName", "RType", "MissingMask"])
%[text] Copyright 2026 The MathWorks, Inc.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
