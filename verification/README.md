# Verification

Most book examples remain static so rendering stays fast and deterministic;
the grouped-replacement example in Chapter 2 executes during rendering. This
directory provides broader executable checks for claims whose truth depends
on S7 or R behavior.

Run the suite from the repository root:

```sh
Rscript verification/verify.R
```

The tests cover:

- validator diagnostics and invocation counts;
- grouped replacement and value semantics;
- dynamic getters and reference-valued properties;
- serialized class specifications;
- the configuration, capability-binding, and document-dispatch examples.

The publish workflow runs these checks before rendering and deploying the
book. Version-sensitive claims in the prose should identify the R and S7
versions against which they were checked.
