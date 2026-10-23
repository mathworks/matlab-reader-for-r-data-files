function info = rdatainfo(filename)
%RDATAINFO - Return metadata for an R serialized data file
%   INFO = RDATAINFO(FILENAME) inspects an .rds, .rda, .RData, or .Rdata
%   file without converting its payload to MATLAB values.
%
%   Supported payloads are parsed to produce summaries. Top-level
%   unsupported R runtime objects are reported with stable diagnostics.
%
%   INFO is a scalar structure. Its file fields are Filename, FileType,
%   Compression, SaveHeader, SerializationFormat, SerializationVersion,
%   WriterVersion, MinReaderVersion, and NativeEncoding. Objects is a table
%   with Name, RType, RClass, Size, and Supported variables. Warnings is a
%   string array reserved for nonfatal inspection diagnostics.
%   Supported indicates whether the top-level representation is recognized.
%   Nested content can still be unsupported during conversion.
%
%   Example: Inspect the objects saved in an R workspace
%       info = rdatainfo("workspace.RData");
%       disp(info.Objects)
%
%   See also readrds, readrdata, rdata2table

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
end

options = struct(Limits=rdata.internal.defaultLimits());

parsed = rdata.internal.parseRFile(filename, options);

if parsed.FileInfo.FileType == "RData"
    objectNames = [parsed.Objects.Name].';
    objectTypes = strings(numel(parsed.Objects), 1);
    objectClasses = strings(numel(parsed.Objects), 1);
    objectSizes = strings(numel(parsed.Objects), 1);
    objectSupported = false(numel(parsed.Objects), 1);
    for k = 1:numel(parsed.Objects)
        summary = rdata.internal.summarizeRObject(parsed.Objects(k).Object);
        objectTypes(k) = summary.RType;
        objectClasses(k) = strjoin(summary.RClass, ",");
        objectSizes(k) = strjoin(string(summary.Size), "x");
        objectSupported(k) = summary.Supported;
    end
else
    summary = rdata.internal.summarizeRObject(parsed.Object);
    objectNames = "";
    objectTypes = summary.RType;
    objectClasses = strjoin(summary.RClass, ",");
    objectSizes = strjoin(string(summary.Size), "x");
    objectSupported = summary.Supported;
end

info = parsed.FileInfo;
info.Objects = table(objectNames, objectTypes, objectClasses, objectSizes, objectSupported, ...
    VariableNames=["Name", "RType", "RClass", "Size", "Supported"]);
info.Warnings = strings(0, 1);
end
