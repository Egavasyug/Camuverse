// SPDX-License-Identifier: MIT
// Append an alias entry so ' + "'VestingWrapper'" + ' points to the upgradeable proxy,
// and mark previous non-upgradeable VestingWrapper entries as deprecated.
// Usage: node scripts/switch-wrapper-address.js base
const fs = require('fs');
const path = require('path');

const net = process.argv[2] || 'base';
const file = path.join(process.cwd(), 'deployments', `${net}.json`);
if (!fs.existsSync(file)) {
  console.error('deployments file not found:', file);
  process.exit(1);
}

const arr = JSON.parse(fs.readFileSync(file, 'utf8') || '[]');
const proxyRec = [...arr].reverse().find((r) => r.name === 'VestingWrapperUpg');
if (!proxyRec) {
  console.error('No VestingWrapperUpg entry found. Aborting.');
  process.exit(1);
}

const proxyAddr = proxyRec.address;

// Mark any existing VestingWrapper entries that are not the proxy as deprecated
for (const r of arr) {
  if (r.name === 'VestingWrapper' && r.address.toLowerCase() !== proxyAddr.toLowerCase()) {
    r.deprecated = true;
    r.note = `Deprecated in favor of VestingWrapperUpg proxy ${proxyAddr}`;
  }
}

// Append new alias pointing VestingWrapper -> proxy
arr.push({
  name: 'VestingWrapper',
  address: proxyAddr,
  alias: true,
  timestamp: new Date().toISOString(),
  note: 'Alias to upgradeable proxy',
});

fs.writeFileSync(file, JSON.stringify(arr, null, 2));
console.log('Updated', file, '-> VestingWrapper now points to proxy', proxyAddr);
