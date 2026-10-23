function entries = attributesToEntries(attributesObject)
%ATTRIBUTESTOENTRIES Convert an R pairlist of attributes to name/value entries.

% Copyright 2026 The MathWorks, Inc.

numEntries = countPairlistNodes(attributesObject);
entries = struct(Name=cell(numEntries, 1), Value=cell(numEntries, 1));
node = attributesObject;
index = 1;

while node.Type == "LISTSXP"
    tag = node.Value.Tag;
    if tag.Type == "SYMSXP"
        name = string(tag.Value);
    else
        name = "";
    end

    entries(index).Name = name;
    entries(index).Value = node.Value.Car;
    index = index + 1;
    node = node.Value.Cdr;
end

if node.Type ~= "NILSXP"
    error("rdata:InvalidSexpType", "R attribute list is not terminated by NULL.")
end
end

function numNodes = countPairlistNodes(node)
numNodes = 0;
while node.Type == "LISTSXP"
    numNodes = numNodes + 1;
    node = node.Value.Cdr;
end
end
