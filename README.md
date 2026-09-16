# S7 Design Notes

Doctrine, field guide, and playbooks for functional OOP in R with
[S7](https://rconsortium.github.io/S7/).

**Read online:** <https://jimbrig.github.io/s7-design-notes/>

Working notes on designing object systems with S7 — types, values,
validation, dispatch, composition, documents, schemas, and the craft of
deciding among them. Opinionated and technically grounded: mechanics are
verified against a live R session (S7 0.2.2, R 4.6.1), patterns are drawn
from a survey of the real S7 ecosystem (ellmer, ragnar, quickr, rtemis,
sqlr, stacbuildr, resultr, and a dozen more), and the recommendations are
written as strong defaults, not laws.

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
- **Appendices** — an inquiry ledger of open questions, and sources.

## Building locally

The book is built with [Quarto](https://quarto.org). No R execution is
required to render (code blocks are static and verified separately):

```sh
quarto render
quarto preview
```

## Contributing

Corrections, counterexamples, and second sightings of single-source
patterns are especially welcome — open an issue or a pull request.

## License

MIT. See [LICENSE](LICENSE).
