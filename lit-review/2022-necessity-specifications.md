# Necessity Specifications for Robustness

- 2022 — Mackay, Drossopoulou, Noble & Eisenbach. ["Necessity Specifications for Robustness"](https://doi.org/10.1145/3563317). _Proc. ACM Program. Lang. 6 (OOPSLA2):154._
- [arXiv preprint 2209.08205](https://arxiv.org/abs/2209.08205)

## Abstract

Robust modules guarantee to do only what they are supposed to do — even in the presence of untrusted, malicious clients, and considering not just the direct behaviour of individual methods, but also the emergent behaviour from calls to more than one method. Necessity is a language for specifying robustness, based on novel necessity operators capturing temporal implication, and a proof logic that derives explicit robustness specifications from functional specifications. Soundness and an exemplar proof are mechanised in Coq.

## Summary

### Motivation

Correctness is traditionally specified through Hoare triples (precondition, code, postcondition), describing *sufficient* conditions. But correctness is not robustness: a module may satisfy its functional specification yet leak authority through emergent interactions across multiple methods. The paper generalises *robust safety* — a module preserves safety guarantees even when run with unknown, unverified, potentially malicious client code — and focuses on **necessary conditions** for effects: conditions without which an effect will not happen.

For example, a bank account's balance should not decrease unless `transfer` was called with the correct password. But a stronger, API-independent formulation is: *the balance of an account does not ever decrease in the future unless some external object now has access to the account's current password.* This lets one hand an account to untrusted code without fear of theft, regardless of the module's API surface.

### Contribution: the Necessity language

Necessity is the first approach able to both **express** and **prove** (through an inference system) robustness specifications of this form. It introduces three novel operators that merge temporal operators with implication, the central one being:

> `from A_curr to A_fut onlyIf A_nec`

A transition from a current state satisfying `A_curr` to a future state satisfying `A_fut` is possible only if the necessary condition `A_nec` holds in the current state. The operators combine temporal logic with object-capability-style notions of permission and provenance (who holds access to what).

A proof logic derives explicit robustness specifications from functional specifications, and soundness is mechanised in Coq along with an exemplar proof.

### Relation to the literature review

This is the 2022 entry point the review cites for "techniques applied more broadly and formalized in Coq." It builds directly on the [*Chainmail* formalism](2020-holistic-specifications.md) of the 2020 paper, replacing/augmenting Chainmail's necessity operators with the `onlyIf` family and adding a proof logic — the missing piece in the 2020 work.