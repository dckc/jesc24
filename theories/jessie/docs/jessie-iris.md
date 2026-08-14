# Jessie In Iris for Robust Safety

HackMD-style slide notes for this Jessie / OCPL / Iris work.

---

## A First Problem

Befor approaching the whole escrow contract, let's start with `makeCounter`:

```js
const makeCounter = () => {
  let count = 0;
  return harden({
    incr: () => (count += 1),
    decr: () => (count -= 1),
  });
};
```

- Goal: state and prove a separation-of-duties claim for this Jessie-flavored
  `makeCounter` example.
- `makeCounter()` returns two methods closing over one hidden cell.
- The security question is whether one method can be handed out without also
  handing out the other.
- This note is part of a spike on correct-by-construction Zoe2 Escrow:
  <https://github.com/Agoric/agoric-sdk/pull/8184>

> Speaker notes:
> Start at the ocap level. The audience should first see the programming model,
> the authority split, and the security claim.

---

## Separation Of Duties

```js
const c = makeCounter();
const cUp = { incr: c.incr };
attacker(cUp);
assert(c.incr() > 0);
```

- `c` is the original counter object.
- `cUp` is the restricted capability object that carries only upward authority.
- Main claim: after any allowed attacker code runs on `cUp`, a direct call to
  the original `c.incr()` still returns a positive number.
- Put differently: the final assertion still succeeds after linking trusted
  code with attacker-controlled code.

> Speaker notes:
> This is the presentation-level theorem. It is deliberately stated on
> `c.incr()`, not on hidden cells, reachability graphs, or proof predicates.

---

## What Must Be Shown

- The attacker can use the authority it was given.
- The attacker cannot synthesize `decr` authority from `cUp`.
- Therefore attacker code cannot drive the hidden counter cell downward.
- One more direct `c.incr()` call must then return something `> 0`.

---

## A Prior Formal Starting Point

- In their 2017 work, Swasey, Garg, and Dreyer reason about object
  capabilities using OCPL, a language and formalism built to prove robust
  safety properties.
- The key pattern is the one needed here:
  verified code linked against attacker-controlled code, with a safety
  property that should survive the linking.
- That makes OCPL the right prior starting point for this project.

Reference:
Swasey, Garg, Dreyer, ["Robust and Compositional Verification of Object Capability Patterns"][2017-ocpl] (OOPSLA 2017).

[2017-ocpl]: https://www.mpi-sws.org/~dreyer/papers/ocpl/paper.pdf

---

## Iris As Proof Foundation

- Iris is a Coq framework for machine-checked proofs about stateful and
  concurrent programs.
- It is a good fit for reasoning about hidden references, higher-order
  functions, event-loop concurrency, and attacker-controlled linking.
- HeapLang is the small ML-like language that ships with Iris and is used for
  many Iris case studies, including this one.

Reference:
Krebbers, Jung, Bizjak, Jourdan, Dreyer, Birkedal,
["The Essence of Higher-Order Concurrent Separation Logic"][2017-iris] (ESOP 2017).

[2017-iris]: https://iris-project.org/pdfs/2017-esop-iris3-final.pdf

---

## Current Proof Stack

1. OCPL robust-safety infrastructure
2. A small Jessie fragment parser and lowering
3. A counter case study and robust-safety proof

> Speaker notes:
> The important point here is that the project now has both a source-facing
> fragment and a proved core example. The remaining gap is the bridge between
> the source-shaped checked client and the proof-oriented client term.

---

## Layer 1: OCPL Robust Safety

