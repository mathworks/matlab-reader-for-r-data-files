function [value, metadata] = readrds(filename, options)
%READRDS - Read one object from an R serialized data file
%   X = READRDS(FILENAME) reads an R serialized single-object file and
%   converts supported R data objects to MATLAB values.
%
%   [X,METADATA] = READRDS(...) also returns file and object metadata.
%
%   X = READRDS(...,TextType=TEXTTYPE) also selects the representation
%   for R character vectors. TEXTTYPE must be:
%       "string"  - (default) Return a string array and preserve missing.
%       "cellstr" - Return a cell array of character vectors.
%
%   X = READRDS(...,IntegerType=INTEGERTYPE) also selects the
%   representation for R integer vectors. INTEGERTYPE must be:
%       "double" - (default) Return doubles and represent R NA as NaN.
%       "int32"  - Return int32 values, including the R NA sentinel.
%
%   X = READRDS(...,PreserveUnsupported=MODE) also controls unsupported
%   R objects. MODE must be:
%       "error"  - (default) Throw an error.
%       "opaque" - Return a diagnostic placeholder structure.
%       "raw"    - Return the unstable internal parsed representation.
%
%   X = READRDS(...,AttachMetadata=TF) also controls table metadata.
%   TF is true by default. When TF is false, READRDS omits metadata from
%   all converted tables but does not change the METADATA output.
%
%   METADATA is a scalar structure. Its file fields are Filename,
%   FileType, Compression, SerializationFormat, SerializationVersion,
%   WriterVersion, MinReaderVersion, and NativeEncoding. Its object fields
%   are ObjectName, RType, RClass, Names, Dimensions, Encoding, RawBytes,
%   Missing, IsReference, ReferenceIndex, and Attributes.
%
%   A converted table stores per-variable metadata in
%   T.Properties.CustomProperties.RDataVariableMetadata. This table
%   contains VariableName, RType, RClass, MissingMask, Encoding, Names,
%   Dimensions, Levels, and IsOrdered. Table-level RClass and RowNames are
%   stored in T.Properties.UserData.RDataMetadata.
%
%   With TextType="cellstr", R missing and empty strings both become ''.
%   For a top-level character vector, use METADATA.Missing to distinguish
%   them. For a direct table variable, use its MissingMask. Nested
%   character vectors in ordinary lists do not expose a corresponding mask.
%   Logical R NA becomes false, integer R NA becomes NaN for the default
%   IntegerType, and real and complex R NA values become NaN payloads.
%   Missing masks preserve these distinctions where applicable.
%
%   Example: Import a data frame and inspect its column metadata
%       T = readrds("data.rds");
%       columnMetadata = ...
%           T.Properties.CustomProperties.RDataVariableMetadata
%
%   See also readrdata, rdata2table, rdatainfo

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

parsed = rdata.internal.parseRFile(filename, options, "RDS");

value = rdata.internal.convertRObject(parsed.Object, options);

if nargout > 1
    metadata = rdata.internal.makeMetadata(parsed.Object, parsed.FileInfo, "");
end

end
