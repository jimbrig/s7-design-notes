if (!requireNamespace("S7", quietly = TRUE)) {
  cli::cli_abort("Package {.pkg S7} is required to verify the book.")
}

if (!requireNamespace("testthat", quietly = TRUE)) {
  cli::cli_abort("Package {.pkg testthat} is required to verify the book.")
}

expected_r <- "4.6.1"
expected_s7 <- "0.2.2"
actual_r <- as.character(getRversion())
actual_s7 <- as.character(utils::packageVersion("S7"))

if (!identical(actual_r, expected_r) || !identical(actual_s7, expected_s7)) {
  cli::cli_abort(c(
    "Verification requires the book's evidence baseline.",
    "i" = "Expected R {expected_r} and S7 {expected_s7}.",
    "x" = "Found R {actual_r} and S7 {actual_s7}."
  ))
}

cli::cli_alert_info(
  "Verifying with R {actual_r} and S7 {actual_s7}."
)

testthat::test_dir(
  "verification",
  reporter = "summary",
  stop_on_failure = TRUE,
  stop_on_warning = TRUE
)

cli::cli_alert_success("S7 mechanics and worked examples verified.")
