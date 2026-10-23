function value = convertRObject(robj, options)
%CONVERTROBJECT Convert a parsed R object to a MATLAB value.

% Copyright 2026 The MathWorks, Inc.

if isDateObject(robj)
    value = convertDate(robj);
    return
end

if isPosixctObject(robj)
    value = convertPosixct(robj);
    return
end

if isDifftimeObject(robj)
    value = convertDifftime(robj);
    return
end

if isPosixltObject(robj)
    if options.PreserveUnsupported == "error"
        error("rdata:UnsupportedRClass", "R POSIXlt objects are not reconstructed.")
    end
    value = convertUnsupported(robj, options);
    return
end

if isDataFrame(robj)
    value = convertDataFrame(robj, options);
    return
end

if isFactor(robj)
    value = convertFactor(robj);
    return
end

switch robj.Type
    case "NILSXP"
        value = [];
    case "LGLSXP"
        value = convertLogical(robj);
    case "INTSXP"
        value = convertInteger(robj, options);
    case "REALSXP"
        value = robj.Value;
    case "CPLXSXP"
        value = robj.Value;
    case "RAWSXP"
        value = robj.Value;
    case "STRSXP"
        value = convertString(robj, options);
    case "VECSXP"
        value = convertList(robj, options);
    case "CHARSXP"
        value = robj.Value;
    otherwise
        value = convertUnsupported(robj, options);
end

value = applyDimensions(value, robj);
end

function tf = isFactor(robj)
tf = any(robj.RClass == "factor");
end

function tf = isDateObject(robj)
tf = any(robj.RClass == "Date");
end

function tf = isPosixctObject(robj)
tf = any(robj.RClass == "POSIXct");
end

function tf = isDifftimeObject(robj)
tf = any(robj.RClass == "difftime");
end

function tf = isPosixltObject(robj)
tf = any(robj.RClass == "POSIXlt");
end

function value = convertDate(robj)
daysSinceEpoch = double(robj.Value);
daysSinceEpoch(robj.Missing) = NaN;
value = datetime(1970, 1, 1) + days(daysSinceEpoch);
value(robj.Missing) = NaT;
value = applyDimensions(value(:), robj);
end

function value = convertPosixct(robj)
secondsSinceEpoch = double(robj.Value);
secondsSinceEpoch(robj.Missing) = NaN;
timeZone = getTimeZone(robj);
value = datetime(secondsSinceEpoch, ConvertFrom="posixtime", TimeZone=timeZone);
value(robj.Missing) = NaT;
value = applyDimensions(value(:), robj);
end

function timeZone = getTimeZone(robj)
timeZoneObject = getAttributeValue(robj, "tzone");
timeZone = "UTC";
if ~isempty(timeZoneObject) && timeZoneObject.Type == "STRSXP" && numel(timeZoneObject.Value) > 0
    candidates = timeZoneObject.Value(strlength(timeZoneObject.Value) > 0);
    if ~isempty(candidates)
        timeZone = candidates(1);
    end
end
end

function value = convertDifftime(robj)
numericValue = double(robj.Value);
numericValue(robj.Missing) = NaN;
unitsObject = getAttributeValue(robj, "units");
units = "secs";
if ~isempty(unitsObject) && unitsObject.Type == "STRSXP" && numel(unitsObject.Value) > 0
    units = unitsObject.Value(1);
end

switch units
    case "secs"
        value = seconds(numericValue);
    case "mins"
        value = minutes(numericValue);
    case "hours"
        value = hours(numericValue);
    case "days"
        value = days(numericValue);
    case "weeks"
        value = days(7*numericValue);
    otherwise
        error("rdata:UnsupportedRClass", "Unsupported R difftime units '%s'.", units)
end
value(robj.Missing) = seconds(NaN);
value = applyDimensions(value(:), robj);
end

function tf = isDataFrame(robj)
tf = robj.Type == "VECSXP" && any(robj.RClass == "data.frame");
end

function value = convertDataFrame(robj, options)
columnObjects = robj.Value;
numColumns = numel(columnObjects);
originalNames = robj.Names;
if numel(originalNames) ~= numColumns
    originalNames = "Var" + string(1:numColumns).';
end

if numel(unique(originalNames)) ~= numColumns
    error("rdata:DuplicateNames", ...
        "Duplicate R column names cannot be represented without losing data. " + ...
        "Give each column a unique name in R before saving.")
end
if any(ismissing(originalNames) | strlength(originalNames) == 0 | ...
        ismember(originalNames, [":", "Properties", "Row", "Variables"]))
    error("rdata:InvalidTableVariableName", ...
        "An R column name is empty, missing, or reserved by MATLAB tables. " + ...
        "Rename the column in R before saving.")
end

value = table();

for k = 1:numColumns
    columnValue = rdata.internal.convertRObject(columnObjects{k}, options);
    columnValue = normalizeTableColumn(columnValue);
    value.(originalNames(k)) = columnValue;
end

rowNames = decodeRowNames(getAttributeValue(robj, "row.names"), height(value));
if options.AttachMetadata
    value = addprop(value, "RDataVariableMetadata", "table");
    variableMetadata = makeVariableMetadata(columnObjects, originalNames);
    value.Properties.CustomProperties.RDataVariableMetadata = variableMetadata;
    value.Properties.UserData.RDataMetadata = struct( ...
        RClass=robj.RClass, ...
        RowNames=rowNames);
