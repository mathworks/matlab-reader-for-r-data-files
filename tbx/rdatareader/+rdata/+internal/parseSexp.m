function robj = parseSexp(reader, context)
%PARSESEXP Parse one serialized R object into an internal representation.

% Copyright 2026 The MathWorks, Inc.

import rdata.internal.RType

limits = context.Options.Limits;
if context.Depth > limits.MaxRecursionDepth
    error("rdata:RecursionLimitExceeded", ...
        "R serialization nesting exceeds the configured recursion limit.")
end

infoWord = reader.readUInt32();
info = decodeInfoWord(infoWord);
context.State.incrementObjectCount(limits);
childContext = context;
childContext.Depth = context.Depth + 1;

switch info.Type
    case {RType.NILSXP, RType.NILVALUE_SXP}
        robj = newRObject("NILSXP", [], info, emptyAttributes());
    case {RType.EMPTYENV_SXP, RType.BASEENV_SXP, ...
            RType.GLOBALENV_SXP, RType.MISSINGARG_SXP}
        robj = newRObject(RType(info.Type), [], info, emptyAttributes());
    case RType.SYMSXP
        robj = parseSymbol(reader, info, childContext);
    case RType.LISTSXP
        robj = parsePairlist(reader, info, childContext, "LISTSXP");
    case {RType.LANGSXP, RType.DOTSXP}
        robj = parsePairlist(reader, info, childContext, RType(info.Type));
    case RType.CHARSXP
        robj = parseCharSexp(reader, info, context);
    case {RType.LGLSXP, RType.INTSXP}
        robj = parseIntegerVector(reader, info, childContext);
    case RType.REALSXP
        robj = parseRealVector(reader, info, childContext);
    case RType.CPLXSXP
        robj = parseComplexVector(reader, info, childContext);
    case RType.STRSXP
        robj = parseStringVector(reader, info, childContext);
    case RType.VECSXP
        robj = parseVectorList(reader, info, childContext);
    case RType.RAWSXP
        robj = parseRawVector(reader, info, childContext);
    case RType.ALTREP_SXP
        robj = parseAltrep(reader, info, childContext);
    case RType.REFSXP
        robj = parseReference(reader, info, context);
    case RType.CLOSXP
        robj = parseClosure(reader, info, childContext);
    case RType.EXPRSXP
        robj = parseExpressionVector(reader, info, childContext);
    case {RType.ENVSXP, RType.PROMSXP, ...
            RType.SPECIALSXP, RType.BUILTINSXP, ...
            RType.BCODESXP, RType.EXTPTRSXP, ...
            RType.WEAKREFSXP, RType.OBJSXP}
        robj = parseKnownUnsupported(reader, info, childContext);
    otherwise
        robj = makeUnsupportedObject("SEXPTYPE_" + info.Type, info, emptyAttributes(), []);
end
end

function robj = parseSymbol(reader, info, context)
printName = rdata.internal.parseSexp(reader, context);
if printName.Type == "CHARSXP"
    value = printName.Value;
else
    value = "";
end
robj = newRObject("SYMSXP", value, info, emptyAttributes());
context.State.addReference(robj);
end

function robj = parseReference(reader, info, context)
index = double(bitshift(info.Raw, -8));
if index == 0
    index = double(reader.readInt32());
end
robj = context.State.getReference(index);
robj.IsReference = true;
robj.ReferenceIndex = index;
end

function robj = parseAltrep(reader, info, context)
classInfo = rdata.internal.parseSexp(reader, context);
state = rdata.internal.parseSexp(reader, context);
attributesObject = rdata.internal.parseSexp(reader, context);
classNames = collectPairlistStrings(classInfo);

if any(classNames == "compact_intseq") && state.Type == "REALSXP" && numel(state.Value) >= 3
    attributes = attributesFromObject(attributesObject);
    robj = materializeCompactIntseq(state, info, attributes, context.Options.Limits);
else
    robj = makeUnsupportedObject("ALTREP_SXP", info, emptyAttributes(), ...
        struct(ClassInfo=classInfo, State=state, AttributesObject=attributesObject));
end
end

function classNames = collectPairlistStrings(node)
numStrings = countPairlistStrings(node);
classNames = strings(numStrings, 1);
index = 1;
while node.Type == "LISTSXP"
    car = node.Value.Car;
    if car.Type == "SYMSXP" || car.Type == "CHARSXP"
        classNames(index) = string(car.Value);
        index = index + 1;
    elseif car.Type == "STRSXP"
        values = car.Value(:);
        classNames(index:index + numel(values) - 1) = values;
        index = index + numel(values);
    end
    node = node.Value.Cdr;
