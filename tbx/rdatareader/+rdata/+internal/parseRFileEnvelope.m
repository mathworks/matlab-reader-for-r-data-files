function envelope = parseRFileEnvelope(filename, limits)
%PARSERFILEENVELOPE Read compression and serialization headers.

% Copyright 2026 The MathWorks, Inc.

originalBytes = rdata.internal.readFileBytes(filename, limits.MaxCompressedBytes);
compression = rdata.internal.detectCompression(originalBytes);
bytes = rdata.internal.decompressBytes(originalBytes, compression, limits);

[fileType, saveHeader, streamBytes] = splitSaveHeader(bytes, filename);
[header, payloadBytes] = readSerializationHeader(streamBytes, filename);

fileInfo = struct( ...
    Filename=filename, ...
    FileType=fileType, ...
    Compression=compression, ...
    SaveHeader=saveHeader, ...
    SerializationFormat=header.Format, ...
    SerializationVersion=header.Version, ...
    WriterVersion=header.WriterVersion, ...
    MinReaderVersion=header.MinReaderVersion, ...
    NativeEncoding=header.NativeEncoding);

envelope = struct( ...
    FileInfo=fileInfo, ...
    StreamBytes=streamBytes, ...
    PayloadBytes=payloadBytes);
end

function [fileType, saveHeader, streamBytes] = splitSaveHeader(bytes, filename)
if isempty(bytes)
    error("rdata:InvalidHeader", "File is empty: %s.", filename)
end

if numel(bytes) >= 5
    firstLine = string(native2unicode(bytes(1:5), "US-ASCII"));
else
    firstLine = "";
end

% R workspace files add a five-byte save header before the serialization
% stream: RDXn for XDR, RDBn for native binary, and RDAn for ASCII payloads.
if any(firstLine == ["RDX2" + newline, "RDX3" + newline, ...
        "RDB2" + newline, "RDB3" + newline, ...
        "RDA2" + newline, "RDA3" + newline])
    fileType = "RData";
    saveHeader = erase(firstLine, newline);
    streamBytes = bytes(6:end);
    if startsWith(saveHeader, "RDA")
        error("rdata:UnsupportedSerializationFormat", ...
            "ASCII R workspace save files are detected but not supported: %s.", filename)
    end
else
    fileType = "RDS";
    saveHeader = "";
    streamBytes = bytes;
end
end

function [header, payloadBytes] = readSerializationHeader(streamBytes, filename)
lineEnd = find(streamBytes == uint8(10), 1);
if isempty(lineEnd)
    error("rdata:InvalidHeader", "File has a truncated R serialization header: %s.", filename)
end

formatBytes = streamBytes(1:lineEnd - 1);
formatText = string(native2unicode(formatBytes(formatBytes ~= uint8(13)), "US-ASCII"));
remainingBytes = streamBytes(lineEnd + 1:end);

% R serialization streams begin with an ASCII format line: X for XDR,
% A for ASCII, or B for native-endian binary.
if formatText == "X"
    format = "XDR";
elseif formatText == "A"
    error("rdata:UnsupportedSerializationFormat", ...
        "ASCII R serialization streams are detected but not supported: %s.", filename)
elseif formatText == "B"
    format = "native";
else
    error("rdata:InvalidHeader", "File does not contain a supported R serialization header: %s.", filename)
end

reader = rdata.internal.SerializationReader(remainingBytes, format);
version = double(reader.readInt32());
writerVersion = decodeRVersion(reader.readUInt32());
minReaderVersion = decodeRVersion(reader.readUInt32());
if version ~= 2 && version ~= 3
    error("rdata:UnsupportedSerializationVersion", ...
        "Unsupported R serialization version %g in %s.", version, filename)
end

nativeEncoding = "";
if version >= 3
    encodingLength = double(reader.readInt32());
    if encodingLength < 0
        error("rdata:InvalidLength", "Invalid native encoding length in %s.", filename)
    end
    encodingBytes = reader.readBytes(encodingLength);
    nativeEncoding = string(native2unicode(encodingBytes, "UTF-8"));
end

header = struct( ...
    Format=format, ...
    Version=version, ...
    WriterVersion=writerVersion, ...
    MinReaderVersion=minReaderVersion, ...
    NativeEncoding=nativeEncoding);
payloadBytes = remainingBytes(reader.Position:end);
end

function versionText = decodeRVersion(packedVersion)
major = floor(double(packedVersion)/65536);
minor = floor(mod(double(packedVersion), 65536)/256);
patch = mod(double(packedVersion), 256);
versionText = string(sprintf("%d.%d.%d", major, minor, patch));
end
