function parsed = parseRFile(filename, options, expectedFileType)
%PARSERFILE Parse one R serialized data file using content-based dispatch.

% Copyright 2026 The MathWorks, Inc.

arguments
    filename (1,1) string {mustBeFile}
    options (1,1) struct
    expectedFileType (1,1) string ...
        {mustBeMember(expectedFileType, ["", "RDS", "RData"])} = ""
end

limits = options.Limits;
envelope = rdata.internal.parseRFileEnvelope(filename, limits);
validateExpectedFileType(envelope.FileInfo.FileType, expectedFileType, filename)

stream = rdata.internal.parseSerializationStream( ...
    envelope.PayloadBytes, ...
    envelope.FileInfo, ...
    options);

if envelope.FileInfo.FileType == "RData"
    parsed = struct( ...
        FileInfo=envelope.FileInfo, ...
        Objects=extractWorkspaceObjects(stream.Object));
else
    parsed = stream;
end
end

function validateExpectedFileType(actualFileType, expectedFileType, filename)
if expectedFileType == "" || actualFileType == expectedFileType
    return
end

if expectedFileType == "RDS"
    error("rdata:InvalidHeader", ...
        "Expected an .rds serialization stream, but %s contains an R workspace save header.", filename)
end

error("rdata:InvalidHeader", ...
    "Expected an R workspace save file, but %s contains a single-object .rds stream.", filename)
end

function objects = extractWorkspaceObjects(workspaceObject)
if workspaceObject.Type == "LISTSXP"
    objects = extractPairlistWorkspace(workspaceObject);
elseif workspaceObject.Type == "VECSXP"
    error("rdata:UnsupportedRType", ...
        "Named vector-list R workspaces are not supported by this reader.")
else
    error("rdata:InvalidSexpType", ...
        "The top-level R workspace object is not a tagged pairlist.")
end
end

function objects = extractPairlistWorkspace(node)
numObjects = countPairlistNodes(node);
objects = struct(Name=cell(numObjects, 1), Object=cell(numObjects, 1));
index = 1;

while node.Type == "LISTSXP"
    tag = node.Value.Tag;
    if tag.Type ~= "SYMSXP" || strlength(tag.Value) == 0
        error("rdata:InvalidHeader", "R workspace entry is missing a symbol tag.")
    end

    objects(index).Name = string(tag.Value);
    objects(index).Object = node.Value.Car;
    index = index + 1;
    node = node.Value.Cdr;
end

if node.Type ~= "NILSXP"
    error("rdata:InvalidSexpType", "R workspace pairlist is not terminated by NULL.")
end
end

function numNodes = countPairlistNodes(node)
numNodes = 0;
while node.Type == "LISTSXP"
    numNodes = numNodes + 1;
    node = node.Value.Cdr;
end
end
