function [text, encoding] = decodeChar(bytes, gp, nativeEncoding)
%DECODECHAR Decode one R CHARSXP byte payload.

% Copyright 2026 The MathWorks, Inc.

arguments
    bytes (1,:) uint8
    gp (1,1) uint32
    nativeEncoding (1,1) string = "UTF-8"
end

encoding = encodingFromGp(gp);

switch encoding
    case {'ASCII', 'UTF-8', 'native'}
        if encoding == "native" && strlength(nativeEncoding) > 0
            text = string(native2unicode(bytes, nativeEncoding));
        else
            text = string(native2unicode(bytes, "UTF-8"));
        end
    case {'latin1', 'bytes'}
        text = string(native2unicode(bytes, "ISO-8859-1"));
    otherwise
        text = string(native2unicode(bytes, "UTF-8"));
end
end

function encoding = encodingFromGp(gp)
if bitand(gp, uint32(64)) ~= 0
    encoding = "ASCII";
elseif bitand(gp, uint32(8)) ~= 0
    encoding = "UTF-8";
elseif bitand(gp, uint32(4)) ~= 0
    encoding = "latin1";
elseif bitand(gp, uint32(2)) ~= 0
    encoding = "bytes";
else
    encoding = "native";
end
end
