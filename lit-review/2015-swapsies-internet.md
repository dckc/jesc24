# Swapsies on the Internet: First Steps towards Reasoning about Risk and Trust in an Open World

- 2015 — Drossopoulou, Noble & Miller. ["Swapsies on the Internet: First Steps towards Reasoning about Risk and Trust in an Open World"](https://doi.org/10.1145/2786558.2786564). _PLAS@ECOOP 2015, pp. 2–15._

## Abstract

Contemporary open systems use components developed by many different parties, linked together dynamically in unforeseen constellations. Code needs to live up to strict security specifications: it has to ensure the correct functioning of its objects when they collaborate with external objects which may be malicious.

## Summary

This is the short PLAS@ECOOP workshop paper that introduced, informally, the ideas later formalised in the [ECSTR15-08 technical report](2015-reasoning-risk-trust.md) (*Reasoning about Risk and Trust in an Open World*, same year, same authors plus Toby Murray). It is the first published sketch of:

- a **first-class notion of trust** — the `obeys` predicate, used hypothetically to reason by cases about whether an object can be trusted to meet a specification; and
- a **first-class notion of risk** — via the `MayAccess` and `MayAffect` predicates, bounding the damage an untrusted object can cause.

The motivating example is Miller, Van Cutsem, and Tulloh's **escrow exchange** (from the [2013 Dr. SES paper](2013-distributed-electronic-rights.md)): a trusted third party that swaps goods between untrusting counterparties. The paper shows why a traditional (sufficient-condition) specification is too weak to capture robustness in the open world, and why a naive implementation is not robust against malicious clients — motivating the move toward necessary-condition reasoning.

### Relation to the literature review

The review cites 2015 as "the first steps toward formal reasoning about these patterns." This workshop paper is the first published (informal) presentation of those steps; the companion technical report (ECSTR15-08) provides the full formal foundations, the four-tuple Hoare logic, and the proof of the key steps of the Escrow protocol.