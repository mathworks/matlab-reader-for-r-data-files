classdef realWorldCorpusTest < matlab.unittest.TestCase
    %realWorldCorpusTest Tests selected downloaded real-world fixtures.

    % Copyright 2026 The MathWorks, Inc.

    properties
        Manifest
    end

    methods (TestClassSetup)
        function prepareFixtures(testCase)
            rdata.test.downloadValidationCorpus();
            manifest = fullfile(currentProject().RootFolder, ...
                "tests", "testdata", "corpus", "manifest.json");
            testCase.verifyThat(manifest, matlab.unittest.constraints.IsFile)
            testCase.Manifest = readstruct(manifest);
        end
    end

    methods (Test, TestTags = {'Corpus'})
        function testSupportedGzipCorpusImports(testCase)
            supportedIds = [
                "openintro-gpa-study-hours"
                "openintro-books"
                "gapminder-main"
                "gapminder-unfiltered"
                "gapminder-country-codes"
                "gapminder-country-colors"
                "gapminder-continent-colors"
                "nycflights13-airlines"
                "nycflights13-airports"
                "nycflights13-planes"
                "meta-analysis-main"
                "meta-analysis-binarydata"
                "meta-analysis-foresttable"
            ];

            verifyCorpusImports(testCase, supportedIds)
        end

        function testSelectedBaselinesMatchDimensions(testCase)
            verifyBaselineDimensions(testCase, "openintro-books")
            verifyBaselineDimensions(testCase, "openintro-gpa-study-hours")
            verifyBaselineDimensions(testCase, "gapminder-country-codes")
        end

        function testUnsupportedCompressionDiagnostics(testCase)
            verifyUnsupportedCompression(testCase)
        end

        function testPreviouslyUnsupportedAltrepCorpusImports(testCase)
            fixture = findFixture(testCase.Manifest, "islr2-auto");
            rfile = fullfile(string(testCase.Manifest.root), ...
                string(fixture.r_serialized_files(1).relative_path));
            baseline = fullfile(string(testCase.Manifest.root), ...
                string(fixture.comparison_files(1).relative_path));
            testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)
            testCase.verifyThat(baseline, matlab.unittest.constraints.IsFile)
            workspace = readrdata(rfile);
            baselineTable = readBaselineTable(baseline);
            info = readCorpusInfo(testCase, "islr2-auto");

            auto = workspace{"Auto"};
            testCase.verifyClass(auto, "table")
            testCase.verifyEqual(height(auto), height(baselineTable))
            testCase.verifyEqual(width(auto), 9)
            testCase.verifyEqual(info.Objects.Size, "392x9")
            testCase.verifyTrue(info.Objects.Supported)
        end
    end

    methods (Test, TestTags = {'Corpus', 'Slow'})
        function testLargeZenodoGzipSmoke(testCase)
            rdata.test.downloadValidationCorpus(IncludeSlow = true);
            manifest = fullfile(currentProject().RootFolder, ...
                "tests", "testdata", "corpus", "manifest.json");
            testCase.Manifest = readstruct(manifest);
            fixture = findFixture(testCase.Manifest, "zenodo-agrimonia");
            rfile = fullfile(string(testCase.Manifest.root), ...
                string(fixture.r_serialized_files(1).relative_path));
            testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)

            workspace = readrdata(rfile);

            testCase.verifyTrue(isKey(workspace, "Agrimonia_Dataset"))
        end
    end
end

function verifyCorpusImports(testCase, supportedIds)
for k = 1:numel(supportedIds)
    fixture = findFixture(testCase.Manifest, supportedIds(k));
    rfile = fullfile(string(testCase.Manifest.root), ...
        string(fixture.r_serialized_files(1).relative_path));
    testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)
    workspace = readrdata(rfile);
    testCase.verifyClass(workspace, "dictionary", ...
        "Import did not return a dictionary for " + supportedIds(k))
    testCase.verifyGreaterThan(numel(workspace.keys), 0, ...
        "No workspace objects imported for " + supportedIds(k))
end
end

function verifyBaselineDimensions(testCase, fixtureId)
fixture = findFixture(testCase.Manifest, fixtureId);
rfile = fullfile(string(testCase.Manifest.root), string(fixture.r_serialized_files(1).relative_path));
baseline = fullfile(string(testCase.Manifest.root), string(fixture.comparison_files(1).relative_path));
testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)
testCase.verifyThat(baseline, matlab.unittest.constraints.IsFile)
workspace = readrdata(rfile);
workspaceKeys = keys(workspace);
imported = workspace{workspaceKeys(1)};
baselineTable = readBaselineTable(baseline);

testCase.verifyClass(imported, "table")
testCase.verifyEqual(height(imported), height(baselineTable), ...
    "Baseline height mismatch for " + fixtureId)
testCase.verifyEqual(width(imported), width(baselineTable), ...
    "Baseline width mismatch for " + fixtureId)
end

function info = readCorpusInfo(testCase, fixtureId)
fixture = findFixture(testCase.Manifest, fixtureId);
rfile = fullfile(string(testCase.Manifest.root), string(fixture.r_serialized_files(1).relative_path));
testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)
info = rdatainfo(rfile);
end

function verifyUnsupportedCompression(testCase)
for k = 1:numel(testCase.Manifest.fixtures)
    fixture = testCase.Manifest.fixtures(k);
    rfile = fullfile(string(testCase.Manifest.root), ...
        string(fixture.r_serialized_files(1).relative_path));
    testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)
    bytes = rdata.internal.readFileBytes(rfile);
    compression = rdata.internal.detectCompression(bytes);
    if compression == "bzip2" || compression == "xz"
        testCase.verifyError(@() readrdata(rfile), "rdata:UnsupportedCompression")
    end
end
end

function fixture = findFixture(manifest, fixtureId)
ids = string({manifest.fixtures.id});
index = find(ids == fixtureId, 1);
if isempty(index)
    error("rdata:MissingFixture", "Fixture '%s' was not found in the manifest.", fixtureId)
end
fixture = manifest.fixtures(index);
end

function baselineTable = readBaselineTable(filename)
[~, ~, ext] = fileparts(filename);
switch lower(ext)
    case ".tsv"
        baselineTable = readtable(filename, FileType="text", Delimiter="\t");
    case ".csv"
        baselineTable = readtable(filename);
    otherwise
        baselineTable = table();
end
end
