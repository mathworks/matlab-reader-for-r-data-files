function fixtureRoot = generateBenchmarkFixtures(outputFolder, options)
%GENERATEBENCHMARKFIXTURES Generate large R fixtures outside the repository.

% Copyright 2026 The MathWorks, Inc.

arguments
    outputFolder (1,1) string = fullfile(tempdir, "matlab-r-reader-benchmarks")
    options.Force (1,1) logical = false
end

requiredFiles = [
    "integer_100000.rds"
    "integer_1000000.rds"
    "real_100000.rds"
    "real_1000000.rds"
    "complex_100000.rds"
    "complex_1000000.rds"
    "table_1000000.rds"
];
fixtureRoot = outputFolder;
if ~options.Force && all(isfile(fullfile(fixtureRoot, requiredFiles)))
    return
end

rscript = rdata.test.findRscript();
if strlength(rscript) == 0
    error("rdata:MissingRscript", ...
        "Rscript is required to generate benchmark fixtures. Set RDATA_RSCRIPT to its executable.")
end

projectRoot = currentProject().RootFolder;
scriptFile = fullfile(projectRoot, "tests", "performance", "generateBenchmarkFixtures.R");
command = rdata.test.quoteCommandArgument(rscript) + " " + ...
    rdata.test.quoteCommandArgument(scriptFile) + " " + ...
    rdata.test.quoteCommandArgument(fixtureRoot);
[status, output] = system(command);
if status ~= 0
    error("rdata:FixtureGenerationFailed", ...
        "R benchmark fixture generation failed with status %d: %s", status, output)
end
end
