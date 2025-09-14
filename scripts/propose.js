// SPDX-License-Identifier: MIT
// Governance proposal builder: creates TEXT proposals describing parameter changes
// Usage examples:
//  - npx hardhat run scripts/propose.js --network base updateDurations 259200 604800 "Set Stage1=3d, Stage2=7d"
//  - npx hardhat run scripts/propose.js --network base updateStage1Threshold 15 "Set Stage1 threshold to 15%"
//  - npx hardhat run scripts/propose.js --network base addVerifier 0xVerifier "Add initial verifier"

const hre = require('hardhat');
const { ethers } = hre;

const DAO = process.env.DAO_PROXY || '0xF5dbA67c3803833836259720f1cDFd0725468dAc';
const CAMU_VERIFY = process.env.CAMU_VERIFY || '';

const ProposalType = {
  TEXT: 0,
  FUNDING: 1,
  TERMINATION: 2,
};

function encodeCall({ kind, args }) {
  // Build informational calldata for future self-call execution
  if (kind === 'updateDurations') {
    const [s1, s2] = args;
    const iface = new ethers.Interface(['function updateDurations(uint256,uint256)']);
    return { target: DAO, data: iface.encodeFunctionData('updateDurations', [s1, s2]) };
  }
  if (kind === 'updateStage1Threshold') {
    const [p] = args;
    const iface = new ethers.Interface(['function updateStage1Threshold(uint256)']);
    return { target: DAO, data: iface.encodeFunctionData('updateStage1Threshold', [p]) };
  }
  if (kind === 'addVerifier') {
    const [addr] = args;
    const verify = CAMU_VERIFY || '<SET_CAMU_VERIFY_ENV>'; // informational only
    const iface = new ethers.Interface(['function addVerifier(address)']);
    return { target: verify, data: iface.encodeFunctionData('addVerifier', [addr]) };
  }
  return { target: ethers.ZeroAddress, data: '0x' };
}

async function main() {
  const [deployer] = await ethers.getSigners();
  const net = hre.network.name;
  const [cmd, ...rest] = process.argv.slice(2);
  if (!cmd) {
    console.log('Commands: updateDurations s1 s2 [desc] | updateStage1Threshold percent [desc] | addVerifier addr [desc]');
    process.exit(1);
  }

  let description = ''; let args = [];
  if (cmd === 'updateDurations') {
    if (rest.length < 2) throw new Error('Usage: updateDurations <s1Seconds> <s2Seconds> [description]');
    const [s1, s2, ...desc] = rest;
    args = [BigInt(s1), BigInt(s2)];
    description = desc.join(' ') || `Update durations: stage1=${s1}s, stage2=${s2}s`;
  } else if (cmd === 'updateStage1Threshold') {
    if (rest.length < 1) throw new Error('Usage: updateStage1Threshold <percent> [description]');
    const [p, ...desc] = rest;
    args = [BigInt(p)];
    description = desc.join(' ') || `Update Stage1 threshold to ${p}%`;
  } else if (cmd === 'addVerifier') {
    if (rest.length < 1) throw new Error('Usage: addVerifier <verifierAddress> [description]');
    const [addr, ...desc] = rest;
    args = [addr];
    description = desc.join(' ') || `Add verifier ${addr}`;
  } else {
    throw new Error(`Unknown command: ${cmd}`);
  }

  // Build informational calldata and print it for auditability
  const { target, data } = encodeCall({ kind: cmd, args });
  console.log('DAO:', DAO);
  console.log('Action:', cmd);
  console.log('Call target:', target);
  console.log('Call data:', data);

  // Create TEXT proposal (ProposalType.TEXT=0). Note: current DAO impl does not auto-execute arbitrary calls.
  const dao = await ethers.getContractAt('contracts/ModifiedCammunityDAOUpgradeable.sol:ModifiedCammunityDAOUpgradeable', DAO);
  console.log('Creating proposal... (requires CAMC balance)');
  const tx = await dao.createProposal(
    `${description} | target=${target} data=${data}`,
    ProposalType.TEXT,
    ethers.ZeroAddress,
    0
  );
  const rc = await tx.wait();
  const ev = rc.logs.find((l) => {
    try { return (dao.interface.parseLog(l).name === 'NewProposal'); } catch { return false }
  });
  if (ev) {
    const parsed = dao.interface.parseLog(ev);
    console.log('New proposal:', parsed.args.id.toString());
  } else {
    console.log('Proposal created. Inspect tx:', tx.hash);
  }

  console.log('\nNext steps:');
  console.log('- Stage 1 voters (verified CAMC holders) voteStage1(proposalId)');
  console.log('- Stage 2 voters (CAMT weighted) voteStage2(proposalId) after Stage 1 passes');
  console.log('- executeProposal(proposalId) after Stage 2 window ends');
  console.log('\nNote: The current DAO impl records intent but does not execute arbitrary calls. We can upgrade the DAO to add self-call execution for PARAM updates.');
}

main().catch((e) => { console.error(e); process.exit(1); });
