function plan = buildfile
% Copyright 2026 The MathWorks, Inc.

import matlab.buildtool.tasks.*
import matlab.unittest.selectors.*

plan = buildplan(localfunctions);

plan("clean") = CleanTask;
plan("check") = CodeIssuesTask;
plan("test") = TestTask("./tests", ...
    SourceFiles = "tbx/rdatareader", ...
    TestResults= "public/testresults.html", ...
    Selector = ~HasTag("Slow"), ...
    CodeCoverageResults= ["public/coverage.xml", "public/coverage.html"]);

plan("testall") = TestTask("./tests", ...
    SourceFiles = "tbx/rdatareader", ...
    TestResults= "public/testresults.html");

plan("archive").Dependencies = ["generatecontents", "testall", "check", "doc"];
plan("archive").Outputs = fullfile("releases", "rDataReader.mltbx");
plan("archive").Inputs = ["tbx", "LICENSE.txt", "SECURITY.md", "buildfile.m"];

plan.DefaultTasks = ["check" "test"];

end

function generatecontentsTask(~)
projectRoot = currentProject().RootFolder;
templateFile = fullfile(projectRoot, "Contents.inc");
contentsFile = fullfile(projectRoot, "tbx", "rdatareader", "Contents.m");
version = releaseVersion();
dateText = string(datetime("today", Format="dd-MMM-yyyy", Locale="en_US"));

contents = string(fileread(templateFile));
contents = replace(contents, "@VERSION@", version);
contents = replace(contents, "@DATE@", dateText);
if contains(contents, ["@VERSION@", "@DATE@"])
    error("rdata:ContentsTemplate", ...
        "Contents.inc contains an unreplaced release placeholder.")
end

fileId = fopen(contentsFile, "w");
if fileId < 0
    error("rdata:ContentsWrite", "Unable to write %s.", contentsFile)
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s", contents);
end

function archiveTask(~)
projectRoot = currentProject().RootFolder;
packageRoot = fullfile(projectRoot, "tbx");
supportFiles = ["LICENSE.txt", "SECURITY.md"];
for k = 1:numel(supportFiles)
    copyfile(fullfile(projectRoot, supportFiles(k)), packageRoot)
end

opts = matlab.addons.toolbox.ToolboxOptions(packageRoot, ...
    "246c70da-75ae-49a6-a15d-2867a43eb24a");
opts.AuthorCompany = "MathWorks";
opts.AuthorEmail = "stheakst@mathworks.com";
opts.AuthorName = "Stuart Theakston";
opts.OutputFile = fullfile(projectRoot, "releases", "rDataReader.mltbx");
opts.Summary = "Import serialized R data files without running R.";
opts.PackageName = "rdatareader";
opts.ToolboxName = "MATLAB Reader for R Data Files";
opts.ToolboxVersion = releaseVersion();
opts.MinimumMatlabRelease = "R2025a";
opts.ToolboxGettingStartedGuide = fullfile(packageRoot, "doc", "mfiles", "GettingStarted.m");
opts.ToolboxMatlabPath = [fullfile(packageRoot, "rdatareader"), fullfile(packageRoot, "doc")];

% Package only runtime code, authored help, generated help, and support files.
% An explicit list prevents stale downloads or build artifacts from shipping.
runtimeFiles = dir(fullfile(packageRoot, "rdatareader", "**", "*.m"));
docFiles = [dir(fullfile(packageRoot, "doc", "*.md")); ...
    dir(fullfile(packageRoot, "doc", "*.html")); ...
    dir(fullfile(packageRoot, "doc", "*.xml")); ...
    dir(fullfile(packageRoot, "doc", "*.css"))];
guideFile = fullfile(packageRoot, "doc", "mfiles", "GettingStarted.m");
searchFiles = dir(fullfile(packageRoot, "doc", "helpsearch-v*", "**", "*"));
searchFiles = searchFiles(~[searchFiles.isdir]);
files = [runtimeFiles; docFiles; searchFiles];
opts.ToolboxFiles = [string(fullfile({files.folder}, {files.name})), ...
    guideFile, fullfile(packageRoot, supportFiles)];
