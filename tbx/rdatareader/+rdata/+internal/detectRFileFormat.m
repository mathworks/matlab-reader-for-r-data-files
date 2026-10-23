function info = detectRFileFormat(filename)
%DETECTRFILEFORMAT Detect R data file headers and compression.

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
end

limits = rdata.internal.defaultLimits();
envelope = rdata.internal.parseRFileEnvelope(filename, limits);
info = envelope.FileInfo;
end

