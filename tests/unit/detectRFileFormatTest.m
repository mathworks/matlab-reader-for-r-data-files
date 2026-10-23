classdef detectRFileFormatTest < matlab.unittest.TestCase
    %detectRFileFormatTest Tests R file and compression detection.

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
        function testUncompressedRds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            info = rdata.internal.detectRFileFormat(fixture);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.Compression, "none")
            testCase.verifyEqual(info.SerializationFormat, "XDR")
            testCase.verifyEqual(info.SerializationVersion, 3)
        end

        function testGzipRds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector_gzip.rds");

            info = rdata.internal.detectRFileFormat(fixture);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.Compression, "gzip")
            testCase.verifyEqual(info.SerializationFormat, "XDR")
        end

        function testUncompressedRData(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            info = rdata.internal.detectRFileFormat(fixture);

            testCase.verifyEqual(info.FileType, "RData")
            testCase.verifyEqual(info.SaveHeader, "RDX3")
            testCase.verifyEqual(info.SerializationVersion, 3)
        end

        function testMisleadingExtension(testCase)
            source = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");
            target = fullfile(testCase.FixtureRoot, "integer_vector.csv");
            copyfile(source, target)
            testCase.addTeardown(@() delete(target));

            info = rdata.internal.detectRFileFormat(target);

            testCase.verifyEqual(info.FileType, "RDS")
            testCase.verifyEqual(info.SerializationFormat, "XDR")
        end

        function testEmptyFileErrors(testCase)
            fixture = fullfile(tempdir, "empty-r-file.rds");
            fileId = fopen(fixture, "w");
            fclose(fileId);
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() rdata.internal.detectRFileFormat(fixture), "rdata:InvalidHeader")
        end

        function testRandomBytesError(testCase)
            fixture = fullfile(tempdir, "random-r-file.rds");
            fileId = fopen(fixture, "w");
            fwrite(fileId, uint8([1 2 3 4 5 6]), "uint8");
            fclose(fileId);
            testCase.addTeardown(@() delete(fixture));

            testCase.verifyError(@() rdata.internal.detectRFileFormat(fixture), "rdata:InvalidHeader")
        end
    end
end
