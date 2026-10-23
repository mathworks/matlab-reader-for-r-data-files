function lengthValue = readRLength(reader, limits)
%READRLENGTH Read an R serialized vector length.

% Copyright 2026 The MathWorks, Inc.

lengthValue = double(reader.readInt32());
if lengthValue == -1
    % R uses -1 as the sentinel for a serialized long-vector length, then
    % stores the high and low uint32 words of the element count.
    upper = double(reader.readUInt32());
    lower = double(reader.readUInt32());
    lengthValue = upper*4294967296 + lower;
end

if lengthValue < 0
    error("rdata:InvalidLength", "R serialization stream contains a negative length.")
end

if lengthValue > limits.MaxVectorElements
    error("rdata:VectorTooLarge", ...
        "R vector length %g exceeds the configured importer limit.", lengthValue)
end
end
