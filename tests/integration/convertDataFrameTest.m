classdef convertDataFrameTest < matlab.unittest.TestCase
    %convertDataFrameTest Tests R data.frame and tibble-like conversion.

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
        function testSimpleDataFrame(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifySize(value, [3 5])
            testCase.verifyEqual(value.id(1:2), [10; 20])
            testCase.verifyTrue(isnan(value.id(3)))
            testCase.verifyEqual(value.value(1), 1.5)
            testCase.verifyTrue(isnan(value.value(2)))
            testCase.verifyEqual(value.flag, [true; false; false])
            testCase.verifyTrue(isundefined(value.group(3)))
            testCase.verifyEqual(value.text(1), "alpha")
            testCase.verifyTrue(ismissing(value.text(2)))
        end

        function testReadrdsDataFrameMatchesWrapper(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            directTable = readrds(fixture);
            wrapperTable = rdata2table(fixture);

            testCase.verifyClass(directTable, "table")
            testCase.verifyEqual(size(directTable), size(wrapperTable))
            testCase.verifyEqual(directTable.id, wrapperTable.id)
            testCase.verifyEqual(directTable.value, wrapperTable.value)
            testCase.verifyEqual(directTable.flag, wrapperTable.flag)
            testCase.verifyEqual(directTable.group, wrapperTable.group)
            testCase.verifyEqual(directTable.text, wrapperTable.text)
        end

        function testReadrdsDataFrameMetadata(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            [value, metadata] = readrds(fixture);
            variableMetadata = value.Properties.CustomProperties.RDataVariableMetadata;
            tableMetadata = value.Properties.UserData.RDataMetadata;

            testCase.verifyTrue(isprop(value.Properties.CustomProperties, "RDataVariableMetadata"))
            testCase.verifyEqual(variableMetadata.VariableName, ["id"; "value"; "flag"; "group"; "text"])
            testCase.verifyEqual(tableMetadata.RClass, "data.frame")
            testCase.verifyEqual(metadata.RType, "VECSXP")
            testCase.verifyEqual(metadata.RClass, "data.frame")
            testCase.verifyEqual(metadata.ObjectName, "")
        end

        function testRdata2tableReadsSingleTableWorkspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "single_table_workspace.rda");

            value = rdata2table(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifySize(value, [3 5])
            testCase.verifyEqual(value.id(1:2), [10; 20])
        end

        function testRdata2tableRejectsNonTableRds(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "integer_vector.rds");

            testCase.verifyError(@() rdata2table(fixture), "rdata:UnsupportedRType")
        end

        function testRdata2tableRejectsMultiObjectWorkspace(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            testCase.verifyError(@() rdata2table(fixture), "rdata:UnsupportedRType")
        end

        function testReadrdsAttachMetadataFalse(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            [value, metadata] = readrds(fixture, AttachMetadata=false);

            testCase.verifyClass(value, "table")
            testCase.verifySize(value, [3 5])
            testCase.verifyFalse(isprop(value.Properties.CustomProperties, "RDataVariableMetadata"))
            testCase.verifyEmpty(value.Properties.UserData)
            testCase.verifyEqual(metadata.RType, "VECSXP")
            testCase.verifyEqual(metadata.RClass, "data.frame")
        end

        function testRdata2tableAttachMetadataFalse(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            value = rdata2table(fixture, AttachMetadata=false);

            testCase.verifyClass(value, "table")
            testCase.verifyFalse(isprop( ...
                value.Properties.CustomProperties, ...
                "RDataVariableMetadata"))
            testCase.verifyEmpty(value.Properties.UserData)
        end

        function testNestedListAttachMetadataTrue(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "list_with_data_frame.rds");

            value = readrds(fixture, AttachMetadata=true);

            frame = value{"frame"};
            testCase.verifyClass(frame, "table")
            testCase.verifyTrue(isprop( ...
                frame.Properties.CustomProperties, ...
                "RDataVariableMetadata"))
            testCase.verifyTrue(isfield( ...
                frame.Properties.UserData, ...
                "RDataMetadata"))
        end

        function testNestedListAttachMetadataFalse(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "list_with_data_frame.rds");

            value = readrds(fixture, AttachMetadata=false);

            frame = value{"frame"};
            testCase.verifyClass(frame, "table")
            testCase.verifyFalse(isprop( ...
                frame.Properties.CustomProperties, ...
                "RDataVariableMetadata"))
            testCase.verifyEmpty(frame.Properties.UserData)
        end

        function testVariableMetadataPreservesColumnMasks(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            value = readrds(fixture);
            variableMetadata = value.Properties.CustomProperties.RDataVariableMetadata;

            testCase.verifyEqual(variableMetadata.VariableName, ["id"; "value"; "flag"; "group"; "text"])
            testCase.verifyEqual(variableMetadata.RType(3), "LGLSXP")
            testCase.verifyEqual(variableMetadata.MissingMask{3}, [false; false; true])
            testCase.verifyEqual(variableMetadata.MissingMask{5}, [false; true; false])
        end

        function testCellstrTableVariablePreservesMissingMask(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "simple_data_frame.rds");

            value = readrds(fixture, TextType="cellstr");
            variableMetadata = value.Properties.CustomProperties.RDataVariableMetadata;

            testCase.verifyTrue(iscellstr(value.text))
            testCase.verifyEqual(value.text{2}, '')
            testCase.verifyEqual(variableMetadata.MissingMask{5}, [false; true; false])
        end

        function testTableAllowsArbitraryVariableNames(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "invalid_name_data_frame.rds");

            value = readrds(fixture);

            testCase.verifyEqual(value.Properties.VariableNames, {'bad-name', 'bad/name'})
        end

        function testDataFrameWithImplicitColumns(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rds", "implicit_columns_data_frame.rds");

            value = readrds(fixture);
            variableMetadata = value.Properties.CustomProperties.RDataVariableMetadata;

            testCase.verifyEqual(value.Properties.VariableNames, {'Var1', 'Var2'})
            testCase.verifyEqual(value.Var1, [1; 2])
            testCase.verifyEqual(value.Var2, ["a"; "b"])
            testCase.verifyEqual(variableMetadata.VariableName, ["Var1"; "Var2"])
        end

        function testTibbleLikeDataFrame(testCase)
            fixture = fullfile(testCase.FixtureRoot, "rds", "tibble_like.rds");

            value = readrds(fixture);

            testCase.verifyClass(value, "table")
            testCase.verifyEqual(value.Properties.UserData.RDataMetadata.RClass, ...
                ["tbl_df"; "tbl"; "data.frame"])
        end

        function testWorkspaceContainsDataFrame(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            workspace = readrdata(fixture);

            tableValue = workspace{"xTable"};
            testCase.verifyClass(tableValue, "table")
            testCase.verifySize(tableValue, [3 5])
            testCase.verifyTrue(isprop( ...
                tableValue.Properties.CustomProperties, ...
                "RDataVariableMetadata"))
        end

        function testNestedTableAttachMetadataFalse(testCase)
            fixture = fullfile(testCase.FixtureRoot, ...
                "rdata", "primitive_workspace.rda");

            [workspace, metadata] = readrdata(fixture, AttachMetadata=false);
            objectNames = string({metadata.Objects.ObjectName});
            tableObject = metadata.Objects(objectNames == "xTable");
            tableValue = workspace{"xTable"};

            testCase.verifyClass(tableValue, "table")
            testCase.verifyFalse(isprop( ...
                tableValue.Properties.CustomProperties, ...
                "RDataVariableMetadata"))
            testCase.verifyEmpty(tableValue.Properties.UserData)
            testCase.verifyEqual(tableObject.RType, "VECSXP")
            testCase.verifyEqual(tableObject.RClass, "data.frame")
        end
    end
end
