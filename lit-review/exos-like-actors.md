# Exos like Actors: A Pure-Transition Reframing for Robust Safety

## Motivation

The long-range goal is robust safety of the Zoe escrow contract. The current
proof stack (Jessie fragment parsed & lowered to Iris HeapLang, proved with
the OCPL robust-safety theorems) has carried the `makeCounter` separation-of-
duties example through to `checked_counter_safe`. The escrow contract is the
harder target, and the natural next question is *what shape of model makes the
proof scale*.

This note sketches a reframing suggested by recent discussion around [exos and
durable state][erights-ownables] (E. Noble / Miller) and by the Actor model as
a party game (an oros-gov note). The claim:

> Treat each exo as an **actor** whose state is a *record of passables* (WLOG a
> single passable that may itself be a copyrecord). Its message handlers are
> mostly **pure transition functions**; the only impure effect is the
> **allocation of new actors** (brands, purses, payments, ...). The
> `makeCounter` example allocates nothing.

If that split holds, the verification burden lands overwhelmingly on *pure
function reasoning*, with a small, sharply-localized residue for *fresh-name /
allocation* reasoning. That is exactly the split the existing Iris/HeapLang
stack is good at.

[erights-ownables]: https://www.youtube.com/watch?v=O8Bx_Abj9Qc&list=PLzDw4TTug5O1A-tkPJe4HVq0VBPcNOMHm

---

## The reframing

**Actor = exos = one heap cell whose contents are a record of passables.**

```coq
(* exo state as a record of passables *)
Definition exo_state := gmap label passable.  (* WLOG a single passable *)
```

An exos "receives a message" (a method call) and, on its turn:

1. **computes** — a pure function on its current record, producing a new record;
2. **sends** — may hand out references that already live in its record;
3. **allocates** — may spawn new actors (new brands, purses, payments) and
   learn their fresh names.

Rule (2) is free: references are *already* in the record, so "sending" is just
projecting the record. Rule (3) is the only genuinely stateful operation.

**`makeCounter` allocates nothing.** `makeCounter()` returns an object whose
closure captures a single hidden cell (`count`); every method is a pure
function of that cell. So the counter proof never exercises the allocation
branch — which is why `checked_counter_safe` went through with a mostly-pure
invariant (`counter_inv count`).

**Escrow, purses, payments, brands all allocate.** This is precisely what makes
escrow harder than the counter: `deposit`/`withdraw` mint new purses and
payments, and `makeBrandPair` needs rights amplification (two mutually
referencing fresh actors). The reframing says: keep those transitions pure in
`passable`, and make allocation the *only* place the proof has to reason about
the heap growing.

---

## Dropping closures: a first-order, Java-like model

In JS/Jessie, object capability *is* closure: `makeCounter` hides `count` in a
closure environment, a `caretaker` captures its `target`, a purse hides its
`balance`, a facet captures the purse reference. The OCPL machinery (low
values, higher-order Iris) exists largely *because* the security mechanism is
a closure capturing private state.

The actor model replaces that mechanism: **authority is possession of a
reference (a TrueName), not capture in a closure.** Under the exo/actor
reframing, every ocap pattern stops being *closure construction* and becomes
*spawning an actor with a finite first-order script*:

| OCap pattern | Closure version | Actor version |
|---|---|---|
| **Facet** | closure capturing the purse, exposing `deposit` only | spawned actor whose state record holds a reference to the purse; its handler forwards only `deposit` |
| **Caretaker** | closure over `target` + `alive` flag | spawned actor with `{ target, alive }` in its record; `revoke` flips the flag |
| **Hidden state** | closed-over cell (`count`, `balance`) | private field of the actor's record |
| **Behavior parameter** (e.g. `amountMath`) | higher-order function argument | a first-order value or an actor reference, **stored in the state record** |

This is the "something more like Java" step: **objects + references + method
dispatch, no higher-order values.** Handlers are finite dispatch tables over a
record; allocation mints a fresh name; the only "data" an actor passes along is
already in its record.

### Why this matters for verification tooling

It converts the hard parts of ocap verification into first-order problems:

- **DimSum compatibility.** The published DimSum is deliberately first-order
  (Rec = C-like imperative, Asm = assembly); its paper lists *closures* as
  explicitly out of scope / future work. If exos don't need closures, that
  stopgap disappears — the exo/actor model is *already* a collection of
  first-order modules-as-labeled-transition-systems communicating via events,
  which is exactly DimSum's model.
