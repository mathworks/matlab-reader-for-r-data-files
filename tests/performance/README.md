# Performance Benchmarks

Run the benchmark suite from the repository root:

```matlab
buildtool("perftest")
```

R&reg; is required to generate the temporary benchmark fixtures. Set
`RDATA_RSCRIPT` if `Rscript` is not on the system path. Fixtures are written
under `tempdir`, not into the repository. The performance tests use fixed
sample counts and do not impose wall-clock pass/fail thresholds.

`memoryObservation` reports the 1,000,000-row table's input size, returned
value and metadata size, MATLAB&reg; process memory before and after import, and
the process peak working set where available. On Windows&reg;, the peak working
set is cumulative for the MATLAB process. Run the benchmark in a fresh MATLAB
session when comparing that value between revisions.

## September 2026 Results

Environment:

- MATLAB R2026a (`26.1.0.3203278`)
- Windows, AMD64 Family 25 Model 68
- 30.8 GB physical memory
- Uncompressed R serialization version 3 fixtures
- Each `timeit` measurement followed one warm-up import
- Baseline: the parser revision immediately before bulk vector decoding

| Workload | Elements/rows | Before (s) | After (s) | Speedup |
| --- | ---: | ---: | ---: | ---: |
| Integer vector | 100,000 | 0.0682 | 0.0048 | 14.2x |
| Integer vector | 1,000,000 | 1.2593 | 0.0189 | 66.6x |
| Real vector | 100,000 | 0.3796 | 0.0062 | 61.6x |
| Real vector | 1,000,000 | 5.0833 | 0.0340 | 149.3x |
| Complex vector | 100,000 | 0.7149 | 0.0119 | 60.2x |
| Complex vector | 1,000,000 | 11.1785 | 0.0717 | 155.9x |
| Numeric data frame | 1,000,000 | 7.9691 | 0.2438 | 32.7x |

The post-change fixed-sample performance run completed all seven benchmark
points successfully. Its 1,000,000-row table observation recorded a 15.26 MB
input file and 70.59 MB returned table plus metadata. MATLAB memory increased
by 23.9 MB after the import. The process peak working set remained at the
session's prior 2081.7 MB high-water mark, so that run did not establish a new
isolated peak.

The before/after table used the same generated fixtures and equivalent commands
before and after bulk vector decoding:

```matlab
root = fullfile(tempdir, "matlab-r-reader-benchmarks");
files = [
    "integer_100000.rds"
    "integer_1000000.rds"
    "real_100000.rds"
    "real_1000000.rds"
    "complex_100000.rds"
    "complex_1000000.rds"
    "table_1000000.rds"
];
for k = 1:numel(files)
    filename = fullfile(root, files(k));
    readrds(filename); % Warm up.
    fprintf("%s %.6f s\n", files(k), timeit(@() readrds(filename)));
end
```

The `perftest` build task uses `matlab.perftest.TimeExperiment` for repeatable
ongoing measurements; the table above records the separate before/after
`timeit` comparison.

<!-- Copyright 2026 The MathWorks, Inc. -->
