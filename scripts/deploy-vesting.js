// SPDX-License-Identifier: MIT
// Deploy VestingWrapper with mock oracles/metrics
// Usage: npx hardhat run scripts/deploy-vesting.js --network base
const fs = require('fs');
const path = require('path');
const hre = require('hardhat');
const { ethers } = hre;

function loadDeployed(network) {
  try {
    const p = path.join(process.cwd(), 'deployments', `${network}.json`);
    if (fs.existsSync(p)) return JSON.parse(fs.readFileSync(p, 'utf8') || '[]');
  } catch (_) {}
  return [];
}

function record(network, name, address, extras = {}) {
  const outDir = path.join(process.cwd(), 'deployments');
  const outFile = path.join(outDir, `${network}.json`);
  fs.mkdirSync(outDir, { recursive: true });
  const arr = loadDeployed(network);
  arr.push({ name, address, timestamp: new Date().toISOString(), ...extras });
  fs.writeFileSync(outFile, JSON.stringify(arr, null, 2));
}

function findAddress(deployed, name) {
  const rec = [...deployed].reverse().find((r) => r.name === name);
  return rec ? rec.address : undefined;
}

async function main() {
  const net = hre.network.name;
  const [deployer] = await ethers.getSigners();
  console.log('Network:', net);
  console.log('Deployer:', deployer.address);

  const deployed = loadDeployed(net);
  const camuVerify = findAddress(deployed, 'CamuVerify');
  if (!camuVerify) throw new Error('Missing CamuVerify in deployments');

  // Helper: deploy with generous EIP-1559 fees
  async function deployWithFeeBump(fqn, ...args) {
    const F = await ethers.getContractFactory(fqn);
    const opts = { maxFeePerGas: 5_000_000_000n, maxPriorityFeePerGas: 2_000_000_000n };
    const c = await F.deploy(...args, opts);
    await c.waitForDeployment();
    return c;
  }

  // 1) Deploy mocks (admin = deployer) or reuse existing
  let contentAddr = findAddress(deployed, 'ContentOracleMock');
  if (!contentAddr) {
    const contentOracle = await deployWithFeeBump('contracts/mocks/ContentOracleMock.sol:ContentOracleMock');
    contentAddr = await contentOracle.getAddress();
    console.log('ContentOracleMock:', contentAddr);
    record(net, 'ContentOracleMock', contentAddr);
    await new Promise((r) => setTimeout(r, 8000));
  } else {
    console.log('ContentOracleMock (existing):', contentAddr);
  }

  let metricsAddr = findAddress(deployed, 'GatingMetricsMock');
  if (!metricsAddr) {
    const gatingMetrics = await deployWithFeeBump('contracts/mocks/GatingMetricsMock.sol:GatingMetricsMock');
    metricsAddr = await gatingMetrics.getAddress();
    console.log('GatingMetricsMock:', metricsAddr);
    record(net, 'GatingMetricsMock', metricsAddr);
    await new Promise((r) => setTimeout(r, 8000));
  } else {
    console.log('GatingMetricsMock (existing):', metricsAddr);
  }

  // 2) Deploy VestingWrapper with (verify, metrics, content)
  const wrapper = await deployWithFeeBump('contracts/VestingWrapper.sol:VestingWrapper', camuVerify, metricsAddr, contentAddr);
  const wrapperAddr = await wrapper.getAddress();
  console.log('VestingWrapper:', wrapperAddr);
  record(net, 'VestingWrapper', wrapperAddr);

  // 3) Verify on explorer
  try {
    await new Promise((r) => setTimeout(r, 4000));
    await hre.run('verify:verify', {
      address: wrapperAddr,
      constructorArguments: [camuVerify, metricsAddr, contentAddr],
      contract: 'contracts/VestingWrapper.sol:VestingWrapper',
    });
    console.log('✓ Verified VestingWrapper');
  } catch (e) {
    console.error('Verify VestingWrapper failed:', e.message || e);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });

