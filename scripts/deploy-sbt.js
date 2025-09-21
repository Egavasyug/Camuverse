// SPDX-License-Identifier: MIT
const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const net = hre.network.name;
  console.log('Network:', net);
  const [deployer] = await hre.ethers.getSigners();
  console.log('Deployer:', deployer.address);

  const F = await hre.ethers.getContractFactory('EarlyAccessSBT');
  const c = await F.deploy();
  await c.waitForDeployment();
  const addr = await c.getAddress();
  console.log('EarlyAccessSBT deployed at', addr);

  // Append to deployments/<network>.json
  const dir = path.join(process.cwd(), 'deployments');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${net}.json`);
  let arr = [];
  if (fs.existsSync(file)) arr = JSON.parse(fs.readFileSync(file, 'utf8'));
  arr.push({ name: 'EarlyAccessSBT', address: addr, timestamp: new Date().toISOString() });
  fs.writeFileSync(file, JSON.stringify(arr, null, 2));
  console.log('Recorded deployment in', file);
}

main().catch((e) => { console.error(e); process.exit(1); });
