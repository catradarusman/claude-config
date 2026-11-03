---
name: solidity-audit
description: >
  Security audit for the Witness contracts (Foundry, solc 0.8.24, via_ir,
  evm cancun). Covers the mint path, commit-reveal, EIP-5192 soulbound
  NEGATIVE, tradable PRINT, tokenURI purity, and the msg.sender != subject
  invariant. Use before writing or reviewing anything in contracts/src,
  before any testnet or mainnet deploy, and whenever the user says
  "audit the contracts", "is this safe to deploy", "review the mint",
  "check the soulbound", or asks about reentrancy, access control,
  signature replay, or gas griefing in Solidity.
license: MIT
---

# Solidity audit — Witness

Audit `contracts/src` against this piece's actual failure modes. Do not emit a
generic OWASP-style checklist; every finding must name a file, a line, and a
concrete exploit path. If a class of bug cannot exist here, say so in one line
and move on.

## Ground truth first

Read before judging:
- `WITNESS.md` — mechanics. The invariants are the artwork, not policy.
- `CLAUDE.md` — hard invariants.
- `contracts/foundry.toml` — solc 0.8.24, `via_ir = true`, `evm_version = "cancun"`,
  `optimizer_runs = 200`.
- `app/lib/pool.ts` — the storage shape the contract is expected to mirror.

solc 0.8.24 means arithmetic reverts on overflow by default. Do not report
unchecked-math findings unless the code uses an `unchecked` block. `via_ir`
changes stack behaviour and can mask/unmask stack-too-deep — flag only if the
build actually fails.

## The invariants that must hold onchain

1. **`msg.sender != subject` at mint.** Check every path into the mint,
   including any batch/permit/relayer path. A meta-transaction or `multicall`
   that lets a subject sponsor their own witnessing breaks the piece. Named
   attack: subject uses a fresh EOA or a contract they control. That is
   unstoppable at the contract level — say so explicitly rather than claiming
   the check is sufficient.
2. **NEGATIVE is soulbound (EIP-5192).** `locked(tokenId)` must return true for
   every existing NEGATIVE and revert for nonexistent ones. Every transfer path
   must revert: `transferFrom`, `safeTransferFrom` (both arities), `approve`,
   `setApprovalForAll`. Blocking only `transferFrom` is the classic miss —
   ERC721's `safeTransferFrom` may not route through it in every base. Confirm
   the `Locked` event fires at mint.
3. **PRINT is a normal tradable ERC-721.** No accidental lock, no royalty
   enforcement that bricks transfer.
4. **Write-once.** The stored reading and the witnessing are set at mint and
   never mutated. Look for any setter, any owner-only "fix" function, any
   upgrade path. An upgradeable proxy silently voids "permanent" — if one
   exists, that is a top-severity finding against the stated concept.
5. **`tokenURI` is pure.** The image is derived on every read from numbers
   frozen at mint, never stored. Verify `tokenURI` reads only immutable/frozen
   storage and calls only `view`/`pure` render code, so a fresh computation is
   bit-identical forever. Any block-dependent value inside the render path
   (`block.timestamp`, `blockhash`, `prevrandao`, balance) is a bug.

## Commit-reveal

- Commitment must bind **all** of: subject/pool handle, witness address, and a
  salt. A commitment missing the witness address is front-runnable — anyone who
  sees the commit can reveal it first.
- Enforce a minimum block delay between commit and reveal, and check what
  happens at exactly the boundary block.
- Check the abandoned-commit path: can a stale commitment be replayed later, or
  reused for a different subject? Is there a way to grief the pool by committing
  to every entry and never revealing?
- `keccak256(abi.encodePacked(...))` with two adjacent dynamic types is
  ambiguity-prone. Prefer `abi.encode`.

## Standard classes, checked against this code

- **Reentrancy.** `_safeMint` hands control to the receiver via
  `onERC721Received`. Confirm all state (reading, witness, commitment
  consumption) is written *before* the mint call — checks-effects-interactions.
  Two mints in one callback must not both pass a supply or one-per-subject
  check.
- **Access control.** Enumerate every non-view external function and name who
  may call it. Any `onlyOwner` that can touch a minted token's data contradicts
  invariant 4.
- **Signature verification** (if consent is verified onchain): must use
  EIP-712 with the real `verifyingContract`, must reject `s` in the upper half
  order / v not in {27,28} (use OZ `ECDSA`, not raw `ecrecover`), must consume a
  nonce or mark the commitment used so a signature cannot be replayed, and the
  domain must pin `chainId` to block replay on another chain.
- **Unbounded loops** over pool entries or token ids in any function a user
  calls — gas griefing.
- **`address(0)` and self-transfer** edge cases in the mint recipient.
- **ETH handling.** If the mint is payable, check the refund path and that a
  failed `.transfer`/`.call` cannot lock funds or block minting.

## Verify, don't assert

A finding is not reported until it is demonstrated. For each one, write a
Foundry test that fails on current code:

```bash
cd contracts && forge test -vvv
```

Useful passes:

```bash
cd contracts && forge test --match-test invariant -vvv
```

```bash
cd contracts && forge build --sizes
```

Fuzz the mint path (`vm.assume(witness != subject)`), and write an invariant
test asserting no NEGATIVE ever changes owner across a random call sequence.

## Output

One line per finding, most severe first:

`contracts/src/File.sol:LINE — SEVERITY: <what breaks>. <exploit in one sentence>. <fix>.`

Severity: **critical** (funds or token ownership stealable, or a core invariant
breakable by anyone), **high** (breakable by a specific party, or permanence
violated), **medium** (griefing, DoS, or spec drift), **low** (gas, style,
defence in depth). No praise sections. If nothing is found in a category, one
line saying so.
