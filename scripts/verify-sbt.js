// SPDX-License-Identifier: MIT
const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const net = hre.network.name;
  const maybeAddr = process.argv[2];
  let address = maybeAddr;
  if (!address) {
    const p = path.join(process.cwd(), 'deployments', `${net}.json`);
    if (!fs.existsSync(p)) throw new Error('No deployments file found: ' + p);
    const arr = JSON.parse(fs.readFileSync(p, 'utf8'));
    const last = [...arr].reverse().find((r) => r.name === 'EarlyAccessSBT');
    if (!last) throw new Error('No EarlyAccessSBT found in deployments');
    address = last.address;
  }
  console.log('Verifying EarlyAccessSBT at', address, 'on', net);
  await hre.run('verify:verify', {
    address,
    constructorArguments: [],
    contract: 'contracts/EarlyAccessSBT.sol:EarlyAccessSBT',
  });
  console.log('Verified.');
}

main().catch((e) => { console.error(e); process.exit(1); });
