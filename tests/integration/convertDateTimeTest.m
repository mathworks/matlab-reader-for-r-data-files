classdef convertDateTimeTest < matlab.unittest.TestCase
    %convertDateTimeTest Tests R Date, POSIXct, and difftime conversion.

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
        function testDateVector(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "date_vector.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "datetime")
            testCase.verifyEqual(value(1), datetime(2020, 1, 1))
            testCase.verifyTrue(isnat(value(2)))
            testCase.verifyEqual(value(3), datetime(1970, 1, 1))
        end

        function testPosixctUtc(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "posixct_utc.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "datetime")
            testCase.verifyEqual(value.TimeZone, 'UTC')
            testCase.verifyEqual(value(1), datetime(2020, 1, 1, 12, 30, 0, TimeZone="UTC"))
            testCase.verifyTrue(isnat(value(2)))
            testCase.verifyEqual(value(3), datetime(1970, 1, 1, 0, 0, 0, TimeZone="UTC"))
        end

        function testPosixctLondon(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "posixct_london.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "datetime")
            testCase.verifyEqual(value.TimeZone, 'Europe/London')
            testCase.verifyEqual(value(1), datetime(2024, 3, 31, 0, 30, 0, TimeZone="Europe/London"))
            testCase.verifyEqual(value(2), datetime(2024, 3, 31, 2, 30, 0, TimeZone="Europe/London"))
        end

        function testDifftimeSeconds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "difftime_seconds.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "duration")
            testCase.verifyEqual(value(1), seconds(30))
            testCase.verifyTrue(isnan(seconds(value(2))))
            testCase.verifyEqual(value(3), seconds(3600))
        end

        function testPosixltDiagnostic(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "posixlt_object.rds");

            testCase.verifyError(@() readrds(fixture), "rdata:UnsupportedRClass")
        end
    end
end
