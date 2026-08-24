#!/usr/bin/env node
/*
 * scan-strings.js - pull printable ASCII runs out of a binary and report those matching a regex.
 * Used to recover the G-code/M-code vocabulary and machine-mode names that a locally installed
 * copy of WeCreat MakeIt! uses, for interoperability with hardware the operator owns.
 *
 * Usage: node scan-strings.js <file> <regex> [minRunLength] [maxHits]
 */
const fs = require('fs');
const [, , file, pattern, minLenArg, maxHitsArg] = process.argv;
if (!file || !pattern) { console.error('usage: node scan-strings.js <file> <regex> [minRun] [maxHits]'); process.exit(1); }
const minRun = parseInt(minLenArg || '4', 10);
const maxHits = parseInt(maxHitsArg || '400', 10);
const re = new RegExp(pattern.replace(/^\(\?i\)/, ''), 'i');

const buf = fs.readFileSync(file);
const seen = new Set();
let hits = 0;
let start = -1;

function flush(end) {
  if (start < 0) return;
  const len = end - start;
  if (len >= minRun) {
    const s = buf.toString('latin1', start, end);
    if (re.test(s) && !seen.has(s)) {
      seen.add(s);
      if (hits < maxHits) { console.log(s); hits++; }
    }
  }
  start = -1;
}

for (let i = 0; i < buf.length; i++) {
  const c = buf[i];
  const printable = (c >= 0x20 && c <= 0x7e);
  if (printable) { if (start < 0) start = i; }
  else flush(i);
}
flush(buf.length);
console.error('--- ' + hits + ' unique matching strings (cap ' + maxHits + ') ---');
