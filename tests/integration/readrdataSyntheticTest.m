classdef readrdataSyntheticTest < matlab.unittest.TestCase
    %readrdataSyntheticTest Tests public .RData workspace imports.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures(currentProject().RootFolder);
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function testPrimitiveWorkspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            [workspace, metadata] = readrdata(fixture);

            testCase.verifyEqual(workspace{"xInt"}(1:2), [11; 22])
            testCase.verifyTrue(isnan(workspace{"xInt"}(3)))
            testCase.verifyEqual(workspace{"xText"}(1), "aa")
            testCase.verifyTrue(ismissing(workspace{"xText"}(2)))
            testCase.verifyEqual(workspace{"xReal"}(1), 1.25)
            testCase.verifyEqual(metadata.FileType, "RData")
        end

        function testGzipWorkspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rdata", "primitive_workspace_gzip.rda");

            [workspace, metadata] = readrdata(fixture);

            testCase.verifyEqual(workspace{"xInt"}(1:2), [11; 22])
            testCase.verifyEqual(workspace{"xText"}(3), "bb")
            testCase.verifyEqual(metadata.Compression, "gzip")
        end

        function testRdatainfoWorkspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            info = rdatainfo(fixture);

            testCase.verifyEqual(info.FileType, "RData")
            testCase.verifyEqual(info.SerializationFormat, "XDR")
            testCase.verifyEqual(height(info.Objects), 4)
        end

        function testVersion2Workspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rdata", "primitive_workspace_v2.rda");

            [workspace, metadata] = readrdata(fixture);

            testCase.verifyEqual(workspace{"xInt"}(1:2), [11; 22])
            testCase.verifyTrue(isnan(workspace{"xInt"}(3)))
            testCase.verifyEqual(metadata.SerializationVersion, 2)
        end
    end
end
