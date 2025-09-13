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

## Deploy + Upgrade (Proxy)

We include an upgradeable DAO variant using a Transparent Proxy.

Env setup (.env):

```
BASE_RPC_URL=YOUR_BASE_RPC_URL
PRIVATE_KEY=0xYourPrivateKey

# Deploy parameters
CAMU_VERIFY=0x...
CAMU_COIN=0x...
CAMU_TOKEN=0x...
TREASURY=0x...
BOOTSTRAP_ADMIN=0x...

# Upgrade parameter
DAO_PROXY=0x...   # deployed proxy address
```

Deploy proxy:

```
npm run compile
npx hardhat run scripts/deploy-dao-proxy.js --network base
```

This deploys a proxy for `ModifiedCammunityDAOUpgradeable` and prints the proxy and implementation addresses.

Bootstrap and finalize (one-time):

```
# Using Hardhat console or a small script, call on the proxy instance:
dao.bootstrapSetAddresses($CAMU_VERIFY, $CAMU_COIN, $CAMU_TOKEN, $TREASURY)
dao.finalizeSetup()
```

Point Treasury to the new DAO (as Treasury owner):

```
treasury.setDAO(<proxyAddress>)
```

Upgrade flow:

1) Modify `contracts/ModifiedCammunityDAOUpgradeable.sol` as needed
2) `npm run compile`
3) Ensure `.env` has `DAO_PROXY`
4) `npx hardhat run scripts/upgrade-dao.js --network base`

The script prepares a new implementation (for review/verification) and upgrades the proxy.
