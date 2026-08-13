# Robust and Compositional Verification of Object Capability Patterns

- 2017 — Swasey, Garg & Dreyer. ["Robust and Compositional Verification of Object Capability Patterns"](https://doi.org/10.1145/3133913). _Proc. ACM Program. Lang. 1 (OOPSLA):89, pp. 1–26._

## Abstract

In scenarios such as web programming, where code is linked together from multiple sources, *object capability patterns* (OCPs) provide an essential safeguard, enabling programmers to protect the private state of their objects from corruption by unknown and untrusted code. However, the benefits of OCPs in terms of program verification have never been properly formalized. In this paper, building on the recently developed Iris framework for concurrent separation logic, we develop OCPL, the first program logic for compositionally specifying and verifying OCPs in a language with closures, mutable state, and concurrency. The key idea of OCPL is to account for the interface between verified and untrusted code by adopting a well-known idea from the literature on security protocol verification, namely *robust safety*. Programs that export only properly wrapped values to their environment can be proven robustly safe, meaning that their untrusted environment cannot violate their internal invariants. We use OCPL to give the first general, compositional, and machine-checked specs for several commonly-used OCPs—including the *dynamic sealing*, *membrane*, and *caretaker* patterns—which we then use to verify robust safety for representative client code. All our results are fully mechanized in the Coq proof assistant.

## Summary

### Motivation

Object capability patterns (OCPs) — wrappers like `readonly` that mediate access to private state via closures — are ubiquitous in web programming (e.g. Yahoo's ADsafe, Google's Caja) and central to capability-secure languages. In a language like JavaScript, where objects provide essentially no data abstraction on their own, OCPs are one of the few effective mechanisms for enforcing data abstraction in the presence of possibly malicious code.

Despite their ubiquity, remarkably little attention had been paid to *what exactly* the security guarantees of OCPs are, and how to prove they provide them. Even for the basic `readonly` pattern, it is unclear what formal conditions on a reference `ℓ` guarantee that `readonly ℓ` can be safely shared with untrusted code. The prior state of the art (Devriese et al. 2016) built a Kripke logical-relations model and verified several examples, but provided no way to compositionally specify what an OCP does and no general specification of what makes user code safely shareable.

### Contribution: OCPL

The paper presents **OCPL** (a Logic for OCPs), the first formal system for compositionally specifying and verifying the security guarantees provided by OCPs, in a higher-order concurrent imperative language (HLA) with closures, mutable state, and fork-based concurrency. OCPL is derived from **Iris**, a framework for higher-order concurrent separation logic, and inherits its Coq mechanisation via the Iris proof mode.

The key idea is how OCPL characterises the interface between verified user code and untrusted code, via the concept of a **low-integrity value** (adapted from security-protocol verification). A *low value* is one from which no code can extract a direct reference to private state — a value that can be safely shared with untrusted code. This is formalised as a logical relation defined using Iris's built-in support for guarded recursive predicates.

### Robust safety

The central meta-theorem is **robust safety**: if user code satisfies a specification whose postcondition stipulates that the resulting value is low-integrity, then running that verified code under an arbitrary adversarial context `C` (containing no `assert` statements of its own) will never violate any of the user code's internal assertions. Robust safety is a well-known meta-theorem in the security literature, but this paper makes the observation that it is *exactly* the property a language must satisfy to support OCPs, and that low-integrity values are essential to compositionally specifying an OCP's contribution toward robust safety.

### Verified patterns

OCPL is used to give the first general, compositional, and machine-checked specifications for several commonly-used OCPs:

- **`readonly`** — wraps a reference as a thunk that reads its contents.
- **Dynamic sealing** (sealer-unsealer) — creates sealed values that can only be unsealed by a designated party.
- **Membrane** — automatically wraps all objects crossing to/from untrusted code, transitively attenuating access (as used by Caja).
- **Caretaker** — a revocable forwarder that can withdraw authority after the fact.

For each, the paper verifies representative client code, proving robust safety — that untrusted code cannot violate the client's internal invariants. All results are fully mechanised in Coq.

### Relation to the literature review

This paper sits in the formal-reasoning lineage between the [2015 risk-and-trust work](2015-reasoning-risk-trust.md) and the [2020 Chainmail paper](2020-holistic-specifications.md). It shares the goal of formally verifying object-capability patterns — the membrane appears in both, and the escrow/mint-purse patterns originate from the [2000 capability-based financial instruments paper](2000-capability-financial-instruments.md) and the [2013 Dr. SES paper](2013-distributed-electronic-rights.md) — but takes a different technical approach: rather than a custom specification language (Chainmail/Necessity), it builds on the established Iris concurrent separation logic and adopts the security-literature notion of robust safety. The [2022 Necessity paper](2022-necessity-specifications.md) cites this work as prior art addressing robustness via generic guarantees and preservation of module invariants, while Necessity focuses on problem-specific necessary conditions for specific effects.