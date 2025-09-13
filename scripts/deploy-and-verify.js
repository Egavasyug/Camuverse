// SPDX-License-Identifier: MIT
// One-shot: deploy proxy, print addresses, verify implementation on BaseScan
// Usage examples:
//  - npx hardhat run scripts/deploy-and-verify.js --network base
//  - npx hardhat run scripts/deploy-and-verify.js --network baseSepolia
const { ethers, upgrades, run } = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deployer:', deployer.address);

  const camuVerify = process.env.CAMU_VERIFY || ethers.ZeroAddress;
  const camuCoin = process.env.CAMU_COIN || ethers.ZeroAddress;
  const camuToken = process.env.CAMU_TOKEN || ethers.ZeroAddress;
  const treasury = process.env.TREASURY || ethers.ZeroAddress;
  const bootstrapAdmin = process.env.BOOTSTRAP_ADMIN || deployer.address;

  if (!process.env.PRIVATE_KEY) {
    console.warn('Warning: PRIVATE_KEY not set in env (are you using a local signer?)');
  }

  // Deploy proxy
  const DAO = await ethers.getContractFactory('ModifiedCammunityDAOUpgradeable');
  const dao = await upgrades.deployProxy(
    DAO,
    [camuVerify, camuCoin, camuToken, treasury, bootstrapAdmin],
    { kind: 'transparent', initializer: 'initialize' }
  );
  await dao.waitForDeployment();
  const proxy = await dao.getAddress();
  console.log('DAO proxy at:', proxy);

  // Resolve implementation
  const impl = await upgrades.erc1967.getImplementationAddress(proxy);
  console.log('DAO implementation at:', impl);

  // Submit verification for implementation
  try {
    console.log('Submitting verification for implementation...');
    await run('verify:verify', { address: impl, constructorArguments: [] });
    console.log('Verification submitted.');
  } catch (e) {
    console.error('Verification error:', e.message || e);
    console.error('If indexing is delayed, re-run: npm run verify:impl');
  }
}

main().catch((e) => { console.error(e); process.exit(1); });

