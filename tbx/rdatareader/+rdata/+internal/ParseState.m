classdef ParseState < handle
    %PARSESTATE Mutable parser state shared across recursive SEXP parsing.

% Copyright 2026 The MathWorks, Inc.

    properties
        References cell = cell(0, 1)
        ObjectCount (1,1) double = 0
    end

    methods
        function incrementObjectCount(state, limits)
            state.ObjectCount = state.ObjectCount + 1;
            if state.ObjectCount > limits.MaxObjectCount
                error("rdata:ObjectLimitExceeded", ...
                    "R serialization object count exceeds the configured importer limit.")
            end
        end

        function index = addReference(state, robj)
            state.References{end + 1, 1} = robj;
            index = numel(state.References);
        end

        function robj = getReference(state, index)
            if index < 1 || index > numel(state.References)
                error("rdata:InvalidReference", ...
                    "R serialization reference index %d is outside the parsed reference table.", index)
            end
            robj = state.References{index};
        end
    end
end
