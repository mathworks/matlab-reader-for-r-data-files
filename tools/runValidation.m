function results = runValidation()
%runValidation - Run the complete suite on a supported MATLAB release
%   RESULTS = runValidation() creates test and coverage reports in public.
%   Run from a source checkout with tools on the MATLAB path. Rscript is
%   required for fixture generation and oracle validation.
%
%   See also runtests, testsuite

% Copyright 2026 The MathWorks, Inc.

root = fileparts(fileparts(mfilename("fullpath")));
originalFolder = pwd;
folderCleanup = onCleanup(@() cd(originalFolder));
cd(root)
project = matlab.project.rootProject;
if isempty(project)
    if ~isMATLABReleaseOlderThan("R2026b")
        project = openProject(fullfile(root, "matlab.toml"));
    else
        % Earlier releases cannot read TOML project definitions.
        % Create a local validation project in this disposable CI checkout.
        project = matlab.project.createProject(Folder=root, ...
            Name="R Data Reader Validation");
        addPath(project, fullfile(root, "tbx", "rdatareader"))
        addPath(project, fullfile(root, "tbx", "doc"))
        addPath(project, fullfile(root, "tests"))
    end
    projectCleanup = onCleanup(@() close(project));
end
assert(string(project.RootFolder) == string(root), ...
    "rdata:WrongProject", "Run validation in this repository's project.")
reportFolder = fullfile(root, "public");
if ~isfolder(reportFolder)
    mkdir(reportFolder)
end
suite = testsuite(fullfile(root, "tests"), IncludingSubfolders=true);
slowSelector = matlab.unittest.selectors.HasTag("Slow");
runner = matlab.unittest.TestRunner.withTextOutput;
runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
    fullfile(reportFolder, "test-results.xml")));
runner.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forFolder( ...
    fullfile(root, "tbx", "rdatareader"), IncludingSubfolders=true, ...
    Producing=matlab.unittest.plugins.codecoverage.CoberturaFormat( ...
        fullfile(reportFolder, "coverage.xml"))));
% Each test runs once. Avoid instrumenting the large downloaded smoke test.
fastResults = runner.run(suite.selectIf(~slowSelector));
slowRunner = matlab.unittest.TestRunner.withTextOutput;
slowRunner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
    fullfile(reportFolder, "test-results-slow.xml")));
slowResults = slowRunner.run(suite.selectIf(slowSelector));
results = [fastResults, slowResults];
summary = struct(Release=version("-release"), Build=version, ...
    Total=numel(results), Passed=sum([results.Passed]), ...
    Failed=sum([results.Failed]), Incomplete=sum([results.Incomplete]));
fileId = fopen(fullfile(reportFolder, "validation.json"), "w", "n", "UTF-8");
assert(fileId >= 0, "rdata:ReportWrite", "Unable to write validation report.")
fileCleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s\n", jsonencode(summary, PrettyPrint=true));
clear fileCleanup
save(fullfile(reportFolder, "validation.mat"), "results", "summary")
disp(summary)
assertSuccess(results)
end
