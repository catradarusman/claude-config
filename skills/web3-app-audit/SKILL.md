---
name: web3-app-audit
description: >
  Security audit for the Witness frontend and API (Next.js 16 route handlers,
  viem, EIP-712 consent, server-side pool store). Covers signature
  verification and replay, the blind-read guarantee, server-only module
  leakage, filesystem store integrity, and RPC/chain-id correctness. Use
  before touching anything in app/app/api or app/lib/{consent,pool,wallet,
  wire,api}.ts, before exposing the app publicly, and whenever the user says
  "audit the app", "is the API safe", "check the signature verification",
  "review the pool", or asks about replay, CSRF, secret leakage, or address
  spoofing.
license: MIT
---

# Web3 app audit — Witness

Audit `app/` for the ways a stranger can break the piece or a subject can
break their own anonymity. Findings must be concrete: a request an attacker
sends, and what they get. Skip generic web advice that does not apply to a
Next.js route handler.

## Ground truth first

- `app/AGENTS.md` — Next.js 16 has breaking API changes vs training data. Read
  it before asserting anything about route handler or `cookies()`/`headers()`
  semantics.
- `app/lib/consent.ts` — the EIP-712 domain, types, and statement.
- `app/lib/pool.ts` — server-only, filesystem-backed, enforces permanence and
  `witness !== subject`.
- `app/app/api/{seal,pool,me,witness}/route.ts` — the whole attack surface.

## Signature and identity

The server must never trust a client-supplied address. Every claim of "I am
0x…" has to be recovered from a signature, not read from the body.

- **`seal`**: recover the signer with `verifyTypedData` and check the recovered
  address equals `message.subject` case-insensitively (checksum vs lowercase
  mismatch is a real bug — normalize with `getAddress`). Rejecting is the
  default; a verification that only logs on failure is critical.
- **Replay.** `sealedAt` is in the signed struct — check it is actually
  enforced: bounded freshness window, and the same signature cannot seal twice.
  Since a sealed reading is permanent, a second seal for the same subject must
  be rejected, not silently overwrite (an overwrite also violates the
  permanence rule in `pool.ts`).
- **Cross-domain replay.** `CONSENT_DOMAIN` pins `chainId: 1` and
  `verifyingContract: 0x0`. The zero address means these signatures are valid
  only against this prototype and must be re-signed at launch. Confirm that is
  still documented at the call site, and that nothing else in the org reuses
  the name/version pair.
- **`witness`**: the witnessing must be authenticated the same way. An
  unauthenticated `POST /api/witness` lets anyone burn any pool entry with an
  arbitrary witness address. Check `witness !== subject` is enforced
  server-side, address-normalized, and not merely checked in the UI.
- **`me`**: whatever identifies the caller must be a signature or a session
  bound to one — never a query parameter or header the caller chooses.

## The blind read

The piece requires a witness to browse without seeing whose history it is.

- `GET /api/pool` must return the handle `id` and the reading only. Grep the
  response shape for `subject`, `signature`, and anything address-shaped. A
  field stripped in the React component but present in the JSON is a full
  break — check the network payload, not the rendered page.
- The reading itself can deanonymize: exact `balanceWei`, exact first-tx
  timestamp, and exact tx counts are near-unique fingerprints against a public
  chain index. Judge whether the exposed fields are bucketed enough, and say
  plainly if they are not.
- Enumeration: can a witness iterate `id`s, or correlate pool order with seal
  order, to link entries to `seal` timing?

## Server/client boundary

- `pool.ts` touches `node:fs` and is server-only. Grep for any import of it
  from a client component or from anything reachable by `"use client"`. Also
  check nothing re-exports it through a shared barrel.
- Any secret (`MAINNET_RPC_URL`, Etherscan key) must never appear under a
  `NEXT_PUBLIC_` name and must never be sent to the browser. Grep
  `NEXT_PUBLIC_` and confirm each one is genuinely public.
- Check `.env.local` is gitignored and that no key is hardcoded as a fallback
  default in source.

## Filesystem store

`pool.ts` reads and writes one JSON file at `.data/pool.json`.

- **Concurrency.** Read-modify-write with no lock loses entries under
  concurrent requests. Two seals landing together can drop one permanently —
  in a piece whose whole claim is permanence. Flag it, and note that this
  disappears when the contract becomes the store.
- **Path traversal.** Any `id` or address that reaches `join()` must be
  validated. Confirm `id` is generated server-side, not client-supplied.
- **Untrusted deserialization.** `BigInt(s.balanceWei)` on a corrupted or
  attacker-influenced string throws and can 500 the whole pool read.
- Confirm there is genuinely no update and no delete path, including via
  object spread in an unrelated handler.

## Request hygiene

- Validate and bound every body field before use — length caps on strings, type
  checks on numbers. `JSON.parse` of an unbounded body is a cheap DoS.
- Rate limit `seal` and `witness`, or say explicitly that they are unprotected.
- Error responses must not echo stack traces, file paths, or the RPC URL.
- Confirm route handlers are not accidentally statically cached (a cached
  `pool` response serves stale or cross-user data).

## RPC correctness

Known live bug: `MAINNET_RPC_URL` in `app/.env.local` serves **Sepolia**
(chainId 11155111) while Etherscan reads mainnet, so readings are mixed —
history from mainnet, `txCount` and balance from Sepolia, and legibility
computed from both. Verify the chain id at runtime before trusting any reading:

```bash
cd app && node -e "fetch(process.env.MAINNET_RPC_URL,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:1,method:'eth_chainId',params:[]})}).then(r=>r.json()).then(console.log)"
```

Recommend asserting the chain id at client construction so this cannot recur
silently.

## Verify

```bash
cd app && npx vitest run
```

Every finding gets a failing test where one is expressible (`pool.test.ts` is
the model). Signature and authorization findings should always be testable.

## Output

`app/path/file.ts:LINE — SEVERITY: <what breaks>. <the request an attacker sends>. <fix>.`

Severity: **critical** (identity spoofable, blind read broken, secret leaked),
**high** (permanence or `witness !== subject` breakable, replay), **medium**
(DoS, data loss, enumeration), **low** (hardening). Most severe first, no
praise, one line per category that came back clean.
