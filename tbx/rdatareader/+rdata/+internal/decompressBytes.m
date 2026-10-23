function bytes = decompressBytes(bytes, compression, limits)
%DECOMPRESSBYTES Decompress supported whole-file compression wrappers.

% Copyright 2026 The MathWorks, Inc.

switch compression
    case "none"
        return
    case "gzip"
        bytes = decompressGzip(bytes, limits);
    case {"bzip2", "xz", "zstd"}
        error("rdata:UnsupportedCompression", ...
            "Compression type '%s' is detected but is not decoded by this reader.", compression)
    otherwise
        error("rdata:UnknownCompression", "Unknown compression type '%s'.", compression)
end
end

function bytes = decompressGzip(bytes, limits)
expectedSize = getGzipUncompressedSize(bytes);
if ~isnan(expectedSize) && expectedSize > limits.MaxDecompressedBytes
    error("rdata:DecompressedDataTooLarge", ...
        "The gzip stream declares a decompressed byte stream above the configured limit.")
end

tempFolder = tempname(tempdir);
mkdir(tempFolder)
cleanup = onCleanup(@() removeTempFolder(tempFolder));

gzipFile = fullfile(tempFolder, "input.gz");
fileId = fopen(gzipFile, "wb");
if fileId < 0
    error("rdata:TempFileError", "Unable to create a temporary gzip file.")
end
fileCleanup = onCleanup(@() fclose(fileId));
fwrite(fileId, bytes, "uint8");
delete(fileCleanup)

try
    outputFiles = gunzip(gzipFile, tempFolder);
catch exception
    error("rdata:InvalidHeader", "Unable to decompress gzip data: %s.", exception.message)
end

bytes = rdata.internal.readFileBytes(outputFiles{1}, limits.MaxDecompressedBytes);
if numel(bytes) > limits.MaxDecompressedBytes
    error("rdata:DecompressedDataTooLarge", ...
        "The decompressed byte stream exceeds the configured limit.")
end
end

function expectedSize = getGzipUncompressedSize(bytes)
expectedSize = NaN;
if numel(bytes) < 4
    return
end

% The final four gzip bytes are ISIZE: the uncompressed size modulo 2^32,
% stored little-endian. It is an early guard, not a complete size proof.
sizeBytes = uint32(bytes(end - 3:end));
expectedSize = double(sizeBytes(1)) + ...
    double(bitshift(sizeBytes(2), 8)) + ...
    double(bitshift(sizeBytes(3), 16)) + ...
    double(bitshift(sizeBytes(4), 24));
end

function removeTempFolder(tempFolder)
if isfolder(tempFolder)
    rmdir(tempFolder, "s")
end
end
