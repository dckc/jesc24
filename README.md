# Toward Robust Safety of escrow in Hardened JavaScript

The essential properties of the [Zoe](https://docs.agoric.com/guides/zoe/) escrow service are the same as the 42 line escrow contract in the [2013 Dr. SES paper](lit-review/2013-distributed-electronic-rights.md).

We aim to formally verify robust safety of the escrow contract using the approach from the [2017 OCPL paper](lit-review/2017-robust-compositional-verification.md), based on Iris and Roq/coq. We use a [literature review](lit-review/literature-review.md) to guide this work.

The [plan](https://github.com/agoric-labs/jesc24/issues/2) is as follows:

- [ ] robust safety of escrow
    - [x] Menhir-based parser for Jessie
        - [x] fragment sufficient for `makeCounter`
        - [x] " for `escrow2013.js`
    - [ ] lowering of Jessica AST to HLA / heap lang
        - [x] sufficient for `makeCounter`
        - [ ] sufficient for `escrow2013`
            - [ ] `throw` - abrupt completion result
    - [x] separation of duties: robust safety of `makeCounter`
    - [ ] adequate approximation of possible behaviors of untrusted code

[Jessie In Iris for Robust Safety](theories/jessie/docs/jessie-iris.md) presents the results to date.

[Rocq Core: CIC Reduction & Kernel](theories/jessie/docs/rocq-core.md) presents the position that while it remains essential that we understand the statement of the theorems, we are content with any Roq proof that checks because
1. The atomic proof steps (reductions) are reasonably clear.
2. The ~10K LOC of code that checks compositions of them is mature.
