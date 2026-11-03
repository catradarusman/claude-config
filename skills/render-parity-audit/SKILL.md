---
name: render-parity-audit
description: >
  Verify the TypeScript render pipeline (app/lib/sigil.ts, kamea.ts) and the
  Solidity port (contracts/src/WitnessArt.sol, WitnessRenderer.sol) produce
  byte-identical output. Catches float creep, division-rounding drift, and
  silent divergence when either side changes. Use whenever editing sigil.ts,
  kamea.ts, or contracts/src, before a deploy, and when the user says
  "check parity", "do the renders match", "port this to Solidity", or
  reports a token image differing between the site and tokenURI.
license: MIT
---

# Render parity audit

`tokenURI` derives the image on every read from numbers frozen at mint. That
only works if the render is deterministic and if both implementations agree
forever. A one-pixel divergence means the site and the token show different
artworks for the same reading — unfixable after mint, because the numbers are
frozen and the contract is not upgradeable.

Treat any divergence as top severity.

## The invariant

`CLAUDE.md`: the render pipeline is **integer-only** and must stay pixel-parity
with the Solidity port. `contracts/` mirrors `app/lib/` numeric logic 1:1 —
when either changes, both change in the same commit.

## What to check in the TypeScript

Grep `app/lib/sigil.ts` and `app/lib/kamea.ts` for anything that leaves integer
arithmetic:

- `/` on values that are not provably divisible — Solidity truncates toward
  zero, JS does not. Every division must be floored explicitly and the flooring
  must match the sign convention on both sides. Negative operands are where
  this bites.
- `Math.round`, `Math.floor`, `Math.ceil`, `Math.sqrt`, `Math.pow`, `**`,
  `Math.hypot`, `Math.min/max` on non-integers, `toFixed`, any literal with a
  decimal point, any trig.
- `Number` values crossing the safe-integer boundary where Solidity uses
  `uint256`. Anything derived from wei must be `bigint`.
- `%` on negatives — JS keeps the dividend's sign, Solidity also truncates
  toward zero, but a hand-rolled "positive modulo" on one side only is a
  classic drift source.
- Map/Set iteration order or `Object.keys` order feeding output ordering.
- Any string formatting of numbers: locale separators, exponential notation for
  large or small values, `-0`.

## What to check in the Solidity

- Implicit truncation in intermediate steps that the TS performs at a different
  point. Order of operations matters: `(a * b) / c` and `a / c * b` differ.
- `int256` vs `uint256` for any value that can go negative in the TS.
- Fixed-size type overflow in an `unchecked` block.
- SVG string assembly: identical attribute order, identical spacing, identical
  decimal representation, identical path command letters. Byte-parity of the
  SVG is the goal, not merely visual similarity.

## Verify

Run both, compare bytes. Do not eyeball two images.

```bash
cd app && npx vitest run sigil.invariants.test.ts sigil.test.ts kamea.test.ts
```

```bash
cd contracts && forge test --match-contract WitnessRender -vvv
```

Then differential-test across a range of readings, not one sample: pick
boundary readings (zero-activity wallet, single tx, max-legibility, values at
each hue boundary, the largest realistic `totalGasSpentWei`) plus random ones.
Feed the same reading to both and diff the emitted SVG string exactly.

If a differential harness does not exist yet, building one is the correct first
move — a fixture file of readings, TS output written to disk, and a Foundry
test asserting `keccak256(svg)` matches the recorded hash per fixture. That
turns parity into a test that fails on regression instead of a review anyone
can forget to do.

## Also confirm

- Exactly one colored element per token (the mark). The frame is never colored.
  Check both implementations independently.
- NEGATIVE and PRINT differ **only** in colour — identical geometry from
  identical numbers.
- No block-dependent value (`block.timestamp`, `blockhash`, `prevrandao`,
  balance) reaches the render path in Solidity.

## Output

`file:LINE — <TS value> vs <Solidity value> for <input>. <cause>. <fix, applied to both sides>.`

State plainly whether parity is currently proven by a test or only by
inspection. "Looks the same" is not a result.
