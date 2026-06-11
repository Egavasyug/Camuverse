# Sovereignty & Key Security Requirements

## Core Principle

For all development and operational work involving the Camuverse project (both frontend and smart contracts), **no private key material, wallet credentials, or signing operations may ever be exposed to external or cloud-based inference providers**.

This is a non-negotiable sovereignty requirement.

## Why This Matters

The Camuverse contracts control real value (tokens, staking, treasury, governance, creator economies). Any AI-assisted workflow that touches deployment, privileged contract calls, or key management must treat private keys as strictly local-only assets.

Using cloud LLMs (or any remote inference) for code generation, debugging, or transaction construction while keys are present in context creates an unacceptable attack surface.

## Required Execution Model

All agentic or AI-assisted work on Camuverse **must** follow the Peregrines Troika Device Execution Plane model:

- **Planning & high-level reasoning** may occur in the Control Plane (aaiaas-control-plane / Mews).
- **Code generation, contract interaction, and especially signing/deployment** must be routed exclusively to the **Device Execution Plane** (Home Roost / local peregrine-runtime worker).
- Private keys must be resolved **only** from the local device vault (OS keychain or encrypted local store) at execution time.
- No key material may transit the control plane or any cloud inference path.
- Proof-of-Execution artifacts must be capable of attesting that key material never left the local security boundary.

## Current Implementation Path (2026)

- Primary agent: Falconer Hero (Hermes-based) operating via local inference (currently DGX-Spark / Ollama).
- Future: Integration of a bespoke Hermes fork directly into `peregrine-runtime` as a first-class local execution engine for high-stakes workloads.
- All contract deployment, treasury actions, and privileged governance operations for Camuverse must be executable under the above constraints.

## Verification Criteria

A workflow or agent is considered compliant for Camuverse work only when it can demonstrate:

1. End-to-end development or deployment tasks can be completed using only local inference.
2. Private keys are resolved exclusively within the local execution environment.
3. No key material appears in control plane logs, traces, prompts, or external model contexts.
4. Full audit trail (Proof-of-Execution) is produced for any on-chain action.
5. The same workflow remains functional in air-gapped or sovereign configurations.

## Related Architecture References

- Peregrines Troika Architecture (aaiaas-control-plane)
- Device Execution Plane / Home Roost guarantees
- Local vault secret resolution requirements
- RiskGuard and policy gating for irreversible actions

---

**Status**: This document is the canonical sovereignty requirement for all Camuverse-related development and operations.
