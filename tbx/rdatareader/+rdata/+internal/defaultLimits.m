function limits = defaultLimits()
%DEFAULTLIMITS Return internal parser resource limits.
%   These are importer guardrails, not R format limits. They
%   keep malformed or unexpectedly large files from allocating unbounded
%   memory while still allowing large analytical data objects.

% Copyright 2026 The MathWorks, Inc.

limits = struct( ...
    MaxCompressedBytes=512*1024*1024, ...     % input-file size guard
    MaxDecompressedBytes=2*1024*1024*1024, ... % decompressed stream guard
    MaxVectorElements=100000000, ...          % per-vector allocation guard
    MaxStringBytes=256*1024*1024, ...         % per-CHARSXP element guard
    MaxRecursionDepth=256, ...                % nested SEXP traversal guard
    MaxObjectCount=5000000);                  % reference-table growth guard
end
