# Copyright 2026 The MathWorks, Inc.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
    stop("Usage: generateBenchmarkFixtures.R <output-folder>")
}

root <- normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
dir.create(root, recursive = TRUE, showWarnings = FALSE)

write_vector <- function(type, n, value) {
    filename <- sprintf("%s_%d.rds", type, n)
    saveRDS(value, file.path(root, filename), compress = FALSE, version = 3)
}

for (n in c(100000L, 1000000L)) {
    write_vector("integer", n, rep(c(1L, -2L, NA_integer_, 4L), length.out = n))
    write_vector("real", n, rep(c(1.5, NA_real_, NaN, Inf, -Inf), length.out = n))
    write_vector("complex", n, rep(c(1 + 2i, NA_complex_, NaN + 3i), length.out = n))
}

n <- 1000000L
large_table <- data.frame(
    id = rep(c(1L, 2L, NA_integer_, 4L), length.out = n),
    value = rep(c(1.5, NA_real_, NaN, Inf, -Inf), length.out = n),
    flag = rep(c(TRUE, FALSE, NA), length.out = n)
)
saveRDS(large_table, file.path(root, "table_1000000.rds"),
        compress = FALSE, version = 3)
