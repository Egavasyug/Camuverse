// SPDX-License-Identifier: MIT
// Deploy upgradeable VestingWrapperUpg with DAO-controlled setters
// Usage: npx hardhat run scripts/deploy-vesting-upg.js --network base
const fs = require('fs');
const path = require('path');
const hre = require('hardhat');
const { ethers, upgrades } = hre;

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

function findLast(deployed, name) {
  const rec = [...deployed].reverse().find((r) => r.name === name);
  return rec ? rec.address : undefined;
}

async function main() {
  const net = hre.network.name;
  const [deployer] = await ethers.getSigners();
  console.log('Network:', net);
  console.log('Deployer:', deployer.address);

  const deployed = loadDeployed(net);
  const verifyAddr = findLast(deployed, 'CamuVerify');
  const metricsAddr = findLast(deployed, 'GatingMetricsMock') || findLast(deployed, 'GatingMetrics');
  const contentAddr = findLast(deployed, 'ContentOracleMock') || findLast(deployed, 'ContentOracle');
  if (!verifyAddr || !metricsAddr || !contentAddr) {
    throw new Error(`Missing deps. verify=${verifyAddr}, metrics=${metricsAddr}, content=${contentAddr}`);
  }
  console.log('Deps:', { verifyAddr, metricsAddr, contentAddr, owner: DAO_PROXY });

  const F = await ethers.getContractFactory('contracts/VestingWrapperUpg.sol:VestingWrapperUpg');
  const proxy = await upgrades.deployProxy(F, [verifyAddr, metricsAddr, contentAddr, DAO_PROXY], { kind: 'transparent' });
  await proxy.waitForDeployment();
  const proxyAddr = await proxy.getAddress();
  console.log('VestingWrapperUpg (proxy):', proxyAddr);
  record(net, 'VestingWrapperUpg', proxyAddr, { owner: DAO_PROXY });

  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);
  console.log('Implementation:', implAddr);

  try {
    await new Promise((r) => setTimeout(r, 5000));
    await hre.run('verify:verify', { address: implAddr, constructorArguments: [] });
    console.log('✓ Verified implementation');
  } catch (e) {
    console.error('Verify impl failed:', e.message || e);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
