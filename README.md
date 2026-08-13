# Toward correct-by-construction escrow in Hardened JavaScript

The essential properties of the [Zoe](https://docs.agoric.com/guides/zoe/) escrow service are the same as the 42 line escrow contract in the [[2013-distributed-electronic-rights|2013 Dr. SES paper]] .

We aim to formally verify robust safety of the escrow contract using the approach from the [[2017-robust-compositional-verification|2017 OCPL paper]]. 

The [plan](https://github.com/agoric-labs/jesc24/issues/2) is as follows:

-  [ ] robust safety of escrow
	   - [x] coq-peg parser for Jessie
	     - [x] fragment sufficient for `makeCounter`
	     - [x] " for `escrow2013.js`
	   - [ ] lowering of Jessica AST to heap lang
	      - [x] sufficient for `makeCounter`
	      - [ ] sufficient for `escrow2013`
	         - [ ] `throw` - abrupt completion result
	   - [x] separation of duties: robust safety of `makeCounter`
	   - [ ] adequate approximation of possible behaviors of untrusted code

We use a [[literature-review]] to guide this work.
