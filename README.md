# Camuverse Smart Contracts

This repository contains the core smart contracts for the Camuverse project (CammunityDAO, CamuToken, Treasury, Staking, Creator Tokens, Verification/Gating, etc.).

## Security & Sovereignty Requirements

**Critical**: This project involves real value and on-chain governance. All development and deployment work that touches private keys or privileged contract actions **must** follow the sovereignty rules defined in:

→ [SOVEREIGNTY_REQUIREMENTS.md](./SOVEREIGNTY_REQUIREMENTS.md)

Key rule: No external or cloud-based inference provider may ever see or be used in a context containing wallet private keys or signing material. All such work must be performed exclusively through the local Device Execution Plane using local inference only.

## Contracts

- `CammunityDAO.sol`
- `CamuToken.sol`
- `TreasuryContract.sol`
- `CamuMarket.sol`
- `CamuVerify.sol`
- `GatingRegistry.sol`
- `CAMTStakingVault.sol`
- `CreatorToken.sol` + `CreatorTokenFactory.sol`
- `VestingWrapper.sol`

## Current Deployment (Base mainnet)

See the latest addresses and status in the frontend repository (`camuverse-web/PLAN.md`).

## Development Notes

Deployment and privileged actions must be executed under the constraints described in `SOVEREIGNTY_REQUIREMENTS.md`. This is both a security requirement and a validation target for the broader Peregrines Troika architecture (specifically the Device Execution Plane and local secret resolution guarantees).

## Internal Documentation

This repository also contains `INTERNAL_REALITY.md`, which is the transparent, non-marketing assessment of the current state of the project, major gaps, risks, and smart contract hygiene issues. 

Anyone doing serious work on Camuverse (especially anything involving keys, deployments, or governance) should read it.
