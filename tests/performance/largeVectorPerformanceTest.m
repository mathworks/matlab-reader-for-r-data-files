classdef largeVectorPerformanceTest < matlab.perftest.TestCase
    %largeVectorPerformanceTest Benchmarks large atomic vectors and tables.
    %   Run with: buildtool("perftest")

% Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    properties (TestParameter)
        VectorSize = struct( ...
            Elements100k=100000, ...
            Elements1m=1000000)
    end

    methods (TestClassSetup)
        function createFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateBenchmarkFixtures();
        end
    end

    methods (Test, TestTags = {'Performance'})
        function testIntegerVector(testCase, VectorSize)
            fixture = fullfile(testCase.FixtureRoot, "integer_" + VectorSize + ".rds");

            while testCase.keepMeasuring
                [value, metadata] = readrds(fixture);
            end

            testCase.verifyNumElements(value, VectorSize)
            testCase.verifyEqual(value([1 2 4]), [1; -2; 4])
            testCase.verifyTrue(isnan(value(3)))
            testCase.verifyEqual(metadata.Missing(1:4), [false; false; true; false])
        end

        function testRealVector(testCase, VectorSize)
            fixture = fullfile(testCase.FixtureRoot, "real_" + VectorSize + ".rds");

            while testCase.keepMeasuring
                [value, metadata] = readrds(fixture);
            end

            testCase.verifyNumElements(value, VectorSize)
            testCase.verifyEqual(value(1), 1.5, AbsTol=0)
            testCase.verifyTrue(isnan(value(2)))
            testCase.verifyTrue(isnan(value(3)))
            testCase.verifyEqual(metadata.Missing(1:3), [false; true; false])
        end

        function testComplexVector(testCase, VectorSize)
            fixture = fullfile(testCase.FixtureRoot, "complex_" + VectorSize + ".rds");

            while testCase.keepMeasuring
                [value, metadata] = readrds(fixture);
            end

            testCase.verifyNumElements(value, VectorSize)
            testCase.verifyEqual(value(1), 1 + 2i, AbsTol=0)
            testCase.verifyTrue(isnan(real(value(2))))
            testCase.verifyTrue(isnan(imag(value(2))))
            testCase.verifyTrue(isnan(real(value(3))))
            testCase.verifyEqual(imag(value(3)), 3, AbsTol=0)
            testCase.verifyEqual(metadata.Missing(1:3), [false; true; false])
        end

        function testLargeTable(testCase)
            fixture = fullfile(testCase.FixtureRoot, "table_1000000.rds");

            while testCase.keepMeasuring
                value = rdata2table(fixture);
            end

            variableMetadata = value.Properties.CustomProperties.RDataVariableMetadata;
            testCase.verifySize(value, [1000000 3])
            testCase.verifyEqual(value.id([1 2 4]), [1; 2; 4])
            testCase.verifyTrue(isnan(value.id(3)))
            testCase.verifyEqual(variableMetadata.MissingMask{1}(1:4), ...
                [false; false; true; false])
        end
    end
end
