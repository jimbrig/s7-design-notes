# S7 Design Notes

[![Publish](https://github.com/jimbrig/s7-design-notes/actions/workflows/publish.yml/badge.svg)](https://github.com/jimbrig/s7-design-notes/actions/workflows/publish.yml)

Meaningful values, explicit contracts, and composable operations in R with
[S7](https://rconsortium.github.io/S7/).

**Read online:** <https://docs.jimbrig.com/s7-design-notes/>

A design guide to making domain concepts, valid states, and operations
explicit with S7. The recommendations are opinionated defaults grounded in
documented mechanics, executable probes, public package evidence, and stated
counterexamples.

## Contents

- **Overview** — the whole argument in ten theses.
- **Foundations** — what kind of OOP S7 is; value semantics and state;
  semantic types and type-driven design.
- **Laws and Composition** — parse-don't-validate and the checking ladder;
  sum types, inheritance, interfaces, and dispatch; documents, schemas,
  and the AST escalation ladder.
- **Evidence** — an ecosystem field guide: what real S7 packages teach.
- **Practice** — the doctrine (principles, decision guides, anti-patterns);
  situation-indexed playbooks; and the middlegame, with a fully annotated
  design derivation.
- **Appendices** — an inquiry ledger of open questions, a glossary, and
  public sources.

## Building locally

The book is built with Quarto 1.10.18. Most code blocks are explanatory;
selected examples execute during rendering, and a separate verification suite
checks S7 mechanics and recurring examples against R 4.6.1 and S7 0.2.2.

```sh
Rscript verification/verify.R
quarto render
```

Use `quarto preview` for local editing. Pushes to `main` run the verification
suite, render the book, and publish `_book/` to the `gh-pages` branch.

## Contributing

Corrections, counterexamples, and public examples that strengthen or challenge
the design guidance are especially welcome.

## License

MIT. See [LICENSE](LICENSE).
