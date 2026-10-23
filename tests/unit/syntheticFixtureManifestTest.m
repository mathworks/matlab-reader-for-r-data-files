classdef syntheticFixtureManifestTest < matlab.unittest.TestCase
    %syntheticFixtureManifestTest Tests synthetic fixture freshness metadata.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures(currentProject().RootFolder);
        end
    end

    methods (Test, TestTags = {'Unit'})
        function testRequiredFixturesExist(testCase)
            requiredFiles = absoluteFixturePaths(testCase.FixtureRoot, requiredFixtureRelativePaths());

            testCase.verifyTrue(all(isfile(requiredFiles)))
        end

        function testManifestPathsExist(testCase)
            manifestFiles = absoluteFixturePaths(testCase.FixtureRoot, manifestFixtureRelativePaths(testCase));

            testCase.verifyGreaterThan(numel(manifestFiles), 0)
            testCase.verifyTrue(all(isfile(manifestFiles)))
        end

        function testManifestIncludesRequiredFixtures(testCase)
            missingPaths = setdiff( ...
                requiredDataFixtureRelativePaths(), ...
                manifestFixtureRelativePaths(testCase));

            testCase.verifyEmpty(missingPaths)
        end

    end
end

function relativePaths = manifestFixtureRelativePaths(testCase)
manifestFile = fullfile(testCase.FixtureRoot, "manifest.json");
manifest = jsondecode(fileread(manifestFile));
entries = manifest.fixtures;
relativePaths = strings(numel(entries), 1);
for k = 1:numel(entries)
    relativePaths(k) = string(entries(k).path);
end
relativePaths = sort(relativePaths);
end

function absolutePaths = absoluteFixturePaths(fixtureRoot, relativePaths)
absolutePaths = fullfile(fixtureRoot, replace(relativePaths, "/", filesep));
end

function relativePaths = requiredFixtureRelativePaths()
relativePaths = [
    "manifest.json"
    requiredDataFixtureRelativePaths()
];
end
function relativePaths = requiredDataFixtureRelativePaths()
relativePaths = [
    "rds/altrep_sequence.rds"
    "rds/array_3d.rds"
    "rds/base_environment.rds"
    "rds/bytes_vector.rds"
    "rds/character_empty_vector.rds"
    "rds/character_vector.rds"
    "rds/complex_vector.rds"
    "rds/date_vector.rds"
    "rds/difftime_seconds.rds"
    "rds/empty_environment.rds"
    "rds/formula_object.rds"
    "rds/function_object.rds"
    "rds/global_environment.rds"
    "rds/integer_vector.rds"
    "rds/integer_vector_ascii.rds"
    "rds/integer_vector_bzip2.rds"
    "rds/integer_vector_gzip.rds"
    "rds/integer_vector_v2.rds"
    "rds/integer_vector_xz.rds"
    "rds/invalid_name_data_frame.rds"
    "rds/invalid_name_list.rds"
    "rds/latin1_vector.rds"
    "rds/list_with_data_frame.rds"
    "rds/list_with_function.rds"
    "rds/logical_vector.rds"
    "rds/named_integer.rds"
    "rds/named_list.rds"
    "rds/nested_list.rds"
    "rds/numeric_matrix.rds"
    "rds/ordered_factor.rds"
    "rds/posixct_london.rds"
    "rds/posixct_utc.rds"
    "rds/posixlt_object.rds"
    "rds/raw_vector.rds"
    "rds/real_vector.rds"
    "rds/simple_data_frame.rds"
    "rds/simple_factor.rds"
    "rds/tibble_like.rds"
    "rds/unnamed_list.rds"
    "rdata/primitive_workspace.rda"
    "rdata/primitive_workspace_gzip.rda"
    "rdata/primitive_workspace_v2.rda"
    "rdata/single_table_workspace.rda"
];
end
