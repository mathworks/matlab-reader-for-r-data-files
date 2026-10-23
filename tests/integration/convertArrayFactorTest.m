classdef convertArrayFactorTest < matlab.unittest.TestCase
    %convertArrayFactorTest Tests arrays, dim metadata, and factor conversion.

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
        function testNumericMatrix(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "numeric_matrix.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifySize(value, [2 3])
            testCase.verifyEqual(value(1, 1), 1.5)
            testCase.verifyTrue(isnan(value(2, 1)))
            testCase.verifyEqual(value(:, 2), [3; 4])
            testCase.verifyEqual(metadata.Dimensions, [2 3])
            testCase.verifyTrue(any(metadata.Attributes.Name == "dimnames"))
        end

        function testArray3d(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "array_3d.rds");

            value = readrds(fixture);

            testCase.verifySize(value, [2 2 2])
            testCase.verifyEqual(value(:, :, 1), [1 3; 2 4])
            testCase.verifyEqual(value(:, :, 2), [5 7; 6 8])
        end

        function testSimpleFactor(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "simple_factor.rds");

            [value, metadata] = readrds(fixture);

            testCase.verifyClass(value, "categorical")
            testCase.verifyEqual(categories(value), {'low'; 'medium'; 'high'})
            testCase.verifyEqual(string(value(1)), "low")
            testCase.verifyTrue(isundefined(value(3)))
            testCase.verifyEqual(metadata.RClass, "factor")
        end

        function testOrderedFactor(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "ordered_factor.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "categorical")
            testCase.verifyEqual(categories(value), {'small'; 'medium'; 'large'})
            testCase.verifyTrue(isordinal(value))
            testCase.verifyTrue(isundefined(value(4)))
        end
    end
end
