// Usage: npx hardhat run scripts/deploy-dao-proxy.js --network <network>
const { ethers, upgrades } = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deployer:', deployer.address);

  // Fill these in or pass via env
  const camuVerify = process.env.CAMU_VERIFY || ethers.ZeroAddress;
  const camuCoin = process.env.CAMU_COIN || ethers.ZeroAddress;
  const camuToken = process.env.CAMU_TOKEN || ethers.ZeroAddress;
  const treasury = process.env.TREASURY || ethers.ZeroAddress;
  const bootstrapAdmin = process.env.BOOTSTRAP_ADMIN || deployer.address;

  const DAO = await ethers.getContractFactory('ModifiedCammunityDAOUpgradeable');
  const dao = await upgrades.deployProxy(
    DAO,
    [camuVerify, camuCoin, camuToken, treasury, bootstrapAdmin],
    { kind: 'transparent', initializer: 'initialize' }
  );
  await dao.waitForDeployment();
  console.log('DAO proxy deployed at:', await dao.getAddress());

  // Optional: record impl
  const impl = await upgrades.erc1967.getImplementationAddress(await dao.getAddress());
  console.log('DAO implementation at:', impl);
}

main().catch((e) => { console.error(e); process.exit(1); });
