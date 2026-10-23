function T = rdata2table(filename, options)
%rdata2table - Read a tabular R object as a MATLAB table or timetable
%   T = rdata2table(FILENAME) reads an .rds or single-table .RData file and
%   returns the imported table. File type is detected from the contents.
%
%   TT = rdata2table(...,OutputType="timetable") uses the Time variable
%   as row times. Its values must be datetimes or durations.
%
%   TT = rdata2table(...,OutputType="timetable",RowTimes=NAME) uses the
%   variable NAME instead. RowTimes is ignored for table output.
%
%   T = rdata2table(...,TextType=TEXTTYPE) also selects the representation
%   for R character vectors. TEXTTYPE must be:
%       "string"  - (default) Return a string array and preserve missing.
%       "cellstr" - Return a cell array of character vectors.
%
%   T = rdata2table(...,IntegerType=INTEGERTYPE) also selects the
%   representation for R integer vectors. INTEGERTYPE must be:
%       "double" - (default) Return doubles and represent R NA as NaN.
%       "int32"  - Return int32 values, including the R NA sentinel.
%
%   T = rdata2table(...,PreserveUnsupported=MODE) also controls unsupported
%   nested R objects. MODE must be:
%       "error"  - (default) Throw an error.
%       "opaque" - Return a diagnostic placeholder structure.
%       "raw"    - Return the unstable internal parsed representation.
%
%   T = rdata2table(...,AttachMetadata=TF) also controls table metadata.
%   TF is true by default. When TF is false, rdata2table omits metadata
%   from all converted tables, including nested tables.
%
%   An .rds file must contain a tabular object. An R workspace file must
%   contain exactly one object, and that object must be tabular.
%
%   Per-variable metadata is stored in
%   T.Properties.CustomProperties.RDataVariableMetadata. This table
%   contains VariableName, RType, RClass, MissingMask, Encoding, Names,
%   Dimensions, Levels, and IsOrdered. Table-level RClass and RowNames are
%   stored in T.Properties.UserData.RDataMetadata. For timetables, the
%   row-time variable's metadata is in the RDataRowTimeMetadata custom
%   property, separate from metadata for the remaining variables.
%
%   Duplicate names are rejected with rdata:DuplicateNames. Empty,
%   missing, and reserved table names are rejected with
%   rdata:InvalidTableVariableName. Other names are retained unchanged.
%
%   With TextType="cellstr", R missing and empty strings both become ''.
%   Use a variable's MissingMask in RDataVariableMetadata to distinguish
%   them. Missing masks also preserve lossy logical, integer, real, and
%   complex missing-value conversions where applicable.
%
%   Example: Import a table and inspect a text variable's missing mask
%       T = rdata2table("data.rds");
%       variableMetadata = ...
%           T.Properties.CustomProperties.RDataVariableMetadata;
%       textMissing = variableMetadata.MissingMask{1}
%
%   See also readrds, readrdata, rdatainfo

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
    options.TextType (1,1) string {mustBeMember(options.TextType, ["string", "cellstr"])} = "string"
    options.IntegerType (1,1) string {mustBeMember(options.IntegerType, ["double", "int32"])} = "double"
    options.PreserveUnsupported (1,1) string ...
        {mustBeMember(options.PreserveUnsupported, ["error", "opaque", "raw"])} = "error"
    options.AttachMetadata (1,1) logical = true
    options.OutputType (1,1) string {mustBeMember(options.OutputType, ["table", "timetable"])} = "table"
    options.RowTimes (1,1) string = "Time"
end

output = options.OutputType;
options.Limits = rdata.internal.defaultLimits();

parsed = rdata.internal.parseRFile(filename, options);
if parsed.FileInfo.FileType == "RDS"
    T = rdata.internal.convertRObject(parsed.Object, options);
else
    if numel(parsed.Objects) ~= 1
        error("rdata:UnsupportedRType", ...
            "R workspace file must contain exactly one object.")
    end
    T = rdata.internal.convertRObject(parsed.Objects(1).Object, options);
end

if ~istable(T)
    error("rdata:UnsupportedRType", "Imported R object is not tabular.")
end

if output == "timetable"
    if options.AttachMetadata
        variableMetadata = T.Properties.CustomProperties.RDataVariableMetadata;
    end
    T = table2timetable(T, RowTimes=options.RowTimes);
    if options.AttachMetadata
        isRowTime = variableMetadata.VariableName == options.RowTimes;
        T.Properties.CustomProperties.RDataVariableMetadata = ...
            variableMetadata(~isRowTime, :);
        T = addprop(T, "RDataRowTimeMetadata", "table");
        T.Properties.CustomProperties.RDataRowTimeMetadata = ...
            variableMetadata(isRowTime, :);
    end
end

end
