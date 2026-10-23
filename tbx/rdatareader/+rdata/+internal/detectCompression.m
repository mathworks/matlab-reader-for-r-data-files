function compression = detectCompression(bytes)
%DETECTCOMPRESSION Detect compression from leading magic bytes.

% Copyright 2026 The MathWorks, Inc.

if numel(bytes) >= 2 && isequal(bytes(1:2), uint8([31 139]))
    compression = "gzip";
elseif numel(bytes) >= 3 && isequal(bytes(1:3), uint8('BZh'))
    compression = "bzip2";
elseif numel(bytes) >= 6 && isequal(bytes(1:6), uint8([253 55 122 88 90 0]))
    compression = "xz";
elseif numel(bytes) >= 4 && isequal(bytes(1:4), uint8([40 181 47 253]))
    compression = "zstd";
else
    compression = "none";
end
end
