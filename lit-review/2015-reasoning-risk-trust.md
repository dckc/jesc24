# Reasoning about Risk and Trust in an Open World

- 2015 — Drossopoulou, Noble, Murray & Miller. ["Reasoning about Risk and Trust in an Open World"](http://ecs.victoria.ac.nz/foswiki/pub/Main/TechnicalReportSeries/ECSTR15-08.pdf). _Victoria University of Wellington, technical report ECSTR15-08._
- [2018 talk: Towards Reasoning about Risk and Trust in an Open World](https://www.youtube.com/watch?v=lxf7HTxWluc)

## Abstract

Contemporary open systems use components developed by different parties, linked together dynamically in unforeseen constellations. Code needs to live up to strict security requirements, and ensure the correct functioning of its objects even when they collaborate with external, potentially malicious, objects.

In this paper we propose special specification predicates that model risk and trust in open systems. We specify Miller, Van Cutsem, and Tulloh's escrow exchange example, and discuss the meaning of such a specification. We propose a novel Hoare logic, based on four-tuples, including an invariant describing properties preserved by the execution of a statement as well as a postcondition describing the state after execution. We model specification and programing languages based on the Hoare logic, prove soundness, and prove the key steps of the Escrow protocol.

## Summary

### Motivation

Traditional systems design assumes a *closed world*: a sharp border around a system whose components are all known and trustworthy. Open systems instead have an *open world* assumption: they interact with objects of varying mutual trust, with configuration that changes dynamically. Given a method request `x.m(y)`, what can we conclude when we know nothing about `x`?

### Contribution: first-class trust and risk

Building on the object-capability security model, the paper introduces a **first-class notion of trust** via the predicate `o obeys Spec`: an *assumption* that object `o` can be trusted to obey specification `Spec`. There is no central authority or trust bit — it is hypothetical, enabling reasoning by cases. If we trust `o`, we use its spec; if not, we bound the maximum damage: the **risk**.

Risk is delineated by two further hypothetical predicates:

- `MayAffect(o, p)` — it is possible that some method invocation on `o` would affect object/property `p`.
- `MayAccess(o, p)` — it is possible that code in `o` could gain a capability to access `p`.

These complementary notions of trust and risk sit within a flexible specification language supported by a **four-tuple Hoare logic** that includes both an invariant (properties preserved during execution) and a postcondition (state after execution), enabling reasoning about partial effects and preserved invariants.

### The escrow exchange case study

The paper formalises and proves correctness, trust, and risk for the Escrow Exchange — a trusted third party that swaps goods (e.g. money and shares) between untrusting counterparties. Two surprising results emerge:

1. The escrow's specification is **weaker** than anticipated: a reported successful transaction does **not** imply (a) the participants were trustworthy, nor (b) the participants are exposed to no risk by an untrustworthy participant (though the risk can be characterised).
2. It is **impossible** to write an escrow that gives both guarantees (a) and (b) — striking, given a co-author is an original developer of the escrow example.

### Relation to the literature review

This is the 2015 entry the review cites as "the first steps toward formal reasoning about these patterns." It is the full formal foundations extending the informal PLAS workshop paper ([*Swapsies on the Internet*](2015-swapsies-internet.md), same year), defining `obeys`, `MayAccess`, and `MayAffect` in the Focal and Chainmail languages and proving the key steps of the Escrow protocol. The escrow exchange example originates from the [2013 Dr. SES paper](2013-distributed-electronic-rights.md).