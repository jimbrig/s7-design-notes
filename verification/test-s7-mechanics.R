testthat::test_that("validators can report multiple problems", {
  bounded_number <- S7::new_property(
    class = S7::class_double,
    validator = function(value) {
      problems <- character()

      if (length(value) != 1L) {
        problems <- c(problems, "must be scalar")
      }
      if (any(!is.finite(value))) {
        problems <- c(problems, "must be finite")
      }

      problems
    }
  )

  Measurement <- S7::new_class(
    "Measurement",
    properties = list(value = bounded_number)
  )

  condition <- rlang::catch_cnd(Measurement(value = c(Inf, 1)))

  testthat::expect_match(conditionMessage(condition), "must be scalar")
  testthat::expect_match(conditionMessage(condition), "must be finite")
})

testthat::test_that("grouped replacement validates once and preserves aliases", {
  counts <- new.env(parent = emptyenv())
  counts$validations <- 0L

  Interval <- S7::new_class(
    "Interval",
    properties = list(
      lower = S7::class_double,
      upper = S7::class_double
    ),
    validator = function(self) {
      counts$validations <- counts$validations + 1L

      if (self@lower > self@upper) {
        "@lower must not exceed @upper"
      }
    }
  )

  original <- Interval(lower = 1, upper = 3)
  alias <- original
  before <- counts$validations

  revised <- S7::set_props(original, lower = 4, upper = 6)

  testthat::expect_equal(counts$validations - before, 1L)
  testthat::expect_equal(alias@lower, 1)
  testthat::expect_equal(alias@upper, 3)
  testthat::expect_equal(revised@lower, 4)
  testthat::expect_equal(revised@upper, 6)
})

testthat::test_that("dynamic getter results are not property-type validated", {
  DerivedValue <- S7::new_class(
    "DerivedValue",
    properties = list(
      source = S7::class_character,
      derived = S7::new_property(
        class = S7::class_double,
        getter = function(self) self@source
      )
    )
  )

  object <- DerivedValue(source = "not a double")

  testthat::expect_identical(object@derived, "not a double")
})

testthat::test_that("reference-valued properties can change behind the boundary", {
  CacheOwner <- S7::new_class(
    "CacheOwner",
    properties = list(cache = S7::class_environment),
    validator = function(self) {
      if (!is.numeric(self@cache$value)) {
        "@cache$value must be numeric"
      }
    }
  )

  cache <- new.env(parent = emptyenv())
  cache$value <- 1
  object <- CacheOwner(cache = cache)

  cache$value <- "changed without property replacement"

  testthat::expect_identical(object@cache$value, "changed without property replacement")
  testthat::expect_error(S7::validate(object), "must be numeric")
})

testthat::test_that("serialized objects retain their class specification", {
  Versioned <- S7::new_class(
    "Versioned",
    properties = list(value = S7::class_character)
  )
  object <- Versioned(value = "old")
  path <- withr::local_tempfile(fileext = ".rds")

  saveRDS(object, path)

  Versioned <- S7::new_class(
    "Versioned",
    properties = list(
      value = S7::class_character,
      revision = S7::class_integer
    )
  )
  restored <- readRDS(path)

  testthat::expect_false(identical(S7::S7_class(restored), Versioned))
  testthat::expect_false("revision" %in% names(S7::props(restored)))
})

testthat::test_that("the documented email property rejects whitespace", {
  email <- S7::new_property(
    class = S7::class_character,
    validator = function(value) {
      if (length(value) != 1L) {
        return("must be a single string")
      }
      if (!grepl("^[^@[:space:]]+@[^@[:space:]]+$", value)) {
        return("must be an email address")
      }
      NULL
    }
  )

  Contact <- S7::new_class(
    "Contact",
    properties = list(email = email)
  )

  testthat::expect_silent(Contact(email = "person@example.com"))
  testthat::expect_error(Contact(email = "person name@example.com"))
})

testthat::test_that("union order determines an implicit property default", {
  IntegerFirst <- S7::new_class(
    "IntegerFirst",
    properties = list(
      value = S7::new_union(S7::class_integer, S7::class_character)
    )
  )
  CharacterFirst <- S7::new_class(
    "CharacterFirst",
    properties = list(
      value = S7::new_union(S7::class_character, S7::class_integer)
    )
  )

  testthat::expect_type(IntegerFirst()@value, "integer")
  testthat::expect_type(CharacterFirst()@value, "character")
})
