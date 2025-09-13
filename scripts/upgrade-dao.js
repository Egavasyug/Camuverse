// SPDX-License-Identifier: MIT
// Usage: set DAO_PROXY in env, then: npx hardhat run scripts/upgrade-dao.js --network base
const { ethers, upgrades } = require('hardhat');

async function main() {
  const proxy = process.env.DAO_PROXY;
  if (!proxy) throw new Error('Missing DAO_PROXY in environment');

  const [deployer] = await ethers.getSigners();
  console.log('Upgrader:', deployer.address);
  console.log('Target proxy:', proxy);

  const DAO = await ethers.getContractFactory('ModifiedCammunityDAOUpgradeable');

  // Optional: Prepare the implementation first (useful for review/verification)
  console.log('Preparing new implementation...');
  const impl = await upgrades.prepareUpgrade(proxy, DAO);
  console.log('Prepared implementation at:', impl);

  // Perform the upgrade
  console.log('Upgrading proxy...');
  const upgraded = await upgrades.upgradeProxy(proxy, DAO);
  await upgraded.waitForDeployment();

  const implAfter = await upgrades.erc1967.getImplementationAddress(proxy);
  console.log('Upgrade complete. Current implementation:', implAfter);
}

main().catch((e) => { console.error(e); process.exit(1); });

