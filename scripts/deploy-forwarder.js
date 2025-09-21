// SPDX-License-Identifier: MIT
const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const net = hre.network.name;
  const [deployer] = await hre.ethers.getSigners();
  console.log('Network:', net, 'Deployer:', deployer.address);

  const F = await hre.ethers.getContractFactory('MinimalForwarder');
  const forwarder = await F.deploy();
  await forwarder.waitForDeployment();
  const addr = await forwarder.getAddress();
  console.log('MinimalForwarder at', addr);

  const dir = path.join(process.cwd(), 'deployments');
  fs.mkdirSync(dir, { recursive: true });
  const file = path.join(dir, `${net}.json`);
  let arr = [];
  if (fs.existsSync(file)) arr = JSON.parse(fs.readFileSync(file, 'utf8'));
  arr.push({ name: 'MinimalForwarder', address: addr, timestamp: new Date().toISOString() });
  fs.writeFileSync(file, JSON.stringify(arr, null, 2));
}

main().catch((e) => { console.error(e); process.exit(1); });
