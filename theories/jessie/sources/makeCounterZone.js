// current zone/exo idiom for makeCounter, with a proper first-order facet.
//
// Following @agoric/zone's ExoZone API:
//   zone.exoClassKit(label, interfaceGuardKit, init, methodsKit, options)
// A "kit" is a record of exos that SHARE one state record. There are no
// closures over per-instance state, and methods are exercised by sending
// messages to an exo reference (E(exo).incr()) — you cannot project a bare
// function `exo.incr`.
//
// The counter is three facets sharing state:
//   upCounter   — { incr }
//   downCounter — { decr }
//   counter     — { incr, decr }  (composes the two above)
// The separation-of-duties client hands out only the upCounter facet.

import { M } from '@endo/patterns';

const makeCounterKit = (zone, label = 'Counter') =>
  zone.exoClassKit(
    label,
    {
      upCounter: M.interface('CounterUp', {
        incr: M.call().returns(M.bigint()),
      }),
      downCounter: M.interface('CounterDown', {
        decr: M.call().returns(M.bigint()),
      }),
      counter: M.interface('Counter', {
        incr: M.call().returns(M.bigint()),
        decr: M.call().returns(M.bigint()),
      }),
    },
    () => ({
      count: 0n,
      etc: undefined,
    }),
    {
      upCounter: {
        incr() {
          this.state.count += 1n;
          return this.state.count;
        },
      },
      downCounter: {
        decr() {
          this.state.count -= 1n;
          return this.state.count;
        },
      },
      counter: {
        incr() {
          return this.facets.upCounter.incr();
        },
        decr() {
          return this.facets.downCounter.decr();
        },
      },
    },
    {
      stateShape: {
        count: M.bigint(),
        etc: M.any(),
      },
    },
  );

const zone = makeZone(); // provided by the environment, e.g. HeapZone
const { upCounter, downCounter, counter } = makeCounterKit(zone);
void downCounter; // the down capability is held but not handed out here
const cUp = upCounter;
attacker(cUp);
assert(0n < E(counter).incr());
