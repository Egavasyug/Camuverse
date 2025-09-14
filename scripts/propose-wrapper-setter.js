// SPDX-License-Identifier: MIT
// Propose a DAO config call to update VestingWrapperUpg dependencies
// Usage examples:
//   npx hardhat run scripts/propose-wrapper-setter.js --network base -- action=verify new=0x... [wrapper=0x...]
//   npx hardhat run scripts/propose-wrapper-setter.js --network base -- action=metrics new=0x...
//   npx hardhat run scripts/propose-wrapper-setter.js --network base -- action=content new=0x...
const hre = require('hardhat');
const { ethers } = hre;
const fs = require('fs');
const path = require('path');

const DAO_PROXY = process.env.DAO_PROXY || '0xF5dbA67c3803833836259720f1cDFd0725468dAc';

function loadDeployed(network) {
  try {
    const p = path.join(process.cwd(), 'deployments', `${network}.json`);
    if (fs.existsSync(p)) return JSON.parse(fs.readFileSync(p, 'utf8') || '[]');
  } catch (_) {}
  return [];
}

function findLast(deployed, name) {
  const rec = [...deployed].reverse().find((r) => r.name === name);
  return rec ? rec.address : undefined;
}

function parseArgs() {
  const argv = process.argv.slice(2).filter((a) => a.includes('='));
  const obj = {};
  for (const kv of argv) {
    const [k, v] = kv.split('=');
    obj[k.replace(/^--/, '')] = v;
  }
  return obj;
}

async function main() {
  const net = hre.network.name;
  const args = parseArgs();
  const action = (args.action || '').toLowerCase();
  const newAddr = args.new;
  if (!['verify', 'metrics', 'content'].includes(action)) {
    throw new Error('Missing/invalid action (verify|metrics|content)');
  }
  if (!newAddr || !ethers.isAddress(newAddr)) {
    throw new Error('Missing/invalid new address');
  }

  const deployed = loadDeployed(net);
  const defaultWrapper = findLast(deployed, 'VestingWrapperUpg') || findLast(deployed, 'VestingWrapper');
  const wrapper = args.wrapper || defaultWrapper;
  if (!wrapper) throw new Error('Missing wrapper proxy address (no VestingWrapperUpg in deployments)');

  const [signer] = await ethers.getSigners();
  console.log('Network:', net);
  console.log('Proposer:', signer.address);
  console.log('DAO proxy:', DAO_PROXY);
  console.log('Wrapper proxy:', wrapper);
  console.log('Action:', action, '->', newAddr);

  const W = await ethers.getContractFactory('contracts/VestingWrapperUpg.sol:VestingWrapperUpg');
  const iW = W.interface;
  const fn = action === 'verify' ? 'setVerify' : action === 'metrics' ? 'setMetrics' : 'setContentOracle';
  const data = iW.encodeFunctionData(fn, [newAddr]);

  const DAO = await ethers.getContractFactory('contracts/CammunityDAOUpg.sol:CammunityDAO');
  const dao = DAO.attach(DAO_PROXY);
  const desc = args.desc || `Update VestingWrapper ${fn} to ${newAddr}`;
  const tx = await dao.createConfigProposal(desc, wrapper, data);
  const rc = await tx.wait();

  let createdId;
  for (const log of rc.logs || []) {
    try {
      const parsed = dao.interface.parseLog({ topics: log.topics, data: log.data });
      if (parsed && parsed.name === 'NewProposal') {
        createdId = parsed.args.id?.toString();
        break;
      }
    } catch (_) {}
  }

  console.log('Proposal submitted. Tx:', tx.hash);
  if (createdId !== undefined) console.log('New proposal id:', createdId);
}

main().catch((e) => { console.error(e); process.exit(1); });
