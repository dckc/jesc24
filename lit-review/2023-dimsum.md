# DimSum: A Decentralized Approach to Multi-language Semantics and Verification

- 2023 — Sammler, Spies, Song, D'Osualdo, Krebbers, Garg & Dreyer. ["DimSum: A Decentralized Approach to Multi-language Semantics and Verification"](https://doi.org/10.1145/3571220). _Proc. ACM Program. Lang. 7 (POPL):27, pp. 1–31._

## Abstract

Prior work on multi-language program verification has achieved impressive results, including the compositional verification of complex compilers. But the existing approaches to this problem impose a variety of restrictions on the overall structure of multi-language programs (e.g., fixing the source language, fixing the set of involved languages, fixing the memory model, or fixing the semantics of interoperation). In this paper, we explore the problem of how to avoid such global restrictions.

Concretely, we present DimSum: a new, decentralized approach to multi-language semantics and verification, which we have implemented in the Coq proof assistant. Decentralization means that we can define and reason about languages independently from each other (as independent modules communicating via events), but also combine and translate between them when necessary (via a library of combinators).

We apply DimSum to a high-level imperative language Rec (with an abstract memory model and function calls), a low-level assembly language Asm (with a concrete memory model, arbitrary jumps, and syscalls), and a mathematical specification language Spec. We evaluate DimSum on two case studies: an Asm library extending Rec with support for pointer comparison, and a coroutine library for Rec written in Asm. In both cases, we show how DimSum allows the Asm libraries to be abstracted to Rec-level specifications, despite the behavior of the Asm libraries not being syntactically expressible in Rec itself. We also verify an optimizing multi-pass compiler from Rec to Asm, showing that it is compatible with these Asm libraries.

## Summary

### Motivation

Real-world programs are assembled from components written in multiple languages (C libraries linked from Go/OCaml/Rust/Python, assembly interrupt handlers in operating systems, etc.). Verifying such programs requires reasoning not just about each component but about the *interactions* between them at language boundaries. Prior multi-language verification frameworks all imposed global restrictions — a fixed source language, a fixed set of languages, a fixed memory model, or a fixed interoperation semantics — which makes them hard to reuse or extend.

### Contribution: a decentralized multi-language framework

DimSum removes these global restrictions with a *decentralized* design, mechanized in Coq:

- **Languages are independent modules** that communicate via *events* (à la process calculi). Each language is defined and reasoned about on its own, without a global set of languages or a single interoperation semantics.
- A **library of combinators** lets languages be combined and translated between when needed.

The paper applies DimSum to three languages: **Rec** (high-level imperative, abstract memory model, function calls), **Asm** (low-level assembly, concrete memory, arbitrary jumps, syscalls), and **Spec** (a mathematical specification language). Two case studies show Asm libraries being abstracted to Rec-level specifications even when their behavior is not syntactically expressible in Rec; a third verifies an optimizing multi-pass Rec→Asm compiler.

## Relation to the literature review

This paper supplies the underlying multi-language semantics machinery on which [the 2026 robust-safety paper](2026-robust-safety-back-translation.md) builds: Mück et al. use DimSum's event-based, module-as-labeled-state-transition-system model to define their semantic back-translation (the SIM/UNIV universal contracts), the crucial step in proving soundness of their Reckon separation logic. DimSum itself is not about object capabilities or escrow, but about how to reason compositionally across language boundaries — which is exactly the setting that the robust-safety and [OCPL-style](2017-robust-compositional-verification.md) results rely on when trusted and untrusted code run in different languages.
