function value = convertNamedObjects(objects, names, options)
%CONVERTNAMEDOBJECTS Convert named R objects to a dictionary.

% Copyright 2026 The MathWorks, Inc.

arguments
    objects (:,1) cell
    names   (:,1) string
    options (1,1) struct
end

if numel(objects) ~= numel(names)
    error("rdata:InvalidObjectNames", ...
        "The number of object names must equal the number of objects.")
end

if numel(unique(names)) ~= numel(names)
    error("rdata:DuplicateNames", ...
        "Duplicate R names cannot be represented without losing values. " + ...
        "Give each object a unique name in R before saving.")
end

values = cell(numel(objects), 1);
for k = 1:numel(objects)
    values{k} = rdata.internal.convertRObject(objects{k}, options);
end

value = dictionary(names, values);
end
