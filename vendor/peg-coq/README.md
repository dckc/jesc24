# peg-coq (vendored)

From <https://github.com/guidanoli/peg-coq> by Guilherme Dantas,
licensed under [GPL-3.0](LICENSE).

We vendor only the 5 theories files needed for our Jessie parser:
`Charset.v`, `Match.v`, `Suffix.v`, `Syntax.v`, `Tactics.v`.

`Match.v` is adapted for Coq 8.9: `Nat.le_add_r` / `Nat.le_add_l`
are replaced with `lia` proofs (see the diff in this commit).