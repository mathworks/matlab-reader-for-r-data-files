classdef rOracleComparisonTest < matlab.unittest.TestCase
    %rOracleComparisonTest Compares importer summaries with live R summaries.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.assumeTrue(strlength(rdata.test.findRscript()) > 0, "Rscript is not available.")
            testCase.FixtureRoot = string(tempname);
            mkdir(testCase.FixtureRoot)
            testCase.addTeardown(@() rmdir(testCase.FixtureRoot, "s"));
            rdata.test.generateSyntheticFixtures(currentProject().RootFolder, ...
                Force=true, OutputFolder=testCase.FixtureRoot);
        end
    end

    methods (Test, TestTags = {'ROracle'})
        function testIntegerVectorOracle(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            oracle = runOracle(testCase, fixture);
            [~, metadata] = readrds(fixture);

            testCase.verifyEqual(string(oracle.objects.typeof), "integer")
            testCase.verifyEqual(oracle.objects.length, numel(metadata.Missing))
            testCase.verifyEqual(oracle.objects.missingCount, sum(metadata.Missing))
        end

        function testDataFrameOracle(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            oracle = runOracle(testCase, fixture);
            value = readrds(fixture);

            testCase.verifyEqual(string(oracle.objects.typeof), "list")
            testCase.verifyEqual(string(oracle.objects.class(end)), "data.frame")
            testCase.verifyEqual(oracle.objects.dim(:).', [height(value) width(value)])
        end

        function testWorkspaceOracle(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            oracle = runOracle(testCase, fixture);
            workspace = readrdata(fixture);

            testCase.verifyEqual(numel(oracle.objects), numel(workspace.keys))
        end

        function testGeneratedCharacterEncodings(testCase)
            utf8Fixture = fullfile(testCase.FixtureRoot, "rds", "character_vector.rds");
            latin1Fixture = fullfile(testCase.FixtureRoot, "rds", "latin1_vector.rds");
            expected = string(native2unicode(uint8([195 169]), "UTF-8"));

            [utf8Value, utf8Metadata] = readrds(utf8Fixture);
            [latin1Value, latin1Metadata] = readrds(latin1Fixture);

            testCase.verifyEqual(utf8Value(1), "abc")
            testCase.verifyTrue(ismissing(utf8Value(2)))
            testCase.verifyEqual(utf8Value(3), expected)
            testCase.verifyEqual(utf8Metadata.Missing, [false; true; false])
            testCase.verifyEqual(latin1Value, expected)
            testCase.verifyEqual(latin1Metadata.Encoding, "latin1")
        end
    end
end

function oracle = runOracle(testCase, fixture)
rscript = rdata.test.findRscript();
outputFile = string(tempname) + ".json";
testCase.addTeardown(@() deleteIfPresent(outputFile));
scriptFile = fullfile("..", "tools", "summarizeRObject.R");
command = rdata.test.quoteCommandArgument(rscript) + " " + ...
    rdata.test.quoteCommandArgument(scriptFile) + " " + ...
    rdata.test.quoteCommandArgument(fixture) + " " + ...
    rdata.test.quoteCommandArgument(outputFile);
[status, output] = system(command);
testCase.assertEqual(status, 0, output)
oracle = jsondecode(fileread(outputFile));
end

function deleteIfPresent(filename)
if isfile(filename)
    delete(filename)
end
end