end
end

function variableMetadata = makeVariableMetadata(columnObjects, variableNames)
numColumns = numel(columnObjects);
rType = strings(numColumns, 1);
rClass = cell(numColumns, 1);
missingMask = cell(numColumns, 1);
encoding = cell(numColumns, 1);
names = cell(numColumns, 1);
dimensions = cell(numColumns, 1);
levels = cell(numColumns, 1);
isOrdered = false(numColumns, 1);

for k = 1:numColumns
    column = columnObjects{k};
    rType(k) = column.Type;
    rClass{k} = column.RClass;
    missingMask{k} = column.Missing;
    encoding{k} = column.Encoding;
    names{k} = column.Names;
    dimensions{k} = column.Dimensions;
    levelsObject = getAttributeValue(column, "levels");
    if ~isempty(levelsObject) && levelsObject.Type == "STRSXP"
        levels{k} = levelsObject.Value;
    else
        levels{k} = strings(0, 1);
    end
    isOrdered(k) = any(column.RClass == "ordered");
end

variableMetadata = table( ...
    variableNames(:), ...
    rType, ...
    rClass, ...
    missingMask, ...
    encoding, ...
    names, ...
    dimensions, ...
    levels, ...
    isOrdered, ...
    VariableNames=["VariableName", "RType", "RClass", ...
    "MissingMask", "Encoding", "Names", "Dimensions", "Levels", "IsOrdered"]);
end

function columnValue = normalizeTableColumn(columnValue)
if isrow(columnValue) && ~ischar(columnValue)
    columnValue = columnValue.';
end
end

function rowNames = decodeRowNames(rowNamesObject, tableHeight)
rowNames = strings(0, 1);
if isempty(rowNamesObject)
    return
end

if rowNamesObject.Type == "STRSXP"
    rowNames = rowNamesObject.Value(:);
elseif rowNamesObject.Type == "INTSXP" && numel(rowNamesObject.Value) == 2 && ...
        rowNamesObject.Missing(1) && rowNamesObject.Value(2) <= 0
    rowNames = string((1:tableHeight).');
elseif rowNamesObject.Type == "INTSXP"
    rowNames = string(rowNamesObject.Value(:));
end
end

function value = convertList(robj, options)
elements = robj.Value;
names = robj.Names;
if isNamedList(names, numel(elements))
    value = rdata.internal.convertNamedObjects(elements, names, options);
else
    value = cell(numel(elements), 1);
    for k = 1:numel(elements)
        value{k} = rdata.internal.convertRObject(elements{k}, options);
    end
end
end

function tf = isNamedList(names, numElements)
tf = numel(names) == numElements && all(strlength(names) > 0) && ~any(ismissing(names));
end

function value = convertFactor(robj)
levelsObject = getAttributeValue(robj, "levels");
if isempty(levelsObject) || levelsObject.Type ~= "STRSXP"
    error("rdata:UnsupportedRClass", "R factor object does not have a supported levels attribute.")
end

levels = levelsObject.Value(:).';
codes = double(robj.Value(:));
labels = strings(size(codes));
valid = (~robj.Missing) & codes >= 1 & codes <= numel(levels);
labels(valid) = levels(codes(valid));
labels(~valid) = missing;
isOrdered = any(robj.RClass == "ordered");
value = categorical(labels, levels, Ordinal=isOrdered);
value = applyDimensions(value, robj);
end

function value = convertLogical(robj)
value = robj.Value ~= 0;
if ~isempty(robj.Missing)
    value(robj.Missing) = false;
end
end

function value = convertInteger(robj, options)
switch options.IntegerType
    case "double"
        value = double(robj.Value);
        if ~isempty(robj.Missing)
            value(robj.Missing) = NaN;
        end
    case "int32"
        value = robj.Value;
    otherwise
        error("rdata:InvalidOption", "Unsupported IntegerType '%s'.", options.IntegerType)
end
end

function value = convertString(robj, options)
value = robj.Value;
switch options.TextType
    case "string"
        return
    case "cellstr"
        value(ismissing(value)) = "";
        value = cellstr(value);
    otherwise
        error("rdata:InvalidOption", "Unsupported TextType '%s'.", options.TextType)
end
end

function value = applyDimensions(value, robj)
if ~isempty(robj.Dimensions)
    value = reshape(value, robj.Dimensions);
end
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

function value = convertUnsupported(robj, options)
switch options.PreserveUnsupported
    case "error"
        if robj.Type == "ALTREP_SXP"
            error("rdata:UnsupportedAltrep", ...
                "R ALTREP object payload is not supported by this reader.")
        end
        error("rdata:UnsupportedRType", ...
            "R object type %s is not supported by this reader.", robj.Type)
    case "opaque"
        value = struct( ...
            Unsupported=true, ...
            RType=robj.Type, ...
            RClass=robj.RClass, ...
            Metadata=rdata.internal.makeMetadata(robj, struct(), ""));
    case "raw"
        value = robj;
    otherwise
        error("rdata:InvalidOption", ...
            "Unsupported PreserveUnsupported value '%s'.", options.PreserveUnsupported)
end
end
