## Build with coq 8.9 using nix

Following the 2017 OCPL work, we use coq 8.9.x from 2019:

```
nix develop --command make -j"$(nproc)"
```

Note `make` rules to
- `%_js.v: %.js` - capture `.js` sources as constants in `.v` files
- `%_parser.v: %_parser.vy` - generate coq parser from menhir grammar
  - `menhir` comes from the `nix develop` shell
  - the Coq `MenhirLib` library it generates against is the vendored `vendor/menhirlib`

`_CoqProject` lists the generated modules directly, so a clean checkout should
start from top-level `make`, not from a direct `coq_makefile -f _CoqProject`
or single-file `coqc` invocation.

## Commit Discipline

Use git commit messages as the running lab notebook.

- Docs in .md are for relatively stable argument and status summary.
- Commit whenever there is a coherent thought worth preserving.
- That includes:
  - working increments
  - clarified invariants
  - proof decompositions
  - informative backtracks

The point is to leave proof breadcrumbs in the history rather than turning docs
note into ever-growing scratchpads.

### retcon - retroactive continuity

When a line of exploration has reached its goal, it's often best to
use retroactive continuity for the final git history.

see [retcon skill](https://github.com/kriscendobot/garden/blob/main/skills/retcon/SKILL.md)
