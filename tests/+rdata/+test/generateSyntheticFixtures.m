function fixtureRoot = generateSyntheticFixtures(projectRoot, options)
%GENERATESYNTHETICFIXTURES Generate deterministic R fixtures for tests.

% Copyright 2026 The MathWorks, Inc.

arguments
    projectRoot (1,1) string
    options.Force (1,1) logical = false
    options.OutputFolder (1,1) string = ""
end

fixtureRoot = options.OutputFolder;
if strlength(fixtureRoot) == 0
    fixtureRoot = fullfile(projectRoot, "tests", "testdata", "synthetic");
end
manifestFile = fullfile(fixtureRoot, "manifest.json");
if ~options.Force && isfile(manifestFile) && requiredFixturesExist(fixtureRoot)
    return
end

rscript = rdata.test.findRscript();
if strlength(rscript) == 0
    error("rdata:MissingRscript", "Rscript was not found. Set RDATA_RSCRIPT to the Rscript executable.")
end

scriptFile = fullfile(projectRoot, "tests", "tools", "generateSyntheticFixtures.R");
command = rdata.test.quoteCommandArgument(rscript) + " " + ...
    rdata.test.quoteCommandArgument(scriptFile) + " " + ...
    rdata.test.quoteCommandArgument(fixtureRoot);
[status, output] = system(command);
if status ~= 0
    error("rdata:FixtureGenerationFailed", ...
        "R fixture generation failed with status %d: %s", status, output)
end
end

function tf = requiredFixturesExist(fixtureRoot)
requiredFiles = [
    fullfile(fixtureRoot, "manifest.json")
    fullfile(fixtureRoot, "rds", "duplicate_columns.rds")
    fullfile(fixtureRoot, "rds", "duplicate_list.rds")
    fullfile(fixtureRoot, "rds", "reserved_column.rds")
    fullfile(fixtureRoot, "rds", "empty_column.rds")
    fullfile(fixtureRoot, "rds", "timetable_metadata.rds")
    fullfile(fixtureRoot, "rds", "timetable_custom_time.rds")
    fullfile(fixtureRoot, "rds", "altrep_sequence.rds")
    fullfile(fixtureRoot, "rds", "array_3d.rds")
    fullfile(fixtureRoot, "rds", "base_environment.rds")
    fullfile(fixtureRoot, "rds", "bytes_vector.rds")
    fullfile(fixtureRoot, "rds", "character_empty_vector.rds")
    fullfile(fixtureRoot, "rds", "character_vector.rds")
    fullfile(fixtureRoot, "rds", "complex_vector.rds")
    fullfile(fixtureRoot, "rds", "date_vector.rds")
    fullfile(fixtureRoot, "rds", "difftime_seconds.rds")
    fullfile(fixtureRoot, "rds", "empty_environment.rds")
    fullfile(fixtureRoot, "rds", "formula_object.rds")
    fullfile(fixtureRoot, "rds", "function_object.rds")
    fullfile(fixtureRoot, "rds", "global_environment.rds")
    fullfile(fixtureRoot, "rds", "integer_vector.rds")
    fullfile(fixtureRoot, "rds", "integer_vector_ascii.rds")
    fullfile(fixtureRoot, "rds", "integer_vector_bzip2.rds")
    fullfile(fixtureRoot, "rds", "integer_vector_gzip.rds")
    fullfile(fixtureRoot, "rds", "integer_vector_v2.rds")
    fullfile(fixtureRoot, "rds", "integer_vector_xz.rds")
    fullfile(fixtureRoot, "rds", "implicit_columns_data_frame.rds")
    fullfile(fixtureRoot, "rds", "invalid_name_data_frame.rds")
    fullfile(fixtureRoot, "rds", "invalid_name_list.rds")
    fullfile(fixtureRoot, "rds", "latin1_vector.rds")
    fullfile(fixtureRoot, "rds", "list_with_data_frame.rds")
    fullfile(fixtureRoot, "rds", "list_with_function.rds")
    fullfile(fixtureRoot, "rds", "logical_vector.rds")
    fullfile(fixtureRoot, "rds", "named_integer.rds")
    fullfile(fixtureRoot, "rds", "named_list.rds")
    fullfile(fixtureRoot, "rds", "nested_list.rds")
    fullfile(fixtureRoot, "rds", "numeric_matrix.rds")
    fullfile(fixtureRoot, "rds", "ordered_factor.rds")
    fullfile(fixtureRoot, "rds", "posixct_london.rds")
    fullfile(fixtureRoot, "rds", "posixct_utc.rds")
    fullfile(fixtureRoot, "rds", "posixlt_object.rds")
    fullfile(fixtureRoot, "rds", "raw_vector.rds")
    fullfile(fixtureRoot, "rds", "real_vector.rds")
    fullfile(fixtureRoot, "rds", "simple_data_frame.rds")
    fullfile(fixtureRoot, "rds", "simple_factor.rds")
    fullfile(fixtureRoot, "rds", "tibble_like.rds")
    fullfile(fixtureRoot, "rds", "unnamed_list.rds")
    fullfile(fixtureRoot, "rdata", "primitive_workspace.rda")
    fullfile(fixtureRoot, "rdata", "primitive_workspace_gzip.rda")
    fullfile(fixtureRoot, "rdata", "primitive_workspace_v2.rda")
    fullfile(fixtureRoot, "rdata", "single_table_workspace.rda")
];
tf = all(isfile(requiredFiles));
end
