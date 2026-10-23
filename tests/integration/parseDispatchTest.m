classdef parseDispatchTest < matlab.unittest.TestCase
    %parseDispatchTest Tests single-pass content-based public dispatch.

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures( currentProject().RootFolder );
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function testRdatainfoParsesOnce(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            profileInfo = profileCall(testCase, @() rdatainfo(fixture));

            testCase.verifyEqual(profileCallCount(profileInfo, "parseRFileEnvelope"), 1)
            testCase.verifyEqual(profileCallCount(profileInfo, "parseSerializationStream"), 1)
        end

        function testRdata2tableParsesOnce(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            profileInfo = profileCall(testCase, @() rdata2table(fixture));

            testCase.verifyEqual(profileCallCount(profileInfo, "parseRFileEnvelope"), 1)
            testCase.verifyEqual(profileCallCount(profileInfo, "parseSerializationStream"), 1)
        end

        function testRdatainfoRds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            info = rdatainfo(fixture);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.Objects.RType, "INTSXP")
        end

        function testRdatainfoRData(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            info = rdatainfo(fixture);

            testCase.verifyEqual(info.FileType, "RData")
            testCase.verifyEqual(height(info.Objects), 4)
        end

        function testRdatainfoGzip(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_gzip.rds");

            info = rdatainfo(fixture);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.Compression, "gzip")
        end

        function testRdatainfoMisleadingExtension(testCase)
            source = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            fixture = copyWithExtension(testCase, source, ".RData");

            info = rdatainfo(fixture);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.Objects.RType, "INTSXP")
        end

        function testRdata2tableGzipRds(testCase)
            source = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");
            fixture = gzipFixture(testCase, source);

            value = rdata2table(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifySize(value, [3 5])
        end

        function testRdata2tableGzipRData(testCase)
            source = fullfile(testCase.FixtureRoot, ...
                "rdata", "single_table_workspace.rda");
            fixture = gzipFixture(testCase, source);

            value = rdata2table(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifySize(value, [3 5])
        end

        function testRdata2tableRdsWithRDataExtension(testCase)
            source = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");
            fixture = copyWithExtension(testCase, source, ".RData");

            value = rdata2table(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifyEqual(value.id(1:2), [10; 20])
        end

        function testRdata2tableRDataWithRdsExtension(testCase)
            source = fullfile(testCase.FixtureRoot, ...
                "rdata", "single_table_workspace.rda");
            fixture = copyWithExtension(testCase, source, ".rds");

            value = rdata2table(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifyEqual(value.id(1:2), [10; 20])
        end

        function testRdata2tableRdsMetadataMatchesReader(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            expected = readrds(fixture);
            actual = rdata2table(fixture);

            testCase.verifyEqual(actual.Properties.UserData, expected.Properties.UserData)
            testCase.verifyEqual( ...
                actual.Properties.CustomProperties.RDataVariableMetadata, ...
                expected.Properties.CustomProperties.RDataVariableMetadata)
        end

        function testRdata2tableRDataMetadataMatchesReader(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "single_table_workspace.rda");

            expectedWorkspace = readrdata(fixture);
            expected = expectedWorkspace{"xTable"};
            actual = rdata2table(fixture);

            testCase.verifyEqual(actual.Properties.UserData, expected.Properties.UserData)
            testCase.verifyEqual( ...
                actual.Properties.CustomProperties.RDataVariableMetadata, ...
                expected.Properties.CustomProperties.RDataVariableMetadata)
        end

        function testRdata2tableMalformedFileDiagnostic(testCase)
            fixture = string(tempname) + ".rds";
            fileId = fopen(fixture, "wb");
            fwrite(fileId, uint8([1 2 3 4]), "uint8");
            fclose(fileId);
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() rdata2table(fixture), "rdata:InvalidHeader")
        end
    end
end

function profileInfo = profileCall(testCase, functionHandle)
profile("clear")
profile("on")
testCase.addTeardown(@() profile("off"));
functionHandle();
profile("off")
profileInfo = profile("info");
end

function numCalls = profileCallCount(profileInfo, functionName)
functionNames = string({profileInfo.FunctionTable.FunctionName});
matches = functionNames == functionName;
numCalls = sum([profileInfo.FunctionTable(matches).NumCalls]);
end

function fixture = gzipFixture(testCase, source)
folder = string(tempname);
mkdir(folder)
testCase.addTeardown(@() rmdir(folder, "s"));
files = gzip(source, folder);
fixture = string(files{1});
end

function fixture = copyWithExtension(testCase, source, extension)
fixture = string(tempname) + extension;
copyfile(source, fixture)
testCase.addTeardown(@() delete(fixture));
end