if ~isfolder(fullfile(projectRoot, "releases"))
    mkdir(fullfile(projectRoot, "releases"))
end
matlab.addons.toolbox.packageToolbox(opts)
end

function version = releaseVersion()
version = string(getenv("RDATAREADER_VERSION"));
if strlength(version) == 0
    error("rdata:MissingReleaseVersion", ...
        "Set RDATAREADER_VERSION to a release tag such as v1.2.3.")
end
if startsWith(version, "v")
    version = extractAfter(version, 1);
end
if isempty(regexp(version, "^\d+\.\d+\.\d+$", "once"))
    error("rdata:InvalidReleaseVersion", ...
        "RDATAREADER_VERSION must use v<major>.<minor>.<patch> format.")
end
end

function docTask(~)
% Generate static help locally, without running example code or remote APIs.
projectRoot = currentProject().RootFolder;
docRoot = fullfile(projectRoot, "tbx", "doc");
python = string(getenv("RDATA_PYTHON"));
if strlength(python) == 0
    python = "python";
end
command = rdata.test.quoteCommandArgument(python) + " " + ...
    rdata.test.quoteCommandArgument(fullfile(projectRoot, "tools", "build_help.py"));
[status, output] = system(command);
if status ~= 0
    error("rdata:HelpBuild", ...
        "Static help failed. Install requirements-build.txt.\n%s", output)
end
% Remove stale converter assets from earlier builds before packaging.
resourceFolder = fullfile(docRoot, "resources");
assert(startsWith(string(resourceFolder), string(projectRoot) + filesep))
if isfolder(resourceFolder)
    rmdir(resourceFolder, "s")
end
builddocsearchdb(docRoot)
generatedMetadata = fullfile(docRoot, "custom_toolbox.json");
if isfile(generatedMetadata)
    delete(generatedMetadata)
end
end

function perftestTask(~)
import matlab.perftest.TimeExperiment
testFile = fullfile(currentProject().RootFolder, "tests", ...
    "performance", "largeVectorPerformanceTest.m");
suite = testsuite(testFile);
experiment = TimeExperiment.withFixedSampleSize(4);
results = run(experiment, suite);
displayTimingSummary(results)

fixture = fullfile(tempdir, "matlab-r-reader-benchmarks", "table_1000000.rds");
[beforeMemory, ~] = memory;
peakBefore = processPeakWorkingSet();
[value, metadata] = readrds(fixture); %#ok<ASGLU>
[afterMemory, ~] = memory;
peakAfter = processPeakWorkingSet();

fileInfo = dir(fixture);
valueInfo = whos("value");
metadataInfo = whos("metadata");
memoryObservation = table( ...
    fileInfo.bytes/2^20, ...
    (valueInfo.bytes + metadataInfo.bytes)/2^20, ...
    beforeMemory.MemUsedMATLAB/2^20, ...
    afterMemory.MemUsedMATLAB/2^20, ...
    peakBefore/2^20, ...
    peakAfter/2^20, ...
    VariableNames=[ ...
        "InputFileMB", ...
        "ReturnedValueAndMetadataMB", ...
        "MatlabMemoryBeforeMB", ...
        "MatlabMemoryAfterMB", ...
        "ProcessPeakBeforeMB", ...
        "ProcessPeakAfterMB"]);
disp(memoryObservation)
end

function displayTimingSummary(results)
numResults = numel(results);
testName = strings(numResults, 1);
medianSeconds = zeros(numResults, 1);
minimumSeconds = zeros(numResults, 1);
maximumSeconds = zeros(numResults, 1);
for k = 1:numResults
    samples = results(k).Samples.MeasuredTime;
    testName(k) = string(results(k).Name);
    medianSeconds(k) = median(samples);
    minimumSeconds(k) = min(samples);
    maximumSeconds(k) = max(samples);
end
disp(table(testName, medianSeconds, minimumSeconds, maximumSeconds))
end

function bytes = processPeakWorkingSet()
bytes = NaN;
if ~ispc
    return
end

try
    process = System.Diagnostics.Process.GetCurrentProcess();
    process.Refresh();
    bytes = double(process.PeakWorkingSet64);
catch
    % Peak working set is optional diagnostic information.
end
end
