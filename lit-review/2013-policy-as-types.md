# Policy as Types

- 2013 — Meredith, Stay & Drossopoulou. ["Policy as Types"](https://arxiv.org/abs/1307.7766). 2013. arXiv:1307.7766. _Submitted to WPES 2013._

## Abstract

Drossopoulou and Noble argue persuasively for the need for a means to express policy in object-capability-based systems. We investigate a practical means to realize their aim via the Curry-Howard isomorphism. Specifically, we investigate representing policy as types in a behavioral type system for the rho-calculus, a reflective higher-order variant of the π-calculus.

## Summary

### Motivation

The object-capability (ocap) security model grows out of the observation that good OO practice leads to good security: separation of duties gives separation of authority, information hiding gives integrity, message passing gives authorization, and dependency injection gives authority injection. An ocap language enforces these patterns — the only way an object can modify state other than its own is by sending messages on the references it possesses. Authority is denied simply by not providing the relevant reference.

The paper's goal is a language for *declaring* security policy: declare the authority an object ought to possess, then check that the implementation matches intent. It grounds this in the capability policies of Drossopoulou and Noble, focusing on **deniability**:

- **Openness** — policies apply to a module and all its extensions.
- **Necessity** — describe necessary conditions for an effect to take place (e.g. to modify a bank-account balance you must hold a reference to the account), rather than the sufficient-and-closed conditions of classical Hoare Logic.

### Contribution: policy via Curry-Howard and the rho-calculus

The paper shows the rho-calculus is an ocap language and expresses policy as types:

- **Necessary conditions** are captured by *inverting the assertion* and using bisimulation (code without the account reference is bisimilar to code in which the balance is never modified).
- **Openness** is captured by adapting the adjoint of the separation operator: any further code attached to the current code is bisimilar to that code in parallel with code that does not modify the balance.

The paper sketches a translation from a subset of JavaScript into the calculus and demonstrates that the corresponding Hennessy-Milner logic suffices to capture deniability. In the larger scheme, this identifies Drossopoulou and Noble's notion of policy with the proposition-as-types paradigm — the Curry-Howard isomorphism — treating behavioral types as a security policy language.

## Relation to the literature review

This paper sits in the formal-reasoning lineage, directly answering the call from Drossopoulou and Noble's [2015 risk-and-trust work](2015-reasoning-risk-trust.md) (the paper predates that published version but targets the same line of policy/robustness ideas). It shares the core concern — how to *specify* the security policy an ocap module is meant to enforce — that later work formalizes differently: [Chainmail](2020-holistic-specifications.md) and [Necessity specifications](2022-necessity-specifications.md) express exactly the *open* and *necessary-condition* nature of these policies that this paper motivates, while [OCPL](2017-robust-compositional-verification.md) and [Reckon](2026-robust-safety-back-translation.md) verify robust safety that such policies describe. Where those works use program logics, this one explores the rho-calculus + behavioral types (Curry-Howard) route.
