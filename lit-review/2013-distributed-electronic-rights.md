# Distributed Electronic Rights in JavaScript

- 2013 — Miller, Van Cutsem & Tulloh. ["Distributed Electronic Rights in JavaScript"](https://doi.org/10.1007/978-3-642-37036-6_1). _ESOP 2013, LNCS 7792:1–20._
- [abstract on papers.agoric.com](http://papers.agoric.com/papers/distributed-electronic-rights-in-javascript/abstract/)

## Abstract

Contracts enable mutually suspicious parties to cooperate safely through the exchange of rights. Smart contracts are programs whose behavior enforces the terms of the contract. This paper shows how such contracts can be specified elegantly and executed safely, given an appropriate distributed, secure, persistent, and ubiquitous computational fabric. JavaScript provides the ubiquity but must be significantly extended to deal with the other aspects. The first part of this paper is a progress report on our efforts to turn JavaScript into this fabric. To demonstrate the suitability of this design, we describe an escrow exchange contract implemented in 42 lines of JavaScript code.

## Summary

### Motivation: a computational fabric for smart contracts

The global economy is held together by contracts — agreed frameworks for rearranging rights between mutually suspicious parties. But existing contracts are ambiguous, jurisdiction-specific, and require expensive experts. **Smart contracts** — contract-like arrangements expressed as program code, enforced by execution — can provide fine-grain, jurisdiction-free, automated arrangements for which legal contracts are impractical.

To realise this potential, smart contracts need a **distributed, secure, persistent, and ubiquitous computational fabric**. The paper argues JavaScript provides ubiquity (widely understood, including by non-expert programmers) and describes **Dr. SES** (Distributed Resilient Secure ECMAScript) as the extension providing the rest.

### Dr. SES

Dr. SES is layered on JavaScript and builds on:

- the **Q** library, extending JavaScript with a handful of features for distributed object- and message-level programming, supporting distributed cryptographic capabilities;
- **SES** (Secure ECMAScript), supporting local object-capabilities so that mobile code from untrusted parties can execute safely; and
- **NodeKen**, layering Node.js onto the Ken system for distributed orthogonal persistence — programs periodically checkpoint state and recover from a previously consistent state, surviving many failures without programmer effort.

The paper depends only on a small, universal JavaScript subset — functions and records (objects) — borrowing one ES6 convenience (arrow functions) and one ES7 proposal (the eventual-send operator `!`).

### Rights, money, and the 42-line escrow

Taking a **rights-based** approach to local and distributed computing, the paper argues, organises complexity in a decentralised manner and yields a better general-purpose platform that is naturally suited to expressing electronic rights and contracts. Three worked examples demonstrate simplicity and expressiveness:

1. **Money** — a mint/purse implementation of electronic bearer instruments.
2. **Escrow exchange** — a trusted third party that swaps goods between untrusting counterparties, implemented in **42 lines of JavaScript**.
3. **Generic contract host** — able to host the escrow contract and others, demonstrating safe execution of third-party code on servers.

### Relation to the literature review

The review cites this paper for the **42-line escrow contract** whose essential properties are the same as the Zoe escrow service, and for the **mint/purse pattern and amount math** that have remained essentially unchanged since the [2000 capability-based financial instruments paper](2000-capability-financial-instruments.md). It is the concrete bridge between the abstract smart-contract vision ([The Digital Path](2003-digital-path.md)) and the later formal reasoning work ([2015](2015-reasoning-risk-trust.md), [2020](2020-holistic-specifications.md), [2022](2022-necessity-specifications.md)).