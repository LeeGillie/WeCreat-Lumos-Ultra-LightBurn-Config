#!/usr/bin/env node
/*
 * asar-tool.js - minimal, dependency-free reader for Electron .asar archives.
 *
 * Used here to inspect a LOCALLY INSTALLED copy of WeCreat MakeIt! for the purpose of
 * interoperability: discovering the machine definitions and G-code the controller expects,
 * so that a LightBurn device profile can be written for hardware the operator owns.
 * Nothing extracted with this tool may be redistributed in this repository.
 *
 * Usage:
 *   node asar-tool.js list    <app.asar> [substringFilter]
 *   node asar-tool.js cat     <app.asar> <internal/path>            > out.txt
 *   node asar-tool.js extract <app.asar> <internal/path> <outFile>
 *   node asar-tool.js grep    <app.asar> <regex> [globSubstring]    # searches text-ish entries
 */
const fs = require('fs');
const path = require('path');

function openArchive(file) {
  const fd = fs.openSync(file, 'r');
  const sizeBuf = Buffer.alloc(8);
  fs.readSync(fd, sizeBuf, 0, 8, 0);
  // asar layout: [u32 =4][u32 headerSize][u32 headerStringSize][u32 jsonLen][json ...]
  const headerSize = sizeBuf.readUInt32LE(4);
  const hdrBuf = Buffer.alloc(headerSize);
  fs.readSync(fd, hdrBuf, 0, headerSize, 8);
  let json;
  const jsonLen = hdrBuf.readUInt32LE(4);
  const cand = hdrBuf.toString('utf8', 8, 8 + jsonLen);
  if (cand.startsWith('{')) {
    json = cand;
  } else {
    // fall back: locate the JSON object and take everything to the last closing brace
    const s = hdrBuf.toString('utf8');
    const start = s.indexOf('{"files"');
    if (start < 0) throw new Error('could not locate asar header JSON');
    json = s.slice(start, s.lastIndexOf('}') + 1);
  }
  const header = JSON.parse(json);
  const baseOffset = 8 + headerSize;
  return { fd, header, baseOffset };
}

function walk(node, prefix, out) {
  for (const [name, entry] of Object.entries(node.files || {})) {
    const p = prefix ? prefix + '/' + name : name;
    if (entry.files) walk(entry, p, out);
    else out.push({ path: p, size: entry.size || 0, offset: entry.offset, unpacked: !!entry.unpacked });
  }
  return out;
}

function readEntry(a, entry) {
  if (entry.unpacked) return null;
  const buf = Buffer.alloc(entry.size);
  if (entry.size > 0) fs.readSync(a.fd, buf, 0, entry.size, a.baseOffset + Number(entry.offset));
  return buf;
}

function findEntry(a, wanted) {
  const all = walk(a.header, '', []);
  return all.find(e => e.path === wanted || e.path.endsWith('/' + wanted));
}

const [, , cmd, archive, arg1, arg2] = process.argv;
if (!cmd || !archive) { console.error('see header for usage'); process.exit(1); }
const a = openArchive(archive);

if (cmd === 'list') {
  const all = walk(a.header, '', []);
  const filtered = arg1 ? all.filter(e => e.path.toLowerCase().includes(arg1.toLowerCase())) : all;
  filtered.sort((x, y) => y.size - x.size);
  for (const e of filtered) console.log(String(e.size).padStart(12) + '  ' + e.path + (e.unpacked ? '  [UNPACKED]' : ''));
  console.error('--- ' + filtered.length + ' of ' + all.length + ' entries ---');
} else if (cmd === 'cat' || cmd === 'extract') {
  const e = findEntry(a, arg1);
  if (!e) { console.error('not found: ' + arg1); process.exit(2); }
  const buf = readEntry(a, e);
  if (!buf) { console.error('entry is unpacked (lives outside the archive)'); process.exit(3); }
  if (cmd === 'cat') process.stdout.write(buf);
  else { fs.mkdirSync(path.dirname(arg2), { recursive: true }); fs.writeFileSync(arg2, buf); console.error('wrote ' + arg2 + ' (' + buf.length + ' bytes)'); }
} else if (cmd === 'grep') {
  const re = new RegExp(arg1, 'gi');
  const all = walk(a.header, '', []).filter(e => !e.unpacked && e.size > 0 && e.size < 40 * 1024 * 1024);
  const scope = arg2 ? all.filter(e => e.path.toLowerCase().includes(arg2.toLowerCase())) : all;
  let hits = 0;
  for (const e of scope) {
    let buf;
    try { buf = readEntry(a, e); } catch (err) { continue; }
    if (!buf) continue;
    const s = buf.toString('latin1');
    re.lastIndex = 0;
    let m, shown = 0;
    while ((m = re.exec(s)) !== null && shown < 6) {
      const start = Math.max(0, m.index - 90);
      const snippet = s.slice(start, m.index + 130).replace(/[\r\n]+/g, ' ');
      console.log(e.path + ' @' + m.index + ' :: ' + snippet);
      shown++; hits++;
      if (m.index === re.lastIndex) re.lastIndex++;
    }
  }
  console.error('--- ' + hits + ' hits across ' + scope.length + ' entries ---');
}
