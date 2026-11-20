function summary = verifyInstalledToolbox(packageFile)
%verifyInstalledToolbox - Validate an installed toolbox in a fresh session
%   SUMMARY = verifyInstalledToolbox(packageFile) installs the package,
%   imports synthetic fixtures, and removes the installation from the path.
%   Run after runValidation has generated the fixtures, in a fresh MATLAB
%   session with no project open and no reader functions on the path.
%
%   See also runValidation, readrds, readrdata, rdata2table, rdatainfo

% Copyright 2026 The MathWorks, Inc.

arguments
    packageFile (1,1) string {mustBeFile}
end

root = fileparts(fileparts(mfilename("fullpath")));
assert(isempty(matlab.project.rootProject), ...
    "rdata:ProjectOpen", "Close the source project before testing installation.")
assert(isempty(which("readrds")), ...
    "rdata:ReaderAlreadyOnPath", "Start with no reader installation on the path.")

if isMATLABReleaseOlderThan("R2026b")
    installed = matlab.addons.toolbox.installToolbox(packageFile);
    cleanup = onCleanup(@() matlab.addons.toolbox.uninstallToolbox(installed));
else
    mpminstall(packageFile, Prompt=false);
    cleanup = onCleanup(@() mpmuninstall("rdatareader", Prompt=false));
end

functionFile = string(which("readrds"));
assert(strlength(functionFile) > 0 && ...
    ~startsWith(functionFile, string(root) + filesep), ...
    "rdata:WrongInstallation", "Reader must resolve outside the source checkout.")

fixtures = fullfile(root, "tests", "testdata", "synthetic");
rdsFile = fullfile(fixtures, "rds", "simple_data_frame.rds");
rdataFile = fullfile(fixtures, "rdata", "single_table_workspace.rda");
value = readrds(rdsFile);
workspace = readrdata(rdataFile);
converted = rdata2table(rdataFile);
info = rdatainfo(rdataFile);
assert(istable(value) && isequal(size(value), [3 5]))
assert(isequaln(value.id, [10; 20; NaN]))
assert(isa(workspace, "dictionary") && numEntries(workspace) == 1)
assert(isequaln(value, converted))
assert(info.FileType == "RData" && height(info.Objects) == 1)

summary = struct(Release=version("-release"), Build=version, ...
    InstalledFunction=functionFile, Passed=true);
reportFolder = fullfile(root, "public");
if ~isfolder(reportFolder)
    mkdir(reportFolder)
end
fileId = fopen(fullfile(reportFolder, "installed-toolbox.json"), "w", "n", "UTF-8");
assert(fileId >= 0, "rdata:ReportWrite", "Unable to write installation report.")
fileCleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s\n", jsonencode(summary, PrettyPrint=true));
disp(summary)
end
