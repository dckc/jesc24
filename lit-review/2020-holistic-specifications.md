# Holistic Specifications for Robust Programs

- 2020 — Drossopoulou, Noble, Mackay & Eisenbach. ["Holistic Specifications for Robust Programs"](https://doi.org/10.1007/978-3-030-45234-6_21). _FASE 2020, LNCS 12076:420–440._
- [arXiv preprint 2002.08334](https://arxiv.org/abs/2002.08334)

## Abstract

Functional specifications describe what program components can do: the sufficient conditions to invoke a component's operations. They allow us to reason about the use of components in the closed world setting, where the component interacts with known client code, and where the client code must establish the appropriate pre-conditions before calling into the component.

Sufficient conditions are not enough to reason about the use of components in the open world setting, where the component interacts with external code, possibly of unknown provenance, and where the component itself may evolve over time. In this open world setting, we must also consider the necessary conditions, i.e. what are the conditions without which an effect will not happen. In this paper we propose the language **Chainmail** for writing holistic specifications that focus on necessary conditions (as well as sufficient conditions). We give a formal semantics for Chainmail. The core of Chainmail has been mechanised in the Coq proof assistant.

## Summary

### Motivation: sufficient vs. necessary conditions

Software in an open world interacts with third-party code of unknown provenance — possibly buggy, possibly malicious. Classical Hoare-triple specifications describe *sufficient* conditions (e.g. "if you know the secret, you can take the treasure"), but they cannot preclude the existence of *other* methods that leak the secret and break robustness. The paper's running example is a `Safe` class with `treasure` and `secret` fields: a second version adds a `set` method that overwrites the secret, satisfies the classic Hoare triple for `take`, yet is not robust.

To express robustness, the paper introduces **holistic specifications**, e.g.:

> For any safe `s` whose treasure is non-null, if in the future `s.treasure` becomes null, then some *external* object currently has access to `s`'s secret.

This is a *necessary* condition on an effect, independent of any particular API.

### Contribution: the Chainmail language

**Chainmail** is a specification language for writing holistic specifications, guided by a sequence of object-capability and smart-contract examples: the membrane, the DOM, the Mint/Purse, the Escrow, the DAO, and ERC20. It provides:

- a small set of predicates capturing access (`canAccess`, `external`), state (`inState`), and temporal/ephemerality notions;
- a formal semantics; and
- a Coq mechanisation of the core.

Crucially, Chainmail can *express* necessary conditions like the holistic spec above, but it does **not** yet provide a proof logic for deriving such specifications — that gap is what the [2022 *Necessity* paper](2022-necessity-specifications.md) fills.

### Relation to the literature review

This is the 2020 paper the review cites for "a *Chainmail* formalism was developed." It is the first paper to introduce Chainmail, its semantics, and its Coq mechanisation, marking the move from [informal reasoning in 2015](2015-reasoning-risk-trust.md) toward formal, machine-checked specification of robustness in an open world.