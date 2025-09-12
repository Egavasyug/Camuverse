# Camuverse Contracts (Normalized)

- Deployed DAO (Base): 0xa5A750f3eF47fc35e5c1Af2c54C1182Abb392125
- Explorer: https://basescan.org/address/0xa5A750f3eF47fc35e5c1Af2c54C1182Abb392125
- Verified contract name: CammunityDAO
- Compiler: v0.8.30+commit.73712a01
- Optimization: disabled (runs shown as 200)

## Hardhat Setup
- Solidity: ^0.8.20
- OpenZeppelin: ^4.9.5
- Sources live under `contracts/`

## On-chain Bytecode Comparison
We include the verified flatten from BaseScan under `verified/0xa5a7...2125/Flattened.sol` and a reproducibility script.

- Command: `npm run compare`
- Script: `scripts/compare-onchain.mjs`
- Behavior: compiles Flattened.sol with optimizer disabled and compares stripped deployed bytecode with on-chain code from Base RPC.

Expected output shows equal bytecode lengths and `MATCH: yes`.
