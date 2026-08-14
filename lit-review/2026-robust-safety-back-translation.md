# Endangered by the Language But Saved by the Compiler: Robust Safety via Semantic Back-Translation

- 2026 — Mück, Georges, Dreyer, Garg & Sammler. ["Endangered by the Language But Saved by the Compiler: Robust Safety via Semantic Back-Translation"](https://doi.org/10.1145/3776682). _Proc. ACM Program. Lang. 10 (POPL):40, pp. 1–30._

## Abstract

It is common for programmers to assemble their programs from a combination of trusted and untrusted components. In this context, a trusted program component is said to be *robustly safe* if it behaves safely when linked against arbitrary untrusted code. Prior work has shown how various encapsulation mechanisms (in both high- and low-level languages) can be used to protect code so that it is robustly safe, but none of the existing work has explored how robust safety can be achieved in a patently unsafe language like C.

In this paper, we show how to bring robust safety to a simple yet representative C-like language we call Rec. Although Rec (like C) is inherently "dangerous" and thus not robustly safe, we can "save" Rec programs via compilation to Cap, a CHERI-like capability machine. To formalize the benefits of such a hardening compiler, we develop Reckon, a separation logic for verifying robust safety of Rec programs. Reckon is not sound under Rec's unsafe, C-like semantics, but it is sound when Rec programs are hardened via compilation and linked against untrusted code running on Cap. As a crucial step in proving soundness of Reckon, we introduce a novel technique of semantic back-translation, which we formalize by building on the DimSum framework for multi-language semantics. All our results are mechanized in the Rocq prover.

## Summary

### Motivation

The question at the heart of the paper is the classic one for this literature: when a trusted module T is linked against untrusted module U, how do we ensure U cannot violate the invariants T maintains on its internal data? The standard answer relies on *built-in encapsulation mechanisms*: object capability patterns in safe high-level languages, physical sandboxing for low-level code, or capability machines for hardware-level memory isolation.

Prior work characterized all of these via the single notion of **robust safety**: T is robustly safe if it stays safe when linked against arbitrary untrusted code. Because those languages have built-in encapsulation, robust safety could be formulated as a "contextual syntactic" property — holding against any syntactic program context in the same language — and proven with standard compositional methods (logical relations, program logics). This is exactly what Swasey et al. (OCPL), Sammler et al., and Georges et al. (Cerise) do.

### Challenge: an unsafe C-like language

None of that work applies to a patently unsafe language like C, because C's syntactic program contexts are *too powerful*: they can incur undefined behavior. The paper's running example is a `password_check` function that reads a password hash into a local `pwd`, calls an untrusted `adv_io`, then asserts `pwd` is unchanged. An adversarial `adv_io` can exploit undefined behavior (out-of-bounds pointer arithmetic) to overwrite the adjacent local `pwd`, defeating the check. In an unsafe C-like language, one simply cannot write robustly safe code on its own — the language itself is the enemy.

### Contribution: hardening compilation to a capability machine

The paper's key move is to recover robust safety *not* in the source language but via a **hardening compiler**: Rec2Cap compiles Rec to Cap, a CHERI-like capability machine, turning Rec pointers into unforgeable fat pointers that Cap uses to enforce memory isolation at runtime. Compiling `password_check` this way means the capability to access `pwd` is never handed to `adv_io`, so the attack halts. This differs from *secure compilation*: there is no useful source-level property to preserve (Rec is already unsafe), so the goal is to *establish* robust safety for Rec modules via the compiler.

The framework is presented in two stages:

1. **Reckon** — a separation logic (built on Iris and OCPL) for verifying robust safety of Rec modules at a high level, with no knowledge of Rec2Cap or Cap required. Like OCPL, it distinguishes *high* locations (never shared, can hold trusted invariants) from *low* locations (may be accessed/written by untrusted code). Its central rule `spec-call-un` lets trusted code safely invoke an untrusted function as long as it only passes and receives low values.

2. **RobustDimSum** — the semantic framework establishing Reckon's soundness. Crucially, Reckon is *not* sound under Rec's unsafe semantics (the `adv_io` counterexample already shows `spec-call-un` fails); it is sound only for Rec modules compiled by Rec2Cap and linked against untrusted Cap code. Proving this requires validating `spec-call-un` against all possible Cap implementations of `f`. A *syntactic* back-translation (the prior technique) fails here, so the paper introduces a **semantic back-translation**: building on DimSum (a Rocq framework for multi-language semantics), it models untrusted Cap code semantically as labeled state-transition systems and proves a theorem relating a Cap-level universal contract (UNIV) to a Rec-level simulation (SIM). Soundness then reduces to a compiler-correctness proof for Rec2Cap. All results are mechanized in the Rocq prover.

## Relation to the literature review

This paper sits squarely in the formal-reasoning lineage of [the 2017 OCPL work](2017-robust-compositional-verification.md): it directly inherits OCPL's notion of robust safety, its high/low distinction, and its Iris-based program logic (Reckon), extending the same style of reasoning from safe high-level object-capability languages down to unsafe C-like languages by delegating encapsulation to a hardening compiler. It also connects to the hardware-capability thread — Cerise, a CHERI-like capability machine, is the basis for the Cap target. It is not about the escrow/mint-purse patterns themselves, but about the general technique of proving robust safety that the rest of the review's escrow verification depends on.
