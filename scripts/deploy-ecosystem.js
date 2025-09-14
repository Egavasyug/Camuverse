// SPDX-License-Identifier: MIT
// Deploy Cammunity ecosystem contracts with fast defaults and wire to DAO proxy
// Usage: npx hardhat run scripts/deploy-ecosystem.js --network base
const fs = require('fs');
const path = require('path');
const hre = require('hardhat');
const { ethers } = hre;

const DAO_PROXY = process.env.DAO_PROXY || '0xF5dbA67c3803833836259720f1cDFd0725468dAc';

function loadDeployed(network) {
  try {
    const p = path.join(process.cwd(), 'deployments', `${network}.json`);
    if (fs.existsSync(p)) return JSON.parse(fs.readFileSync(p, 'utf8') || '[]');
  } catch (_) {}
  return [];
}

function record(network, name, address, extras = {}) {
  const outDir = path.join(process.cwd(), 'deployments');
  const outFile = path.join(outDir, `${network}.json`);
  fs.mkdirSync(outDir, { recursive: true });
  const arr = loadDeployed(network);
  arr.push({ name, address, timestamp: new Date().toISOString(), ...extras });
  fs.writeFileSync(outFile, JSON.stringify(arr, null, 2));
}

function find(deployed, name) {
  const rec = [...deployed].reverse().find((r) => r.name === name);
  return rec ? rec.address : undefined;
}

async function deployOrSkip(name, factoryFqn, argsFn) {
  const net = hre.network.name;
  const existing = find(loadDeployed(net), name);
  if (existing) {
    console.log(`${name}: ${existing} (existing)`);
    return existing;
  }
  const F = await ethers.getContractFactory(factoryFqn);
  const args = await argsFn();
  const fee = await ethers.provider.getFeeData();
  const opts = {};
  if (fee.maxFeePerGas) {
    opts.maxFeePerGas = fee.maxFeePerGas + fee.maxFeePerGas / 5n;
    opts.maxPriorityFeePerGas = (fee.maxPriorityFeePerGas || 0n) + 1_000_000n;
  }
  const c = await F.deploy(...args, opts);
  await c.waitForDeployment();
  const addr = await c.getAddress();
  console.log(`${name}: ${addr}`);
  record(net, name, addr);
  await new Promise((r) => setTimeout(r, 1500));
  return addr;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const net = hre.network.name;
  console.log('Deployer:', deployer.address);
  console.log('DAO proxy:', DAO_PROXY);

  // 1) CamuVerify
  const camuVerifyAddr = await deployOrSkip(
    'CamuVerify',
    'contracts/CamuVerify.sol:CamuVerify',
    async () => []
  );

  // 2) Treasury (fast default: 1-of-1 with deployer)
  const treasuryAddr = await deployOrSkip(
    'MultiSigTreasury',
    'contracts/TreasuryContract.sol:MultiSigTreasury',
    async () => [[deployer.address], 1]
  );

  // 3) CAMT (initialSupply=0, owner=DAO)
  const camuTokenAddr = await deployOrSkip(
    'CamuToken',
    'contracts/CamuToken.sol:CamuToken',
    async () => [0n, DAO_PROXY, deployer.address, treasuryAddr]
  );

  // 4) CAMC (fee token)
  const camuCoinAddr = await deployOrSkip(
    'CamuCoin',
    'contracts/CamuCoin.sol:CamuCoin',
    async () => [treasuryAddr, deployer.address]
  );

  // 5) Staking Vault (CAMT rewards CAMC)
  const vaultAddr = await deployOrSkip(
    'CAMTStakingVault',
    'contracts/CAMTStakingVault.sol:CAMTStakingVault',
    async () => [camuTokenAddr, camuCoinAddr]
  );

  // Update CAMC wallets now that vault exists
  const camuCoin = await ethers.getContractAt('contracts/CamuCoin.sol:CamuCoin', camuCoinAddr);
  await (await camuCoin.setWallets(treasuryAddr, vaultAddr)).wait();
  console.log('CAMC wallets set -> dao:', treasuryAddr, 'lpVault:', vaultAddr);

  // 6) GatingRegistry (uses CamuVerify)
  const gatingAddr = await deployOrSkip(
    'GatingRegistry',
    'contracts/GatingRegistry.sol:GatingRegistry',
    async () => [camuVerifyAddr]
  );

  // 7) CreatorTokenFactory (gated by CamuVerify)
  const factoryAddr = await deployOrSkip(
    'CreatorTokenFactory',
    'contracts/CreatorTokenFactory.sol:CreatorTokenFactory',
    async () => [camuVerifyAddr]
  );

  // 8) CamuMarket (camuCoin, founder, dao treasury)
  const marketAddr = await deployOrSkip(
    'CamuMarket',
    'contracts/CamuMarket.sol:NFTMarketplace',
    async () => [camuCoinAddr, deployer.address, treasuryAddr]
  );

  // 9) Bootstrap DAO with addresses, then finalize
  const dao = await ethers.getContractAt('contracts/ModifiedCammunityDAOUpgradeable.sol:ModifiedCammunityDAOUpgradeable', DAO_PROXY);
  await (await dao.bootstrapSetAddresses(camuVerifyAddr, camuCoinAddr, camuTokenAddr, treasuryAddr)).wait();
  console.log('DAO bootstrapSetAddresses done');
  await (await dao.finalizeSetup()).wait();
  console.log('DAO finalizeSetup done');

  // 10) Transfer ownerships of Verify/CAMT/CAMC to DAO
  const camuVerify = await ethers.getContractAt('contracts/CamuVerify.sol:CamuVerify', camuVerifyAddr);
  const camuToken = await ethers.getContractAt('contracts/CamuToken.sol:CamuToken', camuTokenAddr);
  await (await camuVerify.transferOwnership(DAO_PROXY)).wait();
  await (await camuToken.transferOwnership(DAO_PROXY)).wait();
  await (await camuCoin.transferOwnership(DAO_PROXY)).wait();
  console.log('Ownership of Verify, CAMT, CAMC transferred to DAO');

  // 11) Treasury handoff: set DAO on treasury (as owner)
  const treasury = await ethers.getContractAt('contracts/TreasuryContract.sol:MultiSigTreasury', treasuryAddr);
  await (await treasury.setDAO(DAO_PROXY)).wait();
  console.log('Treasury setDAO ->', DAO_PROXY);

  console.log('Done. Addresses recorded at deployments/%s.json', net);
}

main().catch((e) => { console.error(e); process.exit(1); });
