# Vendored coq-menhirlib (Menhir 20250903)

Source: extracted from the Menhir 20250903 release tarball
(https://gitlab.inria.fr/fpottier/menhir/-/archive/20250903/menhir-20250903.zip),
`coq-menhirlib/src/` directory.

## Why vendored?

`coq-menhirlib` is not packaged for Coq 8.9 in nixpkgs. The `ocamlPackages.menhir`
nix package contains only the OCaml `menhirLib`, not the Coq library. The Coq
sources must be obtained separately from the Menhir source distribution.

## Coq 8.9 compatibility

The library compiles cleanly under Coq 8.9.1 with no source modifications.
However, the `_CoqProject` in this directory is NOT used by the parent build;
the parent `_CoqProject` includes these files with:

```
-R vendor/menhirlib MenhirLib
```

and adds `-undeclared-scope` to the warning flags.

The generated parser (`*.vy` → `*.v` via `menhir --coq`) must use
`--coq-no-version-check` to skip the `Version.require_20250903` check that
would reject Coq 8.9. See issue #3 for details.