// SPDX-License-Identifier: MIT
// Rotate ownership/admin to a new address without touching .env for the new key
// Usage: npx hardhat run scripts/rotate-ownerships.js --network base -- newOwner=0x...
const hre = require('hardhat');
const { ethers } = hre;

const ADDRS = {
  proxyAdmin: '0x8cfc0cdeb12f65286474d6fdb27efe45da660f51',
  treasury: '0xdFB884d7630CD47C539e276aa5a62ce59F607687',
  contentOracle: '0x55822cA226C9dB73dE6EA14B10D5c10abAb4bdd7',
  gatingMetrics: '0x82668948C02a2f9B24c4DC38b350D4d27180C04a',
};

function parseArgs() {
  const obj = {};
  for (const a of process.argv.slice(2)) {
    if (!a.includes('=')) continue;
    const [k, v] = a.split('=');
    obj[k].replace(/^--/, '');
  }
  return obj;
}

async function main() {
  const args = {};
  for (const a of process.argv.slice(2)) {
    if (!a.includes('=')) continue;
    const [k, v] = a.split('=');
    args[k.replace(/^--/, '')] = v;
  }
  const newOwner = args.newOwner || process.env.NEW_OWNER;
  if (!newOwner || !ethers.isAddress(newOwner)) {
    throw new Error('Missing or invalid newOwner. Pass as: -- newOwner=0x...');
  }

  const [signer] = await ethers.getSigners();
  console.log('Network:', hre.network.name);
  console.log('Rotator (current signer):', signer.address);
  console.log('New owner/admin:', newOwner);

  const ownableAbi = [
    'function owner() view returns (address)',
    'function transferOwnership(address newOwner)'
  ];
  const adminAbi = [
    'function admin() view returns (address)',
    'function setAdmin(address newAdmin)'
  ];

  {
    const c = new ethers.Contract(ADDRS.proxyAdmin, ownableAbi, signer);
    const cur = await c.owner();
    console.log('ProxyAdmin owner (before):', cur);
    if (cur.toLowerCase() !== newOwner.toLowerCase()) {
      const tx = await c.transferOwnership(newOwner);
      console.log('ProxyAdmin transferOwnership tx:', tx.hash);
      await tx.wait();
      const after = await c.owner();
      console.log('ProxyAdmin owner (after):', after);
    } else {
      console.log('ProxyAdmin already owned by new owner');
    }
  }

  {
    const c = new ethers.Contract(ADDRS.treasury, ownableAbi, signer);
    const cur = await c.owner();
    console.log('Treasury owner (before):', cur);
    if (cur.toLowerCase() !== newOwner.toLowerCase()) {
      const tx = await c.transferOwnership(newOwner);
      console.log('Treasury transferOwnership tx:', tx.hash);
      await tx.wait();
      const after = await c.owner();
      console.log('Treasury owner (after):', after);
    } else {
      console.log('Treasury already owned by new owner');
    }
  }

  {
    const c = new ethers.Contract(ADDRS.contentOracle, adminAbi, signer);
    const cur = await c.admin();
    console.log('ContentOracle admin (before):', cur);
    if (cur.toLowerCase() !== newOwner.toLowerCase()) {
      const tx = await c.setAdmin(newOwner);
      console.log('ContentOracle setAdmin tx:', tx.hash);
      await tx.wait();
      const after = await c.admin();
      console.log('ContentOracle admin (after):', after);
    } else {
      console.log('ContentOracle already set to new admin');
    }
  }

  {
    const c = new ethers.Contract(ADDRS.gatingMetrics, adminAbi, signer);
    const cur = await c.admin();
    console.log('GatingMetrics admin (before):', cur);
    if (cur.toLowerCase() !== newOwner.toLowerCase()) {
      const tx = await c.setAdmin(newOwner);
      console.log('GatingMetrics setAdmin tx:', tx.hash);
      await tx.wait();
      const after = await c.admin();
      console.log('GatingMetrics admin (after):', after);
    } else {
      console.log('GatingMetrics already set to new admin');
    }
  }

  console.log('Rotation complete.');
}

main().catch((e) => { console.error(e); process.exit(1); });

