function [workspace, metadata] = readrdata(filename, options)
%READRDATA - Read named objects from an R workspace file
%   S = READRDATA(FILENAME) reads an R workspace save file and returns a
%   dictionary containing supported saved objects.
%
%   [S,METADATA] = READRDATA(...) also returns file and object metadata.
%
%   S = READRDATA(...,TextType=TEXTTYPE) also selects the representation
%   for R character vectors. TEXTTYPE must be:
%       "string"  - (default) Return a string array and preserve missing.
%       "cellstr" - Return a cell array of character vectors.
%
%   S = READRDATA(...,IntegerType=INTEGERTYPE) also selects the
%   representation for R integer vectors. INTEGERTYPE must be:
%       "double" - (default) Return doubles and represent R NA as NaN.
%       "int32"  - Return int32 values, including the R NA sentinel.
%
%   S = READRDATA(...,PreserveUnsupported=MODE) also controls unsupported
%   R objects. MODE must be:
%       "error"  - (default) Throw an error.
%       "opaque" - Return a diagnostic placeholder structure.
%       "raw"    - Return the unstable internal parsed representation.
%
%   S = READRDATA(...,AttachMetadata=TF) also controls table metadata.
%   TF is true by default. When TF is false, READRDATA omits metadata from
%   all converted tables but does not change the METADATA output.
%
%   METADATA is a scalar structure. Its file fields are Filename,
%   FileType, Compression, SerializationFormat, SerializationVersion,
%   WriterVersion, MinReaderVersion, and NativeEncoding. Objects is a
%   structure array with the object metadata fields documented by READRDS.
%
%   A converted table stores per-variable metadata in
%   T.Properties.CustomProperties.RDataVariableMetadata. Table-level
%   metadata is stored in T.Properties.UserData.RDataMetadata. These
%   locations also apply to tables stored in the returned dictionary.
%
%   With TextType="cellstr", R missing and empty strings both become ''.
%   For a saved top-level character vector, use
%   METADATA.Objects(k).Missing to distinguish them. For a direct table
%   variable, use its MissingMask. Nested character vectors in ordinary
%   lists do not expose a corresponding mask. Missing masks also preserve
%   lossy logical, integer, real, and complex missing-value conversions
%   where applicable.
%
%   Example: Import a workspace and retrieve an object by its R name
%       S = readrdata("workspace.RData");
%       value = S{"object name"}
%
%   See also readrds, rdata2table, rdatainfo

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
    options.TextType (1,1) string {mustBeMember(options.TextType, ["string", "cellstr"])} = "string"
    options.IntegerType (1,1) string {mustBeMember(options.IntegerType, ["double", "int32"])} = "double"
    options.PreserveUnsupported (1,1) string ...
        {mustBeMember(options.PreserveUnsupported, ["error", "opaque", "raw"])} = "error"
    options.AttachMetadata (1,1) logical = true
end

options.Limits = rdata.internal.defaultLimits();
parsed = rdata.internal.parseRFile(filename, options, "RData");

objects = parsed.Objects(:);
names = [objects.Name].';

% Workspace dictionary
workspace = rdata.internal.convertNamedObjects( ...
    {objects.Object}.', names, options);

if nargout > 1
    % make metadata
    objectMetadata = arrayfun(@(object) rdata.internal.makeMetadata( ...
        object.Object, parsed.FileInfo, object.Name), objects);

    metadata = struct( ...
        Filename=parsed.FileInfo.Filename, ...
        FileType=parsed.FileInfo.FileType, ...
        Compression=parsed.FileInfo.Compression, ...
        SerializationFormat=parsed.FileInfo.SerializationFormat, ...
        SerializationVersion=parsed.FileInfo.SerializationVersion, ...
        WriterVersion=parsed.FileInfo.WriterVersion, ...
        MinReaderVersion=parsed.FileInfo.MinReaderVersion, ...
        NativeEncoding=parsed.FileInfo.NativeEncoding, ...
        Objects=objectMetadata);
end

end