end
end

function numStrings = countPairlistStrings(node)
numStrings = 0;
while node.Type == "LISTSXP"
    car = node.Value.Car;
    if car.Type == "SYMSXP" || car.Type == "CHARSXP"
        numStrings = numStrings + 1;
    elseif car.Type == "STRSXP"
        numStrings = numStrings + numel(car.Value);
    end
    node = node.Value.Cdr;
end
end

function attributes = attributesFromObject(attributesObject)
if attributesObject.Type == "NILSXP"
    attributes = emptyAttributes();
else
    attributes = rdata.internal.attributesToEntries(attributesObject);
end
end

function robj = materializeCompactIntseq(state, info, attributes, limits)
sequenceLength = state.Value(1);
firstValue = state.Value(2);
stepValue = state.Value(3);
if sequenceLength < 0 || sequenceLength > limits.MaxVectorElements || fix(sequenceLength) ~= sequenceLength
    error("rdata:VectorTooLarge", "R compact integer sequence length is outside supported limits.")
end

value = firstValue + (0:sequenceLength - 1).'*stepValue;
if all(isfinite(value)) && all(fix(value) == value) && ...
        all(value >= double(intmin("int32"))) && all(value <= double(intmax("int32")))
    robj = newRObject("INTSXP", int32(value), info, attributes);
else
    robj = newRObject("REALSXP", value, info, attributes);
end
robj.Missing = false(size(value));
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseClosure(reader, info, context)
environment = rdata.internal.parseSexp(reader, context);
formals = rdata.internal.parseSexp(reader, context);
body = rdata.internal.parseSexp(reader, context);
attributes = parseAttributes(reader, info, context);
value = struct(Environment=environment, Formals=formals, Body=body);
robj = makeUnsupportedObject("CLOSXP", info, attributes, value);
end

function [attributes, value, lengthValue] = parseVector(reader, info, context)
lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
value = cell(lengthValue, 1);
for k = 1:lengthValue
    value{k} = rdata.internal.parseSexp(reader, context);
end
attributes = parseAttributes(reader, info, context);
end

function robj = parseExpressionVector(reader, info, context)
[attributes, value] = parseVector(reader, info, context);
robj = makeUnsupportedObject("EXPRSXP", info, attributes, value);
end

function robj = parseVectorList(reader, info, context)
[attributes, value, lengthValue] = parseVector(reader, info, context);
robj = newRObject("VECSXP", value, info, attributes);
robj.Missing = false(lengthValue, 1);
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseKnownUnsupported(reader, info, context)

attributes = parseAttributes(reader, info, context);
robj = makeUnsupportedObject(rdata.internal.RType(info.Type), info, attributes, []);

end

function robj = parsePairlist(reader, info, context, type)
attributes = parseAttributes(reader, info, context);
if info.HasTag
    tag = rdata.internal.parseSexp(reader, context);
else
    tag = newRObject("NILSXP", [], info, emptyAttributes());
end

car = rdata.internal.parseSexp(reader, context);
cdr = rdata.internal.parseSexp(reader, context);
value = struct(Tag=tag, Car=car, Cdr=cdr);
robj = newRObject(type, value, info, attributes);
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseCharSexp(reader, info, context)
limits = context.Options.Limits;
lengthValue = double(reader.readInt32());
if lengthValue == -1
    % CHARSXP length -1 is R's NA_STRING sentinel, not an empty string.
    value = string(missing);
    isMissing = true;
    encoding = "";
    bytes = uint8.empty(1, 0);
elseif lengthValue < -1
    error("rdata:InvalidLength", "R CHARSXP contains an invalid negative length.")
else
    if lengthValue > limits.MaxStringBytes
        error("rdata:StringTooLarge", ...
            "R character element length %g exceeds the configured importer limit.", lengthValue)
    end
    bytes = reader.readBytes(lengthValue);
    [value, encoding] = rdata.internal.decodeChar(bytes, info.Gp, context.FileInfo.NativeEncoding);
    isMissing = false;
end

robj = newRObject("CHARSXP", value, info, emptyAttributes());
robj.Missing = isMissing;
robj.Encoding = encoding;
robj.RawBytes = {bytes};
end

function robj = parseIntegerVector(reader, info, context)
import rdata.internal.RType

lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
value = reader.readInt32Array(lengthValue);
attributes = parseAttributes(reader, info, context);
robj = newRObject(RType(info.Type), value, info, attributes);
robj.Missing = value == intmin("int32");
robj = rdata.internal.applyKnownAttributes(robj);

end

function robj = parseRealVector(reader, info, context)
lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
[value, rawBytes] = reader.readDoubleArray(lengthValue);
missing = isRNaReal(rawBytes, reader.Format, reader.HostEndian);
attributes = parseAttributes(reader, info, context);
robj = newRObject("REALSXP", value, info, attributes);
robj.Missing = missing;
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseComplexVector(reader, info, context)
lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
[parts, rawBytes] = reader.readDoubleArray(2*lengthValue);
parts = reshape(parts, 2, []);
missingParts = reshape(isRNaReal(rawBytes, reader.Format, reader.HostEndian), 2, []);
missing = any(missingParts, 1).';
attributes = parseAttributes(reader, info, context);
robj = newRObject("CPLXSXP", complex(parts(1, :).', parts(2, :).'), info, attributes);
robj.Missing = missing;
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseStringVector(reader, info, context)
lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
value = strings(lengthValue, 1);
missing = false(lengthValue, 1);
encoding = strings(lengthValue, 1);
rawBytes = cell(lengthValue, 1);
for k = 1:lengthValue
    charObject = rdata.internal.parseSexp(reader, context);
    if charObject.Type ~= "CHARSXP"
        error("rdata:InvalidSexpType", ...
            "R STRSXP element is not a CHARSXP at position %d.", k)
    end
    value(k) = charObject.Value;
    missing(k) = charObject.Missing;
    encoding(k) = charObject.Encoding;
    rawBytes{k} = charObject.RawBytes{1};
end
attributes = parseAttributes(reader, info, context);
robj = newRObject("STRSXP", value, info, attributes);
robj.Missing = missing;
robj.Encoding = encoding;
robj.RawBytes = rawBytes;
robj = rdata.internal.applyKnownAttributes(robj);
end

function robj = parseRawVector(reader, info, context)
lengthValue = rdata.internal.readRLength(reader, context.Options.Limits);
value = reader.readBytes(lengthValue).';
attributes = parseAttributes(reader, info, context);
robj = newRObject("RAWSXP", value, info, attributes);
robj.Missing = false(size(value));
robj = rdata.internal.applyKnownAttributes(robj);
end

function attributes = parseAttributes(reader, info, context)
if info.HasAttributes
    attributesObject = rdata.internal.parseSexp(reader, context);
    attributes = rdata.internal.attributesToEntries(attributesObject);
else
    attributes = emptyAttributes();
end
end

function tf = isRNaReal(rawBytes, format, hostEndian)
naBytes = uint8([127 240 0 0 0 0 7 162]);
if format == "native" && hostEndian == "L"
    naBytes = fliplr(naBytes);
end
tf = all(rawBytes == naBytes(:), 1).';
end

function robj = newRObject(type, value, info, attributes)
robj = struct( ...
    Type=string(type), ...
    Value={value}, ...
    Attributes={attributes}, ...
    RClass=strings(0, 1), ...
    Names=strings(0, 1), ...
    Dimensions=[], ...
    Encoding=strings(0, 1), ...
    RawBytes={cell(0, 1)}, ...
    Missing=[], ...
    Info=info, ...
    IsObject=info.IsObject, ...
    IsReference=false, ...
    ReferenceIndex=[]);
end

function attributes = emptyAttributes()
attributes = struct(Name=cell(0, 1), Value=cell(0, 1));
end

function robj = makeUnsupportedObject(type, info, attributes, value)
robj = newRObject(type, value, info, attributes);
robj = rdata.internal.applyKnownAttributes(robj);
end

function info = decodeInfoWord(infoWord)
%DECODEINFOWORD Decode the serialized R SEXP info word.
%   Low 8 bits hold the SEXPTYPE. The next bits mark object, attributes,
%   and tag presence. Bits 12-27 carry gp flags such as CHARSXP encoding.

% Copyright 2026 The MathWorks, Inc.

infoWord = uint32(infoWord);
info = struct( ...
    Raw=infoWord, ...
    Type=bitand(infoWord, uint32(255)), ...
    IsObject=bitand(infoWord, uint32(256)) ~= 0, ...
    HasAttributes=bitand(infoWord, uint32(512)) ~= 0, ...
    HasTag=bitand(infoWord, uint32(1024)) ~= 0, ...
    Gp=bitand(bitshift(infoWord, -12), uint32(65535)));
end
