// no-closures, exo-style rendition of makeCounter.
//
// Faithful to the exo model (@endo/exo defineExoClass):
//   - state is a plain sealed record (here { count: 0 }), NOT a closed-over
//     cell. It lives in a per-instance context { state, self } that the
//     runtime looks up via a WeakMap keyed by the instance.
//   - methods are defined ONCE and shared on the class prototype. They never
//     capture state. Instead each method receives the context as an argument
//     and reads/writes context.state.
//   - authority is possession of the reference, not capture in a closure.
//
// This is the first-order shape we would actually verify: finite dispatch
// entries over a state record, no higher-order values. See
// theories/jessie/docs/exos-like-actors.md.

// The shared method table. Each entry is a plain function over the context;
// none of them close over any per-instance state.
const counterMethods = harden({
  incr: context => {
    context.state.count += 1;
    return context.state.count;
  },
  decr: context => {
    context.state.count -= 1;
    return context.state.count;
  },
});

// init returns the fresh state record for a new instance.
const initCounterState = () => harden({ count: 0 });

const makeCounter = () =>
  defineExoClass('Counter', undefined, initCounterState, counterMethods);

// The separation-of-duties client: hand out only upward authority.
const c = makeCounter();
const cUp = { incr: c.incr };
attacker(cUp);
assert(0 < c.incr());