The active proof line uses the open source [OCPL development](https://gitlab.mpi-sws.org/FCS/ocpl-coq) (`922c0f4c` using Coq 8.9.1 from 2019) as its semantic base.

It provides:

- attacker values and attacker code
- one-hole attacker contexts
- a semantic compatibility discipline for linking trusted and attacker code
- a robust-safety theorem pattern for proving that a property survives linking

This is the part that turns a local counter argument into a contextual theorem.

---

## Layer 2: Jessie Fragment

The current Jessie fragment (`jessie_parse.v`) is intentionally small, but it is real.

It includes:

- object literals
- property access
- arrow functions, calls
- `const`, `let`, expression statements, `assert`, and `return`

This fragment is enough to parse and lower the `makeCounter` code.

---

## Jessie Parser, AST, and Heap Lang translation

The running example is also represented as source and lowered target terms:

```coq
Definition makeCounter_source : string := ...

Definition make_counter : val := ...

Lemma parse_makeCounter_source_program_term :
  compile_parsed_program_expr makeCounter_source =
  Some makeCounter_program_term.
```

- `makeCounter_source` is the Jessie-facing source
  strings for the running example.
- `make_counter` is the HeapLang counter constructor.
- `makeCounter_program_term` is the lowered top-level program that binds
  `makeCounter`.

> Speaker notes:
> This slide is about representation, not the theorem itself: source strings,
> lowered terms, and the parse/compile bridge.

---

## Layer 3: Counter Case Study

The counter case study contains:

- a HeapLang `make_counter`
- a source-shaped Jessie program for `makeCounter`
- a source-shaped Jessie checked client with `c`, `cUp`, `attacker(cUp)`, and
  the final assertion
- parse-and-lower theorems connecting those source strings to HeapLang terms
- a robust-safety proof for a narrower proof-oriented client term

The proof term is narrower than the parsed checked client because it still
passes the exported increment closure directly in one place where the
source-shaped version would keep the one-field object.

> Speaker notes:
> This is the important current-status slide. The project no longer starts from
> handwritten core terms alone; it already has a small source fragment feeding
> the example.

---

## Separation Of Duties Theorem

Recall the premise and conclusion in Jessie/JS:

```js
const c = makeCounter(); const cUp = { incr: c.incr }; attacker(cUp);
assert(c.incr() > 0);
```

In OCPL / Iris / Coq, `checked_counter` is defined as a rough HeapLang translation* of the above, and `checked_counter_safe` is the robust-safety theorem (lemma), building on `checked_counter_spec`:

```coq
Definition checked_counter : expr :=
  let: "c" := make_counter () in
  let: "cUpIncr" := obj_get "c" incr_key in
  let: "use" := (λ: "cUpIncr",
    rec: "use" <> :=
      let: "n" := "cUpIncr" () in
      assert: (#0 < "n")) "cUpIncr" in
  ("use", "cUpIncr").

Lemma checked_counter_spec :
  {{{ heap_ctx }}} checked_counter {{{ v, RET v; low v }}}.
```

- `low v` means `v` is widely-shareable.
- `{{{ P }}} e {{{ v, RET v; Q }}}` means:
  if the precondition `P` holds before running program `e`,
  then `e` runs safely and if it returns,
  then the postcondition `Q` holds afterward, with `v` bound to the return value.
- `heap_ctx` is the standard HeapLang heap invariant: the state is good, low
  locations contain low values, and heap locations are properly tracked.

```coq
Lemma checked_counter_safe C t2 σ2 :
  AdvCtx C →
  rtc step ([ctx_fill C checked_counter], good_state ∅) (t2, σ2) →
  is_good σ2.
```

 - `AdvCtx C` means `C` is arbitrary attacker-controlled code with no `assert` and no heap location literals (approx: no forgeable heap locations).
 - `step` is an execution step. `rtc` is 0-or-more (reflexive transitive closure)
   - from a `good_state` with empty heap to state `σ2`
   - _`t2`, an arbitrary thread pool, is not relevant to this work._
 - `is_good` means no assertions were tripped

_translation* - the translation is currently approximate. We haven't finished proving the whole translation._

> Speaker notes:
> This is the reveal. Keep the focus on the security claim and the
> theorem-bearing Coq artifact.
