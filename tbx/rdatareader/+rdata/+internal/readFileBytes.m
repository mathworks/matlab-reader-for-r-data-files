function bytes = readFileBytes(filename, maxBytes)
%READFILEBYTES Read a file into a uint8 row vector with size checks.

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
    maxBytes (1,1) double = rdata.internal.defaultLimits().MaxCompressedBytes;
end

fileInfo = dir(filename);

if fileInfo.bytes > maxBytes
    error("rdata:FileTooLarge", ...
        "File is too large for this importer: %s has %g bytes.", filename, fileInfo.bytes)
end

fileId = fopen(filename, "rb");
if fileId < 0
    error("rdata:FileOpenError", "Unable to open file for reading: %s.", filename)
end
cleanup = onCleanup(@() fclose(fileId));

bytes = fread(fileId, fileInfo.bytes, "uint8=>uint8").';
[~, errorNumber] = ferror(fileId);
if errorNumber ~= 0
    error("rdata:FileOpenError", "Unable to read file: %s.", filename)
end
if numel(bytes) ~= fileInfo.bytes
    error("rdata:FileOpenError", "Unable to read all bytes from file: %s.", filename)
end
end
