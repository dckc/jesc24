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

## Parser unit tests

Parser "unit tests" are written as `Example`s in
`theories/jessie/jessie_test.v` (Jessie modules), `justin_test.v` (expressions),
and `json_test.v` (JSON). When extending the grammar in `jesc_parser.vy` or the
lexer in `jesc_lexer.v`, add a small red `Example` for the new construct first,
then make it green by extending the grammar/lexer. See the makeCounterZone
tests (`test_bigint_literal`, `test_destructuring`, `test_top_level_void`,
`test_method_shorthand`, `test_default_param`, `test_member_assign`) as the
template.

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
