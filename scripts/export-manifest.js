// SPDX-License-Identifier: MIT
// Export a machine-readable manifest of deployed addresses + ABIs for the frontend
// Usage: node scripts/export-manifest.js base
const fs = require('fs');
const path = require('path');

const NETWORK = process.argv[2] || 'base';
const CHAIN_ID = NETWORK === 'base' ? 8453 : NETWORK === 'baseSepolia' ? 84532 : undefined;

function loadJSON(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function readArtifact(file, name) {
  const p = path.join(process.cwd(), 'artifacts', 'contracts', file, `${name}.json`);
  return loadJSON(p);
}

function loadDeployments(net) {
  const p = path.join(process.cwd(), 'deployments', `${net}.json`);
  if (!fs.existsSync(p)) return [];
  return loadJSON(p);
}

function findLast(deployed, name) {
  const rec = [...deployed].reverse().find((r) => r.name === name);
  return rec ? rec.address : undefined;
}

function main() {
  const deployed = loadDeployments(NETWORK);
  if (!deployed.length && NETWORK === 'base') {
    throw new Error('No deployments found for base');
  }

  // Special: DAO proxy from header
  const header = deployed.find((r) => r.network === NETWORK && r.proxy);
  const daoProxy = header ? header.proxy : undefined;

  // Address picks
  const addresses = {
    CammunityDAO: daoProxy,
    CamuVerify: findLast(deployed, 'CamuVerify'),
    MultiSigTreasury: findLast(deployed, 'MultiSigTreasury'),
    CamuToken: findLast(deployed, 'CamuToken'),
    CamuCoin: findLast(deployed, 'CamuCoin'),
    CAMTStakingVault: findLast(deployed, 'CAMTStakingVault'),
    GatingRegistry: findLast(deployed, 'GatingRegistry'),
    CreatorTokenFactory: findLast(deployed, 'CreatorTokenFactory'),
    CamuMarket: findLast(deployed, 'CamuMarket'),
    VestingWrapper: findLast(deployed, 'VestingWrapper') || findLast(deployed, 'VestingWrapperUpg'),
    GatingMetricsMock: findLast(deployed, 'GatingMetricsMock'),
    ContentOracleMock: findLast(deployed, 'ContentOracleMock'),
    EarlyAccessSBT: findLast(deployed, 'EarlyAccessSBT'),
  };

  // Map names to artifact fully-qualified identifiers
  const fqns = {
    CammunityDAO: ['CammunityDAOUpg.sol', 'CammunityDAO'],
    CamuVerify: ['CamuVerify.sol', 'CamuVerify'],
    MultiSigTreasury: ['TreasuryContract.sol', 'MultiSigTreasury'],
    CamuToken: ['CamuToken.sol', 'CamuToken'],
    CamuCoin: ['CamuCoin.sol', 'CamuCoin'],
    CAMTStakingVault: ['CAMTStakingVault.sol', 'CAMTStakingVault'],
    GatingRegistry: ['GatingRegistry.sol', 'GatingRegistry'],
    CreatorTokenFactory: ['CreatorTokenFactory.sol', 'CreatorTokenFactory'],
    CamuMarket: ['CamuMarket.sol', 'NFTMarketplace'],
    VestingWrapper: ['VestingWrapperUpg.sol', 'VestingWrapperUpg'],
    GatingMetricsMock: ['mocks/GatingMetricsMock.sol', 'GatingMetricsMock'],
    ContentOracleMock: ['mocks/ContentOracleMock.sol', 'ContentOracleMock'],
    EarlyAccessSBT: ['EarlyAccessSBT.sol', 'EarlyAccessSBT'],
  };

  const out = {
    network: NETWORK,
    chainId: CHAIN_ID,
    updatedAt: new Date().toISOString(),
    contracts: {},
  };

  for (const [name, address] of Object.entries(addresses)) {
    if (!address) continue;
    const fqn = fqns[name];
    if (!fqn) continue;
    try {
      const art = readArtifact(fqn[0], fqn[1]);
      out.contracts[name] = { address, abi: art.abi };
    } catch (e) {
      console.warn('Skipping', name, '- artifact missing:', fqn?.join(':') || '', e.message);
    }
  }

  const destDir = path.join(process.cwd(), 'deployments');
  fs.mkdirSync(destDir, { recursive: true });
  const dest = path.join(destDir, `manifest.${NETWORK}.json`);
  fs.writeFileSync(dest, JSON.stringify(out, null, 2));
  console.log('Wrote manifest to', dest);
}

main();
