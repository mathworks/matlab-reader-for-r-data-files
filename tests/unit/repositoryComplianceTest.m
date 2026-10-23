classdef repositoryComplianceTest < matlab.unittest.TestCase
    %REPOSITORYCOMPLIANCETEST Check mechanically verifiable release files.

% Copyright 2026 The MathWorks, Inc.

    properties (SetAccess = private)
        ProjectRoot (1,1) string
    end

    methods (TestMethodSetup)
        function findProjectRoot(testCase)
            testCase.ProjectRoot = currentProject().RootFolder;
        end
    end

    methods (Test)
        function testRequiredSupportFilesExist(testCase)
            requiredFiles = [ ...
                "LICENSE.txt", ...
                "SECURITY.md", ...
                "README.md", ...
                "DEVELOPMENT.md", ...
                fullfile("docs", "media", "rdata-import.svg")];
            missingFiles = requiredFiles(~isfile(fullfile( ...
                testCase.ProjectRoot, requiredFiles)));

            testCase.verifyEmpty(missingFiles, ...
                "Missing required support files: " + join(missingFiles, ", "))
        end

        function testApprovedSecurityLinkIsPresent(testCase)
            securityText = fileread(fullfile(testCase.ProjectRoot, "SECURITY.md"));
            testCase.verifySubstring(securityText, ...
                "[product-security@mathworks.com](mailto:product-security@mathworks.com)")
            testCase.verifySubstring(securityText, ...
                "vulnerability-disclosure-policy.html")
        end

        function testTextFilesContainCopyright(testCase)
            patterns = ["*.m", "*.R", "*.md", "*.txt", "*.json", "*.svg", ...
                "*.yml", "*.yaml", "*.toml", "*.css", "*.py", ".gitignore", ".gitattributes"];
            missingCopyright = findFilesMissingCopyright( ...
                testCase.ProjectRoot, patterns);

            testCase.verifyEmpty(missingCopyright, ...
                "Missing copyright notices: " + join(missingCopyright, ", "))
        end

        function testGettingStartedHasNoSavedOutputs(testCase)
            guide = fileread(fullfile(testCase.ProjectRoot, ...
                "tbx", "doc", "mfiles", "GettingStarted.m"));
            testCase.verifyFalse(contains(guide, "%[output:"))
            testCase.verifyFalse(contains(guide, '"outputData"'))
        end

        function testPublicDestination(testCase)
            readme = fileread(fullfile(testCase.ProjectRoot, "README.md"));
            testCase.verifySubstring(readme, "mathworks/matlab-reader-for-r-data-files")
            testCase.verifySubstring(readme, "repo=mathworks/matlab-reader-for-r-data-files")
        end

        function testDevelopmentGuideIsInternalFacing(testCase)
            readmeText = fileread(fullfile(testCase.ProjectRoot, "README.md"));

            testCase.verifyFalse(isfile(fullfile( ...
                testCase.ProjectRoot, "CONTRIBUTING.md")))
            testCase.verifySubstring(readmeText, ...
                "[DEVELOPMENT.md](DEVELOPMENT.md)")
        end

        function testReadmeVisualIsAccessible(testCase)
            readme = fileread(fullfile(testCase.ProjectRoot, "README.md"));
            diagram = fileread(fullfile(testCase.ProjectRoot, "docs", "media", "rdata-import.svg"));
            testCase.verifySubstring(readme, ...
                "![R file formats converted to MATLAB values](docs/media/rdata-import.svg)")
            testCase.verifySubstring(diagram, "Copyright 2026 The MathWorks, Inc.")
            testCase.verifySubstring(diagram, "<title")
            testCase.verifySubstring(diagram, "<desc")
        end

        function testTrademarkReviewRequirements(testCase)
            readmeText = string(fileread(fullfile( ...
                testCase.ProjectRoot, "README.md")));
            modelText = string(fileread(fullfile( ...
                testCase.ProjectRoot, "docs", "MODEL_ADAPTERS.md")));
            releaseText = string(fileread(fullfile( ...
                testCase.ProjectRoot, "tools", "RELEASE_CHECKLIST.md")));
            benchmarkText = string(fileread(fullfile( ...
                testCase.ProjectRoot, "tests", "performance", "README.md")));

            readmeLines = splitlines(readmeText);
            testCase.verifyEqual(readmeLines(1), ...
                "# MATLAB Reader for R Data Files")
            testCase.verifyEqual(count(readmeText, "MATLAB&reg;"), 1)
            testCase.verifyEqual(count(readmeText, "R&reg;"), 1)
            testCase.verifyEqual(count(readmeText, "Java&reg;"), 1)
            testCase.verifyEqual(count(readmeText, "Git&trade;"), 1)

            testCase.verifyEqual(count(modelText, "MATLAB&reg;"), 1)
            testCase.verifyEqual(count(modelText, "R&reg;"), 1)

            testCase.verifyEqual(count(releaseText, "MATLAB&reg;"), 1)
            testCase.verifyEqual(count(releaseText, "Online&trade;"), 1)
            testCase.verifyEqual(count(releaseText, "GitHub&reg;"), 1)
            testCase.verifyEqual(count(releaseText, "R&reg;"), 1)

            testCase.verifyEqual(count(benchmarkText, "MATLAB&reg;"), 1)
            testCase.verifyEqual(count(benchmarkText, "Windows&reg;"), 1)
            testCase.verifyEqual(count(benchmarkText, "R&reg;"), 1)
        end
    end
end

function missingCopyright = findFilesMissingCopyright(projectRoot, patterns)
filenames = strings(0, 1);
for k = 1:numel(patterns)
    files = dir(fullfile(projectRoot, "**", patterns(k)));
    filenames = [filenames; ...
        string(fullfile({files.folder}, {files.name})).']; %#ok<AGROW>
end

excludedFolders = ["public", ".git", ".buildtool", "releases", ...
    fullfile("tests", "testdata", "corpus")];
for k = 1:numel(excludedFolders)
    excludedPrefix = fullfile(projectRoot, excludedFolders(k)) + filesep;
    filenames = filenames(~startsWith(filenames, excludedPrefix));
end
generatedHelpFolder = fullfile(projectRoot, "tbx", "doc", "helpsearch");
filenames = filenames(~startsWith(filenames, generatedHelpFolder));

missingCopyright = strings(0, 1);
for k = 1:numel(filenames)
    if ~contains(fileread(filenames(k)), ...
            "Copyright 2026 The MathWorks, Inc.")
        missingCopyright(end + 1, 1) = filenames(k); %#ok<AGROW>
    end
end
end
