function rscript = findRscript()
%FINDRSCRIPT Locate an Rscript executable for fixture generation.

% Copyright 2026 The MathWorks, Inc.

envValue = string(getenv("RDATA_RSCRIPT"));
candidate = strings(0, 1);
if strlength(envValue) > 0
    candidate(end + 1, 1) = envValue;
end

programFilesR = findProgramFilesRFolder();
if strlength(programFilesR) > 0
    candidate(end + 1, 1) = fullfile(programFilesR, "R-4.6.1", "bin", "Rscript.exe");
end
candidate(end + 1, 1) = "Rscript";

for k = 1:numel(candidate)
    if candidate(k) == "Rscript"
        [status, ~] = system("Rscript --version");
        if status == 0
            rscript = candidate(k);
            return
        end
    elseif isfile(candidate(k))
        rscript = candidate(k);
        return
    end
end

if strlength(programFilesR) > 0 && isfolder(programFilesR)
    matches = dir(fullfile(programFilesR, "R-*", "bin", "Rscript.exe"));
    if ~isempty(matches)
        rscript = string(fullfile(matches(1).folder, matches(1).name));
        return
    end
end

rscript = "";
end

function programFilesR = findProgramFilesRFolder()
programFiles = string(getenv("ProgramFiles"));
if strlength(programFiles) == 0
    programFilesR = "";
else
    programFilesR = fullfile(programFiles, "R");
end
end
