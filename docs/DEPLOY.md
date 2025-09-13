# Deploy + Verify (Proxy) — Minimal Walkthrough

This guide deploys the upgradeable DAO proxy, prints both proxy and implementation addresses, and verifies the implementation on BaseScan (or Base Sepolia) in a single run.

## Prerequisites

- Node 18+ and npm
- Hardhat deps installed (this repo already includes them)
- A funded deployer key for the selected network

## 1) Configure `.env`

Copy `.env.example` to `.env` and fill values:

```
# Network
BASE_RPC_URL=...            # For mainnet
BASE_SEPOLIA_RPC_URL=...    # For testnet (optional)
PRIVATE_KEY=0x...

# Etherscan (BaseScan) API key
ETHERSCAN_API_KEY=...       # or BASESCAN_API_KEY=...

# Deploy params (can be zero if you will bootstrap after deploy)
CAMU_VERIFY=0x0000000000000000000000000000000000000000
CAMU_COIN=0x0000000000000000000000000000000000000000
CAMU_TOKEN=0x0000000000000000000000000000000000000000
TREASURY=0x0000000000000000000000000000000000000000
BOOTSTRAP_ADMIN=0xYourEOA
```

Notes:
- If CAMU_* addresses are not known at deploy time, leave them as zero and use the DAO bootstrap functions later: `bootstrapSetAddresses(...)` then `finalizeSetup()`.

## 2) Compile

```
npm run compile
```

## 3) One‑shot deploy + verify

Mainnet (Base):

```
npm run deploy:verify
```

Testnet (Base Sepolia):

```
npm run deploy:verify:test
```

The script will:
- Deploy Transparent Proxy for `ModifiedCammunityDAOUpgradeable`
- Print Proxy and Implementation addresses
- Submit verification for the Implementation to BaseScan

If verification fails due to indexing delay, just re‑run the verify script later:

```
# set DAO_PROXY in .env to the deployed proxy
npm run verify:impl
# or testnet
npm run verify:impl:test
```

## 4) Bootstrap + Treasury handoff

If you deployed with zero CAMU_* addresses, call on the proxy:

```
dao.bootstrapSetAddresses(CAMU_VERIFY, CAMU_COIN, CAMU_TOKEN, TREASURY)
dao.finalizeSetup()
```

As Treasury owner, point spending control at the new DAO:

```
treasury.setDAO(<proxyAddress>)
```

## 5) Future upgrades

Edit `contracts/ModifiedCammunityDAOUpgradeable.sol`, then:

```
# set DAO_PROXY in .env
npm run upgrade:dao        # mainnet
npm run upgrade:dao:test   # testnet

# (re)verify new implementation
npm run verify:impl
```

