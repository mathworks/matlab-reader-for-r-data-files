classdef realWorldCorpusSlowTest < matlab.unittest.TestCase
    %realWorldCorpusSlowTest Tests slow real-world corpus imports.

    % Copyright 2026 The MathWorks, Inc.

    methods (Test, TestTags = {'Corpus', 'Slow'})
        function testLargeZenodoGzipSmoke(testCase)
            rdata.test.downloadValidationCorpus(IncludeSlow = true);
            manifestFile = fullfile(currentProject().RootFolder, ...
                "tests", "testdata", "corpus", "manifest.json");
            manifest = readstruct(manifestFile);
            fixture = findFixture(manifest, "zenodo-agrimonia");
            rfile = fullfile(string(manifest.root), ...
                string(fixture.r_serialized_files(1).relative_path));
            testCase.verifyThat(rfile, matlab.unittest.constraints.IsFile)

            workspace = readrdata(rfile);

            testCase.verifyTrue(isKey(workspace, "Agrimonia_Dataset"))
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
