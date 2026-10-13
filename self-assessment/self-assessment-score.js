#!/usr/bin/env node
//
// Rechnet den EU Cloud Sovereignty Self-Assessment-Score für den openEduSuite-
// SCS-Cluster aus. Nutzt die Daten aus dem cloud-sovereignty-score-Tool.
//
//   SCOPE=~/git/cloud-sovereignty-score node self-assessment/self-assessment-score.js
//
// Fehlt der SCOPE-Ordner, wird versucht, ihn via git zu holen.
const fs = require('fs'), vm = require('vm'), cp = require('child_process');

const scope = process.env.SCOPE || (async () => {
  const p = require('os').homedir() + '/git/cloud-sovereignty-score';
  if (fs.existsSync(p + '/questions.js')) return p;
  cp.execSync('git clone --depth 1 https://github.com/flavienbwk/cloud-sovereignty-score.git ' + p);
  return p;
})();

const src = fs.readFileSync(scope + '/questions.js', 'utf8')
  .replace('const assessmentData = ', 'globalThis.assessmentData = ');
const ctx = {}; vm.createContext(ctx); vm.runInContext(src, ctx);
const D = ctx.assessmentData;

// ---- Antwort-Mapping (Answer-Index pro Kriterium, 0-basiert) ----
// Begründung je Kriterium: siehe self-assessment/EU-sovereignty-assessment.md
const A = {
  'SOV-1': [3, 4, 3, 4, 4, 2, 3, 4],
  'SOV-2': [2, 1, 4, 4, 2, 2],
  'SOV-3': [4, 3, 2, 4, 2],
  'SOV-4': [4, 4, 3, 3, 2, 4],
  'SOV-5': [1, 1, 1, 2, 3, 3, 3],
  'SOV-6': [4, 3, 4, 4, 1],
  'SOV-7': [1, 2, 3, 3, 2, 4, 3],
  'SOV-8': [0, 2, 0, 1],
};
const divisor = D.framework.scoreDivisor || 1000;
let weighted = 0, overallSeal = null;
const res = {};
D.objectives.forEach((o, i) => {
  const ans = A[o.code];
  let score = 0, max = 0, objSeal = null;
  o.questions.forEach((q, j) => {
    const a = q.answers[ans[j]];
    max += Math.max(...q.answers.map(x => x.value));
    score += a.value;
    if (overallSeal === null || a.seal < overallSeal) overallSeal = a.seal;
    if (objSeal === null || a.seal < objSeal) objSeal = a.seal;
  });
  res[o.code] = { w: o.weight, pct: Math.round(score / max * 100), seal: objSeal };
  weighted += o.weight * score;
});
const seal = s => D.sealLevels.find(x => x.level === s).code;

console.log('=== SOVEREIGNTY SCORE ===', (Math.min(weighted / divisor, 1) * 100).toFixed(1) + '%',
  '(' + Math.round(weighted) + '/' + divisor + ')');
console.log('=== OVERALL SEAL ===', seal(overallSeal));
D.objectives.forEach(o => {
  const r = res[o.code];
  console.log(`${o.code} ${o.name.padEnd(30)} w${Math.round(r.w * 100)}%  ${String(r.pct).padStart(3)}%  ${seal(r.seal)}`);
});
console.log('--- binding criteria at SEAL ' + overallSeal + ' ---');
D.objectives.forEach(o => {
  o.questions.forEach((q, j) => {
    const a = q.answers[A[o.code][j]];
    if (a.seal === overallSeal) console.log(`  ${o.code} Q${q.number}: ${a.label.trim()} [${a.value}pts]`);
  });
});