- **Attacker-as-process-calculus.** Issue #13's intuition — approximate
  untrusted behavior with a universal contract over LTS modules — fits
  cleanly: the attacker is an arbitrary finite-script LTS that may spawn
  unboundedly many new finite scripts. Each spawned behavior is a finite script
  at spawn time; references stay first-order names.
- **Lighter logic.** The pure tier and the allocation tier become fully
  first-order, expressible in ACL2 / TLA+ / Event-B / Maude / a Java-like Lean
  model — no higher-order separation logic required for the object language.
  Iris/OCPL can remain the substrate for the *open-world adversarial* tier
  without the object language being higher-order.

### Honest costs

1. **Model/implementation gap.** Real Agoric exos are written in JS and do use
   closures internally. A first-order model captures exo *semantics*, not the
   literal JS source — the same gap a compiler proof (e.g. Rec→Asm) accepts.
   You would want a translation / adequacy claim from JS exos to the actor
   model.
2. **Behavior must be data.** We must be deliberate that the "behavior" passed
   to `spawn` is a finite script / interface tag, not a first-class function
   flowing inside messages.
3. **Not free at the meta level.** The open-world attacker tier may still want
   Iris-grade adversarial semantics (OCPL robust safety); what gets simpler is
   the *object language*, not necessarily the *meta-logic*.

On balance, dropping closures is a real simplification with a clear cost to
manage (the JS↔model gap) — and it is the same instinct as the process-calculus
attacker hunch: the exo/actor model is the bridge that makes a first-order,
Java-like, DimSum-compatible formal model viable.

---

## Why this is a separation-of-duties win

The intuition the reframing banks on:

- Pure functions are cheap to verify: a `Function`/`Lemma` over an inductively
  defined `passable` / `amount` data, no separation-logic machinery at all. The
  `amountMath` spike in the earlier Dafny work already confirmed this is the
  easy part.
- Allocation is where the authority in / authority out semantics lives: new
  names must be *fresh* (a brand's mint must not leak, a payment must be
  distinct from a purse). Fresh-name reasoning is the classic separation-logic
  / Iris sweet spot (`inv`, namespace, ghost `na`, etc.).

So the plan is to **chase most state-change into pure functions and concentrate
the proof effort on a small number of allocation sites.**

---

## What the attacker model must be

Following the party-game model: an attacker is *any* actor at the party that
holds references it was handed. To reason about escrow robustly we eventually
must let the attacker do what actors do — **allocate new actors too**:

- an attacker can spawn purses/payments of its own, so brand / mint / purse
  invariants must be robust against arbitrary other allocations;
- the *amount math* and *cross-brand refusal* checks are what keep attacker-
  forged purses from corrupting the escrow's.

For the first milestone, though, we do **not** need attacker allocation:
`makeCounter`-style reasoning (an attacker that can only project the given
references and apply the given pure functions) is sufficient to get the
separation-of-duties theorem that the escrow has full authority over its own
payments. So:

- **Phase 1 (now):** attacker = references-only, no allocation. Prove escrow's
  pure transitions and the adequacy of a non-allocating attacker.
- **Phase 2 (later):** let the attacker allocate. This is where the
  fresh-name/capability argument gets real, and it is the tier that most
  separates the tools (see below).

---

## What tooling fits

Iris is powerful but genuinely hard: higher-order concurrent separation logic
is a lot of machinery, and this reframing's whole point is to keep most of the
reasoning *pure*. The actor-as-record-state picture suggests a tiered proof
that almost any capable prover can carry, so it is worth surveying the 
actor-verification tooling landscape broadly rather than locking onto Iris.
ACL2's instinct ("model freshness with `(cons)`") is exactly right and is the
linchpin below.

The honest framing: **actor verification is a well-trodden field**, and the
reframing is deliberately written to be expressible in the *simplest* of these
tools.

### Candidate tools

