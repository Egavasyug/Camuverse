// SPDX-License-Identifier: MIT
// Usage: set DAO_PROXY and ETHERSCAN_API_KEY (or BASESCAN_API_KEY) in .env
// Example: npx hardhat run scripts/verify-impl.js --network base
const { upgrades, run } = require('hardhat');

async function main() {
  const proxy = process.env.DAO_PROXY;
  if (!proxy) throw new Error('Missing DAO_PROXY in env');

  const impl = await upgrades.erc1967.getImplementationAddress(proxy);
  console.log('Proxy:', proxy);
  console.log('Implementation:', impl);

  try {
    await run('verify:verify', {
      address: impl,
      constructorArguments: []
    });
    console.log('Verification submitted.');
  } catch (e) {
    console.error('Verify failed:', e.message || e);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });

