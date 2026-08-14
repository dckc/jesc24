# JavaScript Language Design and Implementation in Tandem

- 2024 — Ryu & Park. ["JavaScript Language Design and Implementation in Tandem"](https://doi.org/10.1145/3624723). _Communications of the ACM 67 (5):86–93._

## Abstract

Rigorous language specifications do not prevent bugs in language implementations, and it is difficult to get a rigorous specification right in the first place — even the fully formal WebAssembly 1.0 spec had bugs found by mechanized proofs. This article presents how to automatically extract a *mechanized specification* from a prose specification and how useful that can be in practice. Using JavaScript as the example, it shows how mechanized specifications can be used to detect conformance bugs between a language specification and existing JavaScript engines in major web browsers, and to generate more special-purpose JavaScript implementations, such as static analyzers, in a correct-by-construction manner. The article proposes a new approach to programming language development: first design the language in a mechanized specification, then generate both human-friendly specifications in diverse natural languages and correct-by-construction implementations and tools from the mechanized specification.

## Summary

### Motivation

JavaScript is the most actively used programming language on GitHub, and every web browser ships a JavaScript engine. ECMA-262 — the JavaScript specification — is written in highly structured prose at the level of pseudocode algorithms, but prose is error-prone. The paper documents concrete specification bugs (e.g. a `Math.round` algorithm that compared `x` instead of the converted number `n`), counterintuitive semantics (e.g. `[] == ![]` evaluating to `true`), and harmful implementation and security bugs in engines such as V8 (e.g. CVE-2021-21224). Static analyzers built on a sound abstraction of the language have also been plagued by soundness bugs for unusual edge cases.

### Contribution: mechanized specifications via ESMeta

Since 2015 ECMA-262 is released annually, making it infeasible to manually keep analysis tools (most still based on the 2009 ES5) in sync with an ~800-page spec. The key idea is to "parse" the English sentences of the spec and "compile" them into abstract algorithms in an intermediate representation, yielding a **mechanized specification** that can drive the automatic generation of language tools.

A mechanized specification has two parts: a **parser** constructed from the EBNF-style grammar, and **functions in an intermediate representation** compiled from the English abstract algorithms for the semantics. This work builds on a series of KAIST tools:

- **JISET** extracts the mechanized specification from ECMA-262.
- **JEST** synthesizes conformance tests and checks discrepancies between engines and the spec — detecting 44 bugs in four engines (V8, GraalJS, QuickJS, Moddable XS) and 27 bugs in ES2020.
- **JSTAR** analyzes the types of English sentences in ECMA-262, detecting 93 type-related spec bugs confirmed by TC39.
- **JSAVER** automatically generates a JavaScript static analyzer from ECMA-262 that outperforms state-of-the-art manually developed analyzers.

These prototypes were reimplemented and rebranded as **ESMeta**, integrated into the CI systems of ECMA-262 and Test262 (Nov 2022). Every ECMA-262 PR is now "type checked", and new/changed Test262 tests are run using an interpreter extracted directly from the text of the spec.

### Proposed approach

The article generalizes beyond JavaScript: design a language *in* a mechanized specification first, then generate both human-friendly prose specs in many natural languages and correct-by-construction implementations and tools from that single source of truth — keeping spec and implementations in tandem.

## Relation to the literature review

This paper is less about the object-capability/escrow patterns that anchor the rest of this review, and more about the *infrastructure* of trustworthy language implementation and specification. It is relevant background for any project that mechanizes or verifies semantics: it demonstrates the concrete payoff of extracting a mechanically-checkable semantics from a prose specification (bug detection, conformance testing, correct-by-construction tool generation), complementing the machine-checked verification agenda of the [2017 OCPL work](2017-robust-compositional-verification.md) and the [2022 Necessity formalization in Coq](2022-necessity-specifications.md). Where those works formalize object-capability *patterns*, this work is a case study in keeping a large, evolving language *specification* machine-checked.
