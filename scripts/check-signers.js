const hre = require('hardhat');
async function main(){
  const signers = await hre.ethers.getSigners();
  console.log('signers:', signers.length);
  if (signers[0]) console.log('addr0:', await signers[0].getAddress());
}
main().catch(e=>{console.error(e);process.exit(1)});
