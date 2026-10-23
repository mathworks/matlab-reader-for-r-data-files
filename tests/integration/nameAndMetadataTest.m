classdef nameAndMetadataTest < matlab.unittest.TestCase
    %nameAndMetadataTest - Guard against data loss during R object conversion

    % Copyright 2026 The MathWorks, Inc.

    properties
        FixtureRoot (1,1) string
    end

    properties (TestParameter)
        duplicateFile = struct(frame="duplicate_columns.rds", list="duplicate_list.rds", ...
            nested="nested_duplicate_list.rds")
        invalidColumn = struct(colon="reserved_column.rds", properties="properties_column.rds", ...
            empty="empty_column.rds")
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            testCase.FixtureRoot = rdata.test.generateSyntheticFixtures( ...
                currentProject().RootFolder);
        end
    end

    methods (Test, TestTags = {'Synthetic'})
        function rejectsDuplicateNames(testCase, duplicateFile)
            fixture = fullfile(testCase.FixtureRoot, "rds", duplicateFile);
            testCase.verifyError(@() readrds(fixture), "rdata:DuplicateNames")
        end

        function rejectsDuplicateTableNames(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "duplicate_columns.rds");
            testCase.verifyError(@() rdata2table(fixture), "rdata:DuplicateNames")
        end

        function rejectsDuplicateWorkspaceNames(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rdata", "duplicate_workspace.rda");
            testCase.verifyError(@() readrdata(fixture), "rdata:DuplicateNames")
        end

        function rejectsInvalidTableNames(testCase, invalidColumn)
            fixture = fullfile(testCase.FixtureRoot, "rds", invalidColumn);
            testCase.verifyError(@() readrds(fixture), "rdata:InvalidTableVariableName")
        end

        function retainsPunctuationInNames(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "invalid_name_data_frame.rds");
            value = readrds(fixture);
            testCase.verifyEqual(value.Properties.VariableNames, {'bad-name', 'bad/name'})
            testCase.verifyEqual(value.("bad-name"), [1; 2], AbsTol=0)
            testCase.verifyEqual(value.("bad/name"), [3; 4], AbsTol=0)
        end

        function separatesRowTimeMetadata(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "timetable_metadata.rds");
            value = rdata2table(fixture, OutputType="timetable");
            metadata = value.Properties.CustomProperties.RDataVariableMetadata;
            rowMetadata = value.Properties.CustomProperties.RDataRowTimeMetadata;
            testCase.verifyEqual(value.Properties.VariableNames, {'flag'})
            testCase.verifyEqual(metadata.VariableName, "flag")
            testCase.verifyEqual(metadata.MissingMask{1}, [true; false])
            testCase.verifyEqual(rowMetadata.VariableName, "Time")
            testCase.verifyEqual(rowMetadata.MissingMask{1}, [false; false])
            testCase.verifyEqual(value.Properties.RowTimes, ...
                datetime(2020, 1, [1; 2]))
        end

        function preservesCustomTimeAndColumnOrder(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "timetable_custom_time.rds");
            value = rdata2table(fixture, OutputType="timetable", RowTimes="When");
            metadata = value.Properties.CustomProperties.RDataVariableMetadata;
            rowMetadata = value.Properties.CustomProperties.RDataRowTimeMetadata;
            testCase.verifyEqual(value.Properties.VariableNames, {'before', 'after'})
            testCase.verifyEqual(metadata.VariableName, ["before"; "after"])
            testCase.verifyEqual(metadata.MissingMask{1}, [true; false])
            testCase.verifyEqual(metadata.MissingMask{2}, [false; true])
            testCase.verifyEqual(rowMetadata.VariableName, "When")
        end

        function omitsTimetableMetadataWhenDisabled(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "timetable_metadata.rds");
            value = rdata2table(fixture, OutputType="timetable", AttachMetadata=false);
            testCase.verifyFalse(isprop(value.Properties.CustomProperties, "RDataVariableMetadata"))
            testCase.verifyFalse(isprop(value.Properties.CustomProperties, "RDataRowTimeMetadata"))
            testCase.verifyEmpty(value.Properties.UserData)
        end

        function keepsTimeColumnForTableOutput(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "timetable_metadata.rds");
            value = rdata2table(fixture);
            testCase.verifyEqual(value.Properties.VariableNames, {'Time', 'flag'})
            testCase.verifyEqual( ...
                value.Properties.CustomProperties.RDataVariableMetadata.VariableName, ...
                ["Time"; "flag"])
            testCase.verifyFalse(isprop(value.Properties.CustomProperties, "RDataRowTimeMetadata"))
        end
    end
end
