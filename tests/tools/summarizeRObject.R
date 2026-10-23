# Copyright 2026 The MathWorks, Inc.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: summarizeRObject.R <rds-or-rdata-file> <output-json>")
}

json_escape <- function(x) {
    x <- gsub("\\\\", "\\\\\\\\", x)
    x <- gsub("\"", "\\\\\"", x)
    x <- gsub("\n", "\\\\n", x)
    x
}

json_string <- function(x) {
    if (length(x) == 0) {
        return("[]")
    }
    paste0("[", paste0("\"", json_escape(as.character(x)), "\"", collapse = ","), "]")
}

json_number <- function(x) {
    if (length(x) == 0 || is.null(x)) {
        return("[]")
    }
    paste0("[", paste(as.character(as.numeric(x)), collapse = ","), "]")
}

missing_count <- function(x) {
    result <- tryCatch(sum(is.na(x)), error = function(e) NA_integer_)
    as.integer(result)
}

summarize_object <- function(name, object) {
    object_dim <- dim(object)
    object_names <- names(object)
    object_class <- class(object)
    paste0(
        "{",
        "\"name\":\"", json_escape(name), "\",",
        "\"typeof\":\"", json_escape(typeof(object)), "\",",
        "\"class\":", json_string(object_class), ",",
        "\"length\":", length(object), ",",
        "\"dim\":", json_number(object_dim), ",",
        "\"names\":", json_string(object_names), ",",
        "\"missingCount\":", missing_count(object),
        "}"
    )
}

input <- args[[1]]
output <- args[[2]]
if (grepl("\\.[rR][dD][sS]$", input)) {
    objects <- list(value = readRDS(input))
} else {
    env <- new.env(parent = emptyenv())
    load(input, envir = env)
    object_names <- ls(env)
    objects <- mget(object_names, envir = env)
}

summaries <- character(length(objects))
for (i in seq_along(objects)) {
    summaries[[i]] <- summarize_object(names(objects)[[i]], objects[[i]])
}

json <- paste0(
    "{",
    "\"schemaVersion\":1,",
    "\"source\":\"", json_escape(normalizePath(input, winslash = "/", mustWork = FALSE)), "\",",
    "\"objects\":[", paste(summaries, collapse = ","), "]",
    "}"
)
writeLines(json, output, useBytes = TRUE)
