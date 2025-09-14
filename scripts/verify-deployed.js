// SPDX-License-Identifier: MIT
const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const net = hre.network.name;
  if (net !== 'base' && net !== 'baseSepolia') {
    console.log('Network not supported in this script:', net);
  }
  const depPath = path.join(process.cwd(), 'deployments', `${net}.json`);
  const deployments = JSON.parse(fs.readFileSync(depPath, 'utf8'));
  function addr(name) {
    const rec = [...deployments].reverse().find((r) => r.name === name);
    if (!rec) throw new Error('Missing address for ' + name);
    return rec.address;
  }
  const proxy = '0xF5dbA67c3803833836259720f1cDFd0725468dAc';
  const deployer = '0x2f85C4fedA8F939B8E4cDCd071B4CF3F3F02ED5E';
  const camuVerify = addr('CamuVerify');
  const treasury = addr('MultiSigTreasury');
  const camuToken = addr('CamuToken');
  const camuCoin  = addr('CamuCoin');
  const vault     = addr('CAMTStakingVault');
  const gating    = addr('GatingRegistry');
  const factory   = addr('CreatorTokenFactory');
  const market    = addr('CamuMarket');

  const tasks = [
    { name: 'CamuVerify',         fqn: 'contracts/CamuVerify.sol:CamuVerify',                       address: camuVerify, args: [] },
    { name: 'MultiSigTreasury',   fqn: 'contracts/TreasuryContract.sol:MultiSigTreasury',           address: treasury,   args: [[deployer], 1] },
    { name: 'CamuToken',          fqn: 'contracts/CamuToken.sol:CamuToken',                         address: camuToken,  args: [0, proxy, deployer, treasury] },
    { name: 'CamuCoin',           fqn: 'contracts/CamuCoin.sol:CamuCoin',                           address: camuCoin,   args: [treasury, deployer] },
    { name: 'CAMTStakingVault',   fqn: 'contracts/CAMTStakingVault.sol:CAMTStakingVault',           address: vault,      args: [camuToken, camuCoin] },
    { name: 'GatingRegistry',     fqn: 'contracts/GatingRegistry.sol:GatingRegistry',               address: gating,     args: [camuVerify] },
    { name: 'CreatorTokenFactory',fqn: 'contracts/CreatorTokenFactory.sol:CreatorTokenFactory',     address: factory,    args: [camuVerify] },
    { name: 'NFTMarketplace',     fqn: 'contracts/CamuMarket.sol:NFTMarketplace',                   address: market,     args: [camuCoin, deployer, treasury] },
  ];

  for (const t of tasks) {
    try {
      console.log('Verifying', t.name, t.address);
      await hre.run('verify:verify', { address: t.address, constructorArguments: t.args, contract: t.fqn });
      console.log('✓ Verified', t.name, t.address);
    } catch (e) {
      console.error('✗ Failed', t.name, t.address, '-', e.message || e);
    }
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