| Tool | Kind | Actor fit | Notes |
|---|---|---|---|
| **ACL2** | first-order Lisp prover, 40+ yrs | strong | The flagship actor-verification line. Freshness by construction: a new actor's "name" is a fresh `(cons)`ed token, and the ACL2 meta-logical [first-order/`tame` subset][tame] lets you carry functions around. State = a list/map of actor→record; transition = a pure `defun`. No concurrency logic needed if actors are modeled as one monolithic transition. Many [verified systems][acl2-apps] including Java VM, app (JVM bytecode) models — the "machine-checked runtime" sweet spot. |
| **TLA+ / TLC + TLAPS** | TLA + model checker + proof system | mature | TLA is *the* actor/concurrency spec notation (actors = `processes` with `spawn`); TLC model-checks bounded state (catches bugs fast); TLAPS proves invariants. Very mature, battle-tested on real distributed systems. But: proof obligations are invariant/refinement, and there's no direct line to the runnable Jessie/JS. |
| **Rewriting logic / Maude** | rewrite theories + SMC | mature | An actor is literally a term; message arrival = a rewrite rule; `spawn` = extending a multiset with a fresh term. [Real-Time Maude](http://heim.ifi.uio.no/~peterol/RealTimeMaude/) does formal real-time actor semantics. Search/`model-check` finds violating reachable states. Same "separate semantics from JS" caveat as above. |
| **Erlang/OTP + McErlang / Concuerror** | the reference actor language + model checkers | the most mature | Erlang *is* the actor model (processes, `spawn`, message-passing, `make_ref` = fresh name). [Concuerror](https://concuerror.com/) does stateless model checking of Erlang programs; [McErlang](https://www.jaist.ac.jp/project/mc-erlang/) does model checking of Erlang specs. Best if we wanted to prototype the *actor semantics itself* in its native home and then translate. |
| **Event-B / Rodin** | refinement + automated obligations | mature | Models a "state machine that spawns a growing set of actors" via refinement (each new actor = an event creating a set member). The "growing set of fresh actors" is *the* canonical Event-B pattern. Strongly tooled (Rodin + Atelier B). But obligations are generated, not a program logic, and it's a different universe from JS. |
| **Iris / HeapLang (Rocq)** | higher-order concurrency separation logic | current stack | Most powerful for *adversarial higher-order linking* and *open-world robust safety* — the OCPL/2017 thread this repo is built on. `ref` for cells, `jobj`/`obj_get` for record-of-passables, allocation is native. The con of the reframing (fresh-name / alloc) is the exact case separation logic is designed to carry. Heavy, but it's the one tool that *also* covers the open-world attacker-allocation (Phase 2). |
| **Lean 4 / Mathlib** | dependent-type prover, fast-moving | young but rising | The "hip" option. What's relevant is [iris-lean](https://github.com/leanprover-community/iris-lean), a Lean 4 port of Iris (MoSeL proof mode, the model, invariants) — so the *same* concurrency/separation-logic approach is being reproduced in Lean, but it is early/experimental, not a drop-in. For the pure-transition tier Lean/mathlib is pleasant. Where Lean *is* already battle-hardened in this space: [Cedar](https://github.com/cedar-policy/cedar-spec), Amazon's authorization-policy DSL, has a [Lean formalization](https://github.com/cedar-policy/cedar-spec/tree/main/cedar-lean) that defines the spec as a Lean evaluator and proves authorization properties against it. That is exactly the "one pure transition function + soundness proofs" shape the pure tier wants, and it is production-grade. Net: as pure-tier prover Lean is credible; as a full actor/robust-safety substrate it lags Iris-in-Rocq and the classic tools because the actor-specific libraries are not there yet. |
| **F\*** | Dependently-typed ML with effects | long-horizon | Interesting for a Jessie→JS certifying compiler (the fully-abstract-JS-compilation line), but not the obvious first step for the actor model itself. |

The honest trade-off is **automation+simplicity vs. end-to-end authority /
adversarial semantics**:

- If the goal is "verify the escrow amount/transfer invariants and the
  brand/purse fresh-actor discipline," **ACL2, TLA+, Event-B, Maude, or Lean**
  do that with far less logical machinery than Iris; freshness-by-`cons` is the
  canonical ACL2 idiom, and Cedar's Lean spec is proof the pure-tier shape
  works in Lean at production scale.
- If the goal is also "prove it robust *against an arbitrary allocating
  adversary*" — the OCPL robust-safety statement the repo is built around —
  then you need higher-order adversary semantics, and **Iris** (with OCPL) is
  the strongest existing substrate, which is why it's the incumbent. `iris-lean`
  is the same logic in Lean, but is not yet at that level of maturity.

### The division of labor I'd actually propose

The tiers are tool-agnostic; only tier 3's *strength* varies by tool.

1. **Pure layer (cheap, reusable, any tool):** each exos's transition
   functions as pure functions over a `passable`/`record` datatype, verified
   with arithmetic/reasoning. This is the bulk of escrow (`amount`, transfer
   predicates, brand checks) and most of the code volume and soundness. This
   tier is where ACL2-the-prover, a TLA+ invariant, or a Lean/Mathlib
   `theorem` (à la Cedar) shines.
2. **Allocation layer (fresh-actor):** the only "stateful" tier. Freshness of
   new names (brand/purse/payment) — in ACL2 as a fresh `(cons)` token with a
   "name not already in the state map" lemma; in TLA+ as a `spawn` action that
   adds to a set; in Event-B as a refinement event; in Iris as an `alloc`
   spec lemma. All the actor-allocation reasoning lives here.
3. **Robust-safety wrapper (attacker allocation):** the adversarial tier. In
   OCPL/Iris this is the `AdvCtx`/`ctx_fill`/`robust_safety` scaffolding,
   extended (Phase 2) so the attacker context may itself allocate. In TLA+
   this is a fairness/"any actor may run any enabled action" adversary. In
   ACL2 it is a quantifier over attacker actions; in Maude it is the `spawn`
   rewrite rule available to anyone.

### A concrete ACL2 sketch (the "freshness by cons" instinct)

The reframing's purity claim is so natural in ACL2 that the whole thing might
be one model:

```lisp
;; an actor's name is just a fresh cons cell; the state is a map from
;; name -> (record of passables)
(defun take-step (st name msg) ; pure: one exos's handler
  (if (brand-and-amount-checks-ok st) ...))

;; allocation: mint a fresh name and register it
(defun spawn (st behavior) (acons (cons 'name (nfix (len st))) behavior st))
```

`acons` gives fresh names for free: the state is an association list keyed by
`(cons 'name <n>)`, so a new `spawn` can never collide with an existing name;
"a mint's purse must not collide" becomes a `memberp` / distinct-names
invariant. ACL2-the-prover will prove the amount-conservation /
no-double-spend / cross-brand-refusal lemmas as ordinary inductive theorems.

The recommendation is not to throw away Iris (it is the only tool here that
already carries the open-world adversarial tier), but to **let the tools each
do the tier they are simplest at**: use a lightweight prover (ACL2 / TLA+ /
Maude / Event-B) for the bulk pure-transition invariants, and keep Iris for
the adversary tier — or, if the open-world tier turns out to be disposable,
just stay in the lightweight tool the whole way.

---

## Relationship to the current tree

- `theories/jessie/make_counter.v` — the counter constructor and its
  robust-safety proof; currently the base case (no allocation).
- `theories/jessie/escrow2013*.v` — the escrow sources and their parser/
  lowering; the allocation-heavy target this note aims to reach.
- `theories/jessie/docs/jessie-iris.md` — the standing summary of the current
  proof stack; this note is a proposed next layer on top of it.

---

## Open questions

- Where does "send" (handing out an already-held reference) enter? Pure
  projection, or a third effect that must be tracked?
- For `makeBrandPair` rights amplification: does the fresh-name argument
  already cover the two-recursive-reference case, or do we need a dedicated
  "brand knoweth purse" invariant at the allocation site?
- Phase 2 attacker-allocation: what exactly may it allocate (only payment/ purse
  of its own brand, or any exo), and how is that bounded to keep the 
  robustness theorem tractable?
- Do we want a notion of "message" as the actual unit of reasoning (a session/
  channel semantics à la Actris) or is a single `handle : msg -> state -> state
  * allocations * reply` enough?

[dafny-spike]: https://github.com/Agoric/agoric-sdk/pull/8184#issuecomment-1676638022
[fa-js]: https://dl.acm.org/doi/10.1145/2429069.2429114
[tame]: https://www.cs.utexas.edu/users/moore/acl2/v8-5/combined-manual/?topic=ACL2____TAME
[acl2-apps]: https://www.cs.utexas.edu/users/moore/acl2/v8-7/combined-manual/index.html?topic=ACL2____INTERESTING-APPLICATIONS
