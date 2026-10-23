# Copyright 2026 The MathWorks, Inc.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
    stop("Usage: generateSyntheticFixtures.R <output-folder>")
}

root <- normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
dir.create(root, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "rds"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "rdata"), recursive = TRUE, showWarnings = FALSE)

set.seed(1729)

write_rds <- function(id, value, compress = FALSE) {
    saveRDS(value, file.path(root, "rds", paste0(id, ".rds")),
            compress = compress, version = 3)
}

write_workspace <- function(id, values, compress = FALSE) {
    env <- new.env(parent = emptyenv())
    for (name in names(values)) {
        assign(name, values[[name]], envir = env)
    }
    save(list = names(values), file = file.path(root, "rdata", paste0(id, ".rda")),
         envir = env, compress = compress, version = 3)
}

logical_vector <- c(TRUE, FALSE, NA)
integer_vector <- c(-10L, 0L, 25L, NA_integer_, 100L)
real_vector <- c(1.5, NA_real_, NaN, Inf, -Inf, -0)
complex_vector <- c(1 + 2i, NA_complex_, NaN + 3i)
raw_vector <- as.raw(c(0, 1, 127, 128, 255))
character_empty_vector <- c("", NA_character_)
e_acute <- intToUtf8(0x00E9)
character_vector <- c("abc", NA_character_, enc2utf8(e_acute))
latin1_vector <- iconv(e_acute, from = "UTF-8", to = "latin1")
Encoding(latin1_vector) <- "latin1"
bytes_vector <- rawToChar(as.raw(c(0x80, 0x81)))
Encoding(bytes_vector) <- "bytes"
named_integer <- c(alpha = 10L, beta = NA_integer_)
numeric_matrix <- matrix(c(1.5, NA_real_, 3, 4, 5, 6), nrow = 2, ncol = 3,
                         dimnames = list(c("r1", "r2"), c("c1", "c2", "c3")))
array_3d <- array(as.numeric(c(1, 2, 3, 4, 5, 6, 7, 8)), dim = c(2, 2, 2))
simple_factor <- factor(c("low", "medium", NA, "high", "low"),
                        levels = c("low", "medium", "high"))
ordered_factor <- ordered(c("small", "large", "medium", NA),
                          levels = c("small", "medium", "large"))
simple_data_frame <- data.frame(
    id = c(10L, 20L, NA_integer_),
    value = c(1.5, NA_real_, 3),
    flag = c(TRUE, FALSE, NA),
    group = factor(c("a", "b", NA), levels = c("a", "b", "c")),
    text = c("alpha", NA_character_, "gamma"),
    stringsAsFactors = FALSE
)
invalid_name_data_frame <- data.frame(
    c(1, 2),
    c(3, 4),
    check.names = FALSE
)
names(invalid_name_data_frame) <- c("bad-name", "bad/name")
implicit_columns_data_frame <- structure(
    list(c(1L, 2L), c("a", "b")),
    class = "data.frame",
    row.names = c(NA_integer_, -2L)
)
tibble_like <- simple_data_frame
class(tibble_like) <- c("tbl_df", "tbl", "data.frame")
date_vector <- as.Date(c("2020-01-01", NA, "1970-01-01"))
posixct_utc <- as.POSIXct(c("2020-01-01 12:30:00", NA, "1970-01-01 00:00:00"),
                          tz = "UTC")
posixct_london <- as.POSIXct(c("2024-03-31 00:30:00", "2024-03-31 02:30:00"),
                             tz = "Europe/London")
difftime_seconds <- as.difftime(c(30, NA, 3600), units = "secs")
posixlt_object <- as.POSIXlt(as.POSIXct("2020-01-01 00:00:00", tz = "UTC"))
unnamed_list <- list(c(1.5, NA_real_), c("x", NA_character_), NULL)
named_list <- list(first = c(1L, NA_integer_), second = c("a", "b"))
nested_list <- list(outer = list(inner = c(TRUE, NA)), value = 42)
list_with_data_frame <- list(frame = simple_data_frame)
invalid_name_list <- list(c(1, 2), c(3, 4))
names(invalid_name_list) <- c("bad-name", "bad/name")
altrep_sequence <- 1:3
function_object <- function(x) x + 1
list_with_function <- list(ok = c(1L, 2L), bad = function(x) x + 1)
formula_object <- y ~ x

