testthat::test_that("configuration preserves candidate intent and contextual readiness", {
  CandidateValues <- S7::new_class(
    "CandidateValues",
    properties = list(values = S7::class_double),
    validator = function(self) {
      if (length(self@values) == 0L) {
        "@values must contain at least one candidate"
      }
    }
  )

  probability <- S7::new_property(
    class = S7::class_double,
    validator = function(value) {
      if (length(value) != 1L || !is.finite(value) || value < 0 || value > 1) {
        "must be one finite number between 0 and 1"
      }
    }
  )

  RunSpecification <- S7::new_class(
    "RunSpecification",
    properties = list(
      sampling_rate = probability,
      feature_count = S7::new_union(S7::class_integer, CandidateValues)
    )
  )

  PreparedRun <- S7::new_class(
    "PreparedRun",
    properties = list(
      specification = RunSpecification,
      available_features = S7::class_integer
    )
  )

  prepare_run <- function(specification, available_features) {
    requested <- if (S7::S7_inherits(specification@feature_count, CandidateValues)) {
      specification@feature_count@values
    } else {
      specification@feature_count
    }

    if (any(requested > available_features)) {
      cli::cli_abort(
        "Requested feature counts must not exceed {available_features}.",
        class = "s7_notes_error_context"
      )
    }

    PreparedRun(
      specification = specification,
      available_features = available_features
    )
  }

  fixed <- RunSpecification(sampling_rate = 0.8, feature_count = 3L)
  tuned <- RunSpecification(
    sampling_rate = 0.8,
    feature_count = CandidateValues(values = c(2, 3, 5))
  )

  testthat::expect_identical(fixed@feature_count, 3L)
  testthat::expect_s7_class(tuned@feature_count, CandidateValues)
  testthat::expect_s7_class(prepare_run(tuned, 5L), PreparedRun)
  testthat::expect_error(
    prepare_run(tuned, 4L),
    class = "s7_notes_error_context"
  )
})

testthat::test_that("portable definitions bind capabilities and authority at the host", {
  TaskDefinition <- S7::new_class(
    "TaskDefinition",
    properties = list(
      id = S7::class_character,
      capabilities = S7::class_character,
      requested_limit = S7::class_integer
    )
  )

  AuthorizedTask <- S7::new_class(
    "AuthorizedTask",
    properties = list(
      definition = TaskDefinition,
      capabilities = S7::class_environment,
      granted_limit = S7::class_integer
    )
  )

  bind_task <- function(definition, registry, maximum_limit) {
    missing <- setdiff(definition@capabilities, ls(registry, all.names = TRUE))
    if (length(missing) > 0L) {
      cli::cli_abort(
        "Unknown capabilities: {.val {missing}}.",
        class = "s7_notes_error_capability"
      )
    }

    bound <- new.env(parent = emptyenv())
    for (name in definition@capabilities) {
      bound[[name]] <- registry[[name]]
    }

    AuthorizedTask(
      definition = definition,
      capabilities = bound,
      granted_limit = min(definition@requested_limit, maximum_limit)
    )
  }

  registry <- new.env(parent = emptyenv())
  registry$read_data <- function() "data"
  definition <- TaskDefinition(
    id = "daily-report",
    capabilities = "read_data",
    requested_limit = 10L
  )
  authorized <- bind_task(definition, registry, maximum_limit = 3L)

  testthat::expect_identical(authorized@granted_limit, 3L)
  testthat::expect_identical(authorized@capabilities$read_data(), "data")
  testthat::expect_type(definition@capabilities, "character")
  testthat::expect_false(any(vapply(S7::props(definition), is.function, logical(1))))
})

