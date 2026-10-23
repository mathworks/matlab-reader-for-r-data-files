function robj = applyKnownAttributes(robj)
%APPLYKNOWNATTRIBUTES Copy common R attributes into top-level IR fields.

% Copyright 2026 The MathWorks, Inc.

for k = 1:numel(robj.Attributes)
    entry = robj.Attributes(k);
    switch entry.Name
        case "names"
            if entry.Value.Type == "STRSXP"
                robj.Names = entry.Value.Value(:);
            end
        case "class"
            if entry.Value.Type == "STRSXP"
                robj.RClass = entry.Value.Value(:);
            end
        case "dim"
            if entry.Value.Type == "INTSXP"
                robj.Dimensions = double(entry.Value.Value(:).');
            end
        otherwise
            % Other attributes remain available through robj.Attributes.
    end
end
end

