const hre = require('hardhat');
const { ethers } = hre;
const DAO = process.env.DAO_PROXY || '0xF5dbA67c3803833836259720f1cDFd0725468dAc';
async function bumpOpts(mult=2n){ const f= await ethers.provider.getFeeData(); if(!f.maxFeePerGas) return {}; return { maxFeePerGas: f.maxFeePerGas*mult, maxPriorityFeePerGas: (f.maxPriorityFeePerGas||0n)+(2_000_000n) }; }
async function main(){
  const net=hre.network.name; const arr=require(`../deployments/${net}.json`);
  const find=(n)=>[...arr].reverse().find(r=>r.name===n)?.address;
  const camuVerify=await ethers.getContractAt('contracts/CamuVerify.sol:CamuVerify', find('CamuVerify'));
  const camuCoin=await ethers.getContractAt('contracts/CamuCoin.sol:CamuCoin', find('CamuCoin'));
  const treasury=await ethers.getContractAt('contracts/TreasuryContract.sol:MultiSigTreasury', find('MultiSigTreasury'));
  const opts=await bumpOpts(5n);
  try{ await (await camuVerify.transferOwnership(DAO, opts)).wait(); console.log('camuVerify owner -> DAO'); }catch(e){ console.log('verify ow:', e.message||e); }
  try{ await (await camuCoin.transferOwnership(DAO, opts)).wait(); console.log('camuCoin owner -> DAO'); }catch(e){ console.log('coin ow:', e.message||e); }
  try{ await (await treasury.setDAO(DAO, opts)).wait(); console.log('treasury setDAO ok'); }catch(e){ console.log('setDAO:', e.message||e); }
}
main().catch(e=>{ console.error(e); process.exit(1); });