testthat::test_that("one semantic document supports reference checks and dialect dispatch", {
  identifier_pattern <- "^[A-Za-z_][A-Za-z0-9_]*$"

  identifier <- S7::new_property(
    class = S7::class_character,
    validator = function(value) {
      if (length(value) != 1L || is.na(value)) {
        return("must be one non-missing identifier")
      }
      if (!grepl(identifier_pattern, value)) {
        return("must use portable unquoted SQL identifier syntax")
      }
      NULL
    }
  )

  identifiers <- S7::new_property(
    class = S7::class_character,
    validator = function(value) {
      if (length(value) == 0L || anyNA(value)) {
        return("must contain non-missing identifiers")
      }
      if (!all(grepl(identifier_pattern, value))) {
        return("must use portable unquoted SQL identifier syntax")
      }
      NULL
    }
  )

  Relation <- S7::new_class(
    "Relation",
    properties = list(name = identifier)
  )

  Query <- S7::new_class(
    "Query",
    properties = list(
      from = identifier,
      select = identifiers
    )
  )

  Document <- S7::new_class(
    "Document",
    properties = list(
      relations = S7::class_list,
      query = Query
    ),
    validator = function(self) {
      relation_names <- vapply(
        self@relations,
        function(relation) relation@name,
        character(1)
      )

      if (!self@query@from %in% relation_names) {
        "@query@from must name a declared relation"
      }
    }
  )

  Postgres <- S7::new_class("Postgres")
  SQLite <- S7::new_class("SQLite")
  render_document <- S7::new_generic("render_document", c("document", "dialect"))

  S7::method(render_document, list(Document, Postgres)) <- function(document, dialect) {
    columns <- paste0('"', document@query@select, '"')
    paste0(
      "SELECT ",
      paste(columns, collapse = ", "),
      ' FROM "',
      document@query@from,
      '"'
    )
  }

  S7::method(render_document, list(Document, SQLite)) <- function(document, dialect) {
    columns <- paste0("[", document@query@select, "]")
    paste0(
      "SELECT ",
      paste(columns, collapse = ", "),
      " FROM [",
      document@query@from,
      "]"
    )
  }

  document <- Document(
    relations = list(Relation(name = "observations")),
    query = Query(from = "observations", select = c("id", "value"))
  )

  testthat::expect_identical(
    render_document(document, Postgres()),
    'SELECT "id", "value" FROM "observations"'
  )
  testthat::expect_identical(
    render_document(document, SQLite()),
    "SELECT [id], [value] FROM [observations]"
  )
  testthat::expect_error(
    Document(
      relations = list(Relation(name = "observations")),
      query = Query(from = "missing", select = "id")
    ),
    "must name a declared relation"
  )
  testthat::expect_error(
    Relation(name = 'observations"; DROP TABLE observations; --'),
    "portable unquoted SQL identifier syntax"
  )
  testthat::expect_error(
    Query(from = "observations", select = c("id", "value]")),
    "portable unquoted SQL identifier syntax"
  )
})

testthat::test_that("unknown layer variants remain typed and preserve raw content", {
  Layer <- S7::new_class(
    "Layer",
    abstract = TRUE,
    properties = list(
      id = S7::class_character,
      source = S7::class_character,
      extensions = S7::new_property(S7::class_list, default = list())
    )
  )
  UnknownLayer <- S7::new_class(
    "UnknownLayer",
    parent = Layer,
    properties = list(raw = S7::class_list)
  )
  layer_list <- S7::new_property(
    class = S7::class_list,
    default = list(),
    validator = function(value) {
      valid <- vapply(
        value,
        S7::S7_inherits,
        logical(1),
        class = Layer
      )
      if (!all(valid)) {
        "every element must inherit from Layer"
      }
    }
  )
  Style <- S7::new_class(
    "Style",
    properties = list(
      sources = S7::class_list,
      layers = layer_list
    ),
    validator = function(self) {
      refs <- vapply(self@layers, function(x) x@source, character(1))
      missing_refs <- setdiff(refs, names(self@sources))
      if (length(missing_refs)) {
        "@layers must reference declared sources"
      }
    }
  )

  raw <- list(
    id = "future-layer",
    source = "observations",
    type = "future-heatmap",
    intensity = 0.8
  )
  unknown <- UnknownLayer(
    id = raw$id,
    source = raw$source,
    raw = raw
  )
  document <- Style(
    sources = list(observations = list()),
    layers = list(unknown)
  )

  testthat::expect_identical(document@layers[[1L]]@raw, raw)
  testthat::expect_error(
    Style(
      sources = list(observations = list()),
      layers = list(list(id = "not-a-layer"))
    ),
    "every element must inherit from Layer"
  )
})