write_rds("logical_vector", logical_vector)
write_rds("integer_vector", integer_vector)
write_rds("real_vector", real_vector)
write_rds("complex_vector", complex_vector)
write_rds("raw_vector", raw_vector)
write_rds("character_vector", character_vector)
write_rds("character_empty_vector", character_empty_vector)
write_rds("latin1_vector", latin1_vector)
write_rds("bytes_vector", bytes_vector)
write_rds("named_integer", named_integer)
write_rds("numeric_matrix", numeric_matrix)
write_rds("array_3d", array_3d)
write_rds("simple_factor", simple_factor)
write_rds("ordered_factor", ordered_factor)
write_rds("simple_data_frame", simple_data_frame)
write_rds("invalid_name_data_frame", invalid_name_data_frame)
write_rds("implicit_columns_data_frame", implicit_columns_data_frame)
duplicate_columns <- data.frame(x = c(1, 2), x = c(3, 4), check.names = FALSE)
write_rds("duplicate_columns", duplicate_columns)
write_rds("duplicate_list", list(x = 1, x = 2))
write_rds("nested_duplicate_list", list(outer = list(x = 1, x = 2)))
reserved_column <- data.frame(c(1, 2), check.names = FALSE)
names(reserved_column) <- ":"
write_rds("reserved_column", reserved_column)
names(reserved_column) <- "Properties"
write_rds("properties_column", reserved_column)
names(reserved_column) <- ""
write_rds("empty_column", reserved_column)
write_rds("timetable_metadata", data.frame(
    Time = as.Date(c("2020-01-01", "2020-01-02")), flag = c(NA, TRUE)))
write_rds("timetable_custom_time", data.frame(
    before = c(NA_integer_, 2L),
    When = as.POSIXct(c("2020-01-01", "2020-01-02"), tz = "UTC"),
    after = c(TRUE, NA)))
x <- c(1, 2)
save(list = c("x", "x"), file = file.path(root, "rdata", "duplicate_workspace.rda"),
     compress = FALSE, version = 3)
write_rds("tibble_like", tibble_like)
write_rds("date_vector", date_vector)
write_rds("posixct_utc", posixct_utc)
write_rds("posixct_london", posixct_london)
write_rds("difftime_seconds", difftime_seconds)
write_rds("posixlt_object", posixlt_object)
write_rds("unnamed_list", unnamed_list)
write_rds("named_list", named_list)
write_rds("nested_list", nested_list)
write_rds("list_with_data_frame", list_with_data_frame)
write_rds("invalid_name_list", invalid_name_list)
write_rds("altrep_sequence", altrep_sequence)
write_rds("function_object", function_object)
write_rds("list_with_function", list_with_function)
write_rds("formula_object", formula_object)
write_rds("base_environment", baseenv())
write_rds("empty_environment", emptyenv())
write_rds("global_environment", globalenv())
write_rds("integer_vector_gzip", integer_vector, compress = "gzip")
saveRDS(integer_vector, file.path(root, "rds", "integer_vector_v2.rds"),
        compress = FALSE, version = 2)
xInt <- c(11L, 22L, NA_integer_)
save(xInt, file = file.path(root, "rdata", "primitive_workspace_v2.rda"),
     compress = FALSE, version = 2)
write_rds("integer_vector_bzip2", integer_vector, compress = "bzip2")
write_rds("integer_vector_xz", integer_vector, compress = "xz")
saveRDS(integer_vector, file.path(root, "rds", "integer_vector_ascii.rds"),
        ascii = TRUE, compress = FALSE, version = 3)

write_workspace("primitive_workspace", list(
    xInt = c(11L, 22L, NA_integer_),
    xText = c("aa", NA_character_, "bb"),
    xReal = c(1.25, NA_real_, NaN),
    xTable = simple_data_frame
))

write_workspace("single_table_workspace", list(
    xTable = simple_data_frame
))

write_workspace("primitive_workspace_gzip", list(
    xInt = c(11L, 22L, NA_integer_),
    xText = c("aa", NA_character_, "bb")
), compress = "gzip")

json_escape <- function(value) {
    gsub('"', '\\"', value, fixed = TRUE)
}

manifest_entries <- character()
rds_files <- sort(basename(list.files(file.path(root, "rds"), pattern = "\\.rds$")))
for (filename in rds_files) {
    id <- sub("\\.rds$", "", filename)
    path <- file.path("rds", filename)
    path <- gsub("\\\\", "/", path)
    manifest_entries <- c(
        manifest_entries,
        sprintf("    {\"id\": \"%s\", \"type\": \"rds\", \"path\": \"%s\"}",
                json_escape(id), json_escape(path))
    )
}

rdata_files <- sort(basename(list.files(file.path(root, "rdata"), pattern = "\\.rda$")))
for (filename in rdata_files) {
    id <- sub("\\.rda$", "", filename)
    path <- file.path("rdata", filename)
    path <- gsub("\\\\", "/", path)
    manifest_entries <- c(
        manifest_entries,
        sprintf("    {\"id\": \"%s\", \"type\": \"rdata\", \"path\": \"%s\"}",
                json_escape(id), json_escape(path))
    )
}

if (length(manifest_entries) > 1) {
    manifest_entries[-length(manifest_entries)] <- paste0(manifest_entries[-length(manifest_entries)], ",")
}

manifest <- file.path(root, "manifest.json")
writeLines(c(
    "{",
    "  \"schemaVersion\": 1,",
    "  \"copyright\": \"Copyright 2026 The MathWorks, Inc.\",",
    "  \"description\": \"Synthetic fixtures generated by tests/tools/generateSyntheticFixtures.R\",",
    "  \"fixtures\": [",
    manifest_entries,
    "  ]",
    "}"
), manifest, useBytes = TRUE)
