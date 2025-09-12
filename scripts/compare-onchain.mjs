import fs from 'fs';
import path from 'path';
import solc from 'solc';

// On-chain deployment details
const ADDRESS = '0xa5A750f3eF47fc35e5c1Af2c54C1182Abb392125';
const RPC = 'https://mainnet.base.org';

// Use the verified flatten included in this repo
const FLATTEN = path.resolve(process.cwd(), 'verified/0xa5a750f3ef47fc35e5c1af2c54c1182abb392125/Flattened.sol');

function stripMeta(hex) {
  if (!hex || hex === '0x') return hex;
  const h = hex.startsWith('0x') ? hex.slice(2) : hex;
  if (h.length < 4) return '0x' + h;
  const last4 = h.slice(-4);
  const metaLen = parseInt(last4, 16);
  const total = metaLen * 2 + 4;
  if (total > h.length) return '0x' + h;
  return '0x' + h.slice(0, h.length - total);
}

async function getCode(addr) {
  const res = await fetch(RPC, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'eth_getCode', params: [addr, 'latest'] })
  });
  const j = await res.json();
  return (j.result || '0x').toLowerCase();
}

async function main() {
  if (!fs.existsSync(FLATTEN)) {
    console.error('Flattened.sol not found at', FLATTEN);
    process.exit(1);
  }
  const src = fs.readFileSync(FLATTEN, 'utf8');
  const input = {
    language: 'Solidity',
    sources: { 'Flattened.sol': { content: src } },
    settings: {
      // Match basescan settings: optimizer disabled, but runs listed as 200
      optimizer: { enabled: false, runs: 200 },
      outputSelection: { '*': { '*': ['evm.deployedBytecode.object'] } }
    }
  };
  const out = JSON.parse(solc.compile(JSON.stringify(input)));
  if (out.errors) {
    const fatal = out.errors.filter(e => e.severity === 'error');
    if (fatal.length) {
      console.error('Compile errors:\n' + fatal.map(e => e.formattedMessage).join('\n'));
      process.exit(1);
    }
  }
  const contracts = out.contracts['Flattened.sol'];
  const names = Object.keys(contracts);
  const target = names.includes('CammunityDAO') ? 'CammunityDAO' : (names.includes('ModifiedCammunityDAO') ? 'ModifiedCammunityDAO' : names[0]);
  const local = '0x' + contracts[target].evm.deployedBytecode.object.toLowerCase();
  const localStripped = stripMeta(local);
  const onchain = await getCode(ADDRESS);
  const onchainStripped = stripMeta(onchain);
  console.log('Contract:', target);
  console.log('Local len:', (localStripped.length - 2) / 2);
  console.log('Onchain len:', (onchainStripped.length - 2) / 2);
  console.log('MATCH:', localStripped === onchainStripped ? 'yes' : 'no');
}

main().catch(e => { console.error(e); process.exit(1); });
