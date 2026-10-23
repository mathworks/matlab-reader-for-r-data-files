function summary = summarizeRObject(robj)
%SUMMARIZEROBJECT Return a compact summary for one parsed R object.

% Copyright 2026 The MathWorks, Inc.

valueSize = inferSize(robj);
summary = struct( ...
    RType=robj.Type, ...
    RClass=robj.RClass, ...
    Size=valueSize, ...
    Names=robj.Names, ...
    Dimensions=robj.Dimensions, ...
    HasMissing=any(robj.Missing(:)), ...
    Supported=isSupported(robj));
end

function valueSize = inferSize(robj)
if ~isempty(robj.Dimensions)
    valueSize = robj.Dimensions;
elseif robj.Type == "VECSXP" && any(robj.RClass == "data.frame")
    valueSize = [inferDataFrameHeight(robj), numel(robj.Value)];
elseif iscell(robj.Value)
    valueSize = [numel(robj.Value), 1];
else
    valueSize = size(robj.Value);
end
end

function height = inferDataFrameHeight(robj)
height = 0;
rowNamesObject = getAttributeValue(robj, "row.names");
if ~isempty(rowNamesObject) && rowNamesObject.Type == "INTSXP" && numel(rowNamesObject.Value) == 2 && ...
        rowNamesObject.Missing(1) && rowNamesObject.Value(2) <= 0
    height = abs(double(rowNamesObject.Value(2)));
elseif ~isempty(rowNamesObject) && rowNamesObject.Type == "STRSXP"
    height = numel(rowNamesObject.Value);
end
if height == 0
    height = inferFirstColumnHeight(robj);
end
end

function height = inferFirstColumnHeight(robj)
height = 0;
if isempty(robj.Value)
    return
end
firstColumn = robj.Value{1};
if ~isempty(firstColumn.Dimensions)
    height = double(firstColumn.Dimensions(1));
else
    height = numel(firstColumn.Value);
end
end

function tf = isSupported(robj)
supportedTypes = ["NILSXP", "LGLSXP", "INTSXP", "REALSXP", "CPLXSXP", ...
    "RAWSXP", "STRSXP", "CHARSXP", "VECSXP"];
tf = any(robj.Type == supportedTypes) && ~any(robj.RClass == "POSIXlt");
end

function attributeValue = getAttributeValue(robj, name)
attributeValue = [];
for k = 1:numel(robj.Attributes)
    if robj.Attributes(k).Name == name
        attributeValue = robj.Attributes(k).Value;
        return
    end
end
end
