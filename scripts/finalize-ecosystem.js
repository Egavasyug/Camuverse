const hre = require('hardhat');
const { ethers } = hre;
const DAO = process.env.DAO_PROXY || '0xF5dbA67c3803833836259720f1cDFd0725468dAc';
async function main(){
  const net = hre.network.name; const fee = await ethers.provider.getFeeData();
  const bump = (x)=> x ? x + x/5n : undefined;
  const opts = fee.maxFeePerGas ? { maxFeePerGas: bump(fee.maxFeePerGas), maxPriorityFeePerGas: (fee.maxPriorityFeePerGas||0n)+1_000_000n } : {};
  const arr = require(`../deployments/${net}.json`);
  const find=(n)=>[...arr].reverse().find(r=>r.name===n)?.address;
  const dao = await ethers.getContractAt('contracts/ModifiedCammunityDAOUpgradeable.sol:ModifiedCammunityDAOUpgradeable', DAO);
  console.log('Finalizing DAO setup...');
  try { await (await dao.finalizeSetup(opts)).wait(); console.log('finalizeSetup ok'); } catch(e){ console.log('finalizeSetup skip/err:', e.message||e); }
  const camuVerify = await ethers.getContractAt('contracts/CamuVerify.sol:CamuVerify', find('CamuVerify'));
  const camuToken = await ethers.getContractAt('contracts/CamuToken.sol:CamuToken', find('CamuToken'));
  const camuCoin  = await ethers.getContractAt('contracts/CamuCoin.sol:CamuCoin',  find('CamuCoin'));
  console.log('Transferring ownerships to DAO...');
  try { await (await camuVerify.transferOwnership(DAO, opts)).wait(); } catch(e){ console.log('verify owner:', e.message||e) }
  try { await (await camuToken.transferOwnership(DAO, opts)).wait(); } catch(e){ console.log('token owner:', e.message||e) }
  try { await (await camuCoin.transferOwnership(DAO, opts)).wait(); } catch(e){ console.log('coin owner:', e.message||e) }
  const treasury = await ethers.getContractAt('contracts/TreasuryContract.sol:MultiSigTreasury', find('MultiSigTreasury'));
  try { await (await treasury.setDAO(DAO, opts)).wait(); console.log('treasury setDAO ok'); } catch(e){ console.log('treasury setDAO:', e.message||e) }
}
main().catch(e=>{ console.error(e); process.exit(1); });
