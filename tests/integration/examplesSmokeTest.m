classdef examplesSmokeTest < matlab.unittest.TestCase
    %examplesSmokeTest Smoke tests for public documentation examples.

% Copyright 2026 The MathWorks, Inc.

    properties
        ProjectRoot (1,1) string
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.ProjectRoot = currentProject().RootFolder;            
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures(testCase.ProjectRoot);
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function testReadmeGettingStarted(testCase)
            rdsFile = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");
            T = rdata2table(rdsFile);

            rdataFile = fullfile(testCase.FixtureRoot, ...
                "rdata", "single_table_workspace.rda");
            TFromWorkspace = rdata2table(rdataFile);

            x = readrds(fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds"));
            S = readrdata(fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda"));
            info = rdatainfo(rdataFile);

            testCase.verifySize(T, [3 5])
            testCase.verifySize(TFromWorkspace, [3 5])
            testCase.verifyEqual(x([1 2 3 5]), [-10; 0; 25; 100])
            testCase.verifyClass(S, "dictionary")
            testCase.verifyEqual(info.FileType, "RData")
            testCase.verifyEqual(height(info.Objects), 1)
        end

        function testGettingStarted(testCase)
            guide = fullfile(testCase.ProjectRoot, "tbx", "doc", ...
                "mfiles", "GettingStarted.m"); %#ok<NASGU> Used by captured execution below.
            evalc("run(guide)");
        end
    end
end
