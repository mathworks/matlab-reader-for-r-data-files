classdef apiValidationTest < matlab.unittest.TestCase
    %apiValidationTest Tests public API validation behavior.

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
        function testReadrdsMissingFile(testCase)
            missingFile = fullfile(testCase.FixtureRoot, "missing.rds");

            testCase.verifyError(@() readrds(missingFile), "MATLAB:validators:mustBeFile")
        end

        function testReadrdataMissingFile(testCase)
            missingFile = fullfile(testCase.FixtureRoot, "missing.rda");

            testCase.verifyError(@() readrdata(missingFile), "MATLAB:validators:mustBeFile")
        end

        function testRdatainfoMissingFile(testCase)
            missingFile = fullfile(testCase.FixtureRoot, "missing.rds");

            testCase.verifyError(@() rdatainfo(missingFile), "MATLAB:validators:mustBeFile")
        end

        function testReadrdsInvalidOption(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            testCase.verifyError(@() readrds(fixture, TextType="bad"), "MATLAB:validators:mustBeMember")
        end

    end
end
