# Capability-Based Financial Instruments

- 2000 — Miller, Morningstar & Frantz. ["Capability-Based Financial Instruments"](https://doi.org/10.1007/3-540-45472-1_24). _Financial Cryptography (FC) 2000, LNCS 1962:349–378._
- [abstract on papers.agoric.com](http://papers.agoric.com/papers/capability-based-financial-instruments/abstract/)

## Abstract

Every novel cooperative arrangement of mutually suspicious parties interacting electronically — every smart contract — effectively requires a new cryptographic protocol. However, if every new contract requires new cryptographic protocol design, our dreams of cryptographically enabled electronic commerce would be unreachable. Cryptographic protocol design is too hard and expensive, given our unlimited need for new contracts.

Just as the digital logic gate abstraction allows digital circuit designers to create large analog circuits without doing analog circuit design, we present **cryptographic capabilities** as an abstraction allowing a similar economy of engineering effort in creating smart contracts. We explain the E system, which embodies these principles, and show a covered-call-option as a smart contract written in a simple security formalism independent of cryptography, but automatically implemented as a cryptographic protocol coordinating five mutually suspicious parties.

## Summary

### Motivation: the abstraction problem

Designing cryptographic protocols is hard and expensive, and every new smart contract among mutually suspicious parties effectively needs a new one. To make cryptographically-enabled electronic commerce scale to an unlimited variety of contracts, we need an abstraction that factors out the cryptographic machinery — analogous to how the digital logic gate lets circuit designers build large systems without doing analog design per gate.

### The Granovetter Diagram as a unifying abstraction

The paper bridges three communities — object programming, capability-secure operating systems, and financial cryptography — around a single abstraction: the **Granovetter Diagram** (sociologist Mark Granovetter's notation for how interpersonal connections form over time as people introduce people they know). The diagram captures the fundamental "message send" / capability-handoff step:

> Alice has access to Bob; Alice sends Bob a reference to Carol; now Bob has access to Carol.

The paper presents this abstraction from **six perspectives**:

1. **Objects** — the basic message-send step of object computation.
2. **Capability security** — the foundation for access control: capability = unforgeable reference + authority to invoke.
3. **Cryptographic protocol** — a protocol implementing distributed capabilities across untrusted networks.
4. **Public key infrastructure** — certificates act like messages, transmitting authorization among players.
5. **Game rules** — secure computation as a vast multi-player game.
6. **Financial bearer instruments** — material from which to build diverse instruments.

### The E system and the covered-call option

The authors are building **E**, a simple, secure, distributed, pure-object, persistent programming language blending the lambda calculus, capability security, and modern cryptography. E brings the Granovetter operator to life across all six perspectives.

As a worked example, the paper shows a **covered-call option** written as a smart contract in E's simple, cryptography-independent security formalism — and automatically implemented as a cryptographic protocol coordinating **five mutually suspicious parties** (buyer, seller, issuer, assurance party, and mint). The same contract code expresses the logic; the platform supplies the cryptography.

### The mint/purse pattern

The paper introduces the **mint/purse** pattern for electronic bearer instruments: a *mint* creates purses holding amounts of a currency, and purses can transfer amounts to one another while preserving conservation of money. This pattern and its **amount math** properties (no inflation, no double-spending, conservation) have remained essentially unchanged in all subsequent Agoric work.

### Relation to the literature review

The review cites this paper as the origin of the **mint/purse pattern and amount math properties** that are "essentially unchanged since the 2000 paper on capability-based financial instruments." It is the foundational technical paper: it establishes the capability abstraction for smart contracts, the E language, and the patterns (mint/purse, escrow) that the [2013 Dr. SES paper](2013-distributed-electronic-rights.md) ports to JavaScript and the [2015](2015-reasoning-risk-trust.md)–[2022](2022-necessity-specifications.md) papers then formalise.