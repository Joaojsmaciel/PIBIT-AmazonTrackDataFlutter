// Consolida as saídas da execução (Flutter JSON + JUnit das regras) por caso de teste CT-*.
// Uso: node consolidar_por_caso.mjs  → grava resumo_por_caso.json e imprime a tabela.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, basename } from 'node:path';

const dir = dirname(fileURLToPath(import.meta.url));
const casos = {};
const registrar = (nome, arquivo, resultado) => {
  const ids = new Set();
  for (const m of nome.matchAll(/CT-([A-Z]+)-(\d{2})/g)) ids.add(`CT-${m[1]}-${m[2]}`);
  for (const id of ids) {
    const c = (casos[id] ??= { testes: 0, pass: 0, fail: 0, skip: 0, arquivos: new Set() });
    c.testes++; c[resultado]++; c.arquivos.add(arquivo);
  }
  return ids.size;
};

// Flutter
const suites = {}, testes = {};
let semCaso = 0;
for (const linha of readFileSync(join(dir, 'flutter_test_resultado.json'), 'utf8').split(/\r?\n/)) {
  if (!linha.startsWith('{')) continue;
  const e = JSON.parse(linha);
  if (e.type === 'suite') suites[e.suite.id] = basename(e.suite.path);
  else if (e.type === 'testStart') testes[e.test.id] = e.test;
  else if (e.type === 'testDone' && !e.hidden) {
    const t = testes[e.testID];
    const r = e.skipped ? 'skip' : e.result === 'success' ? 'pass' : 'fail';
    if (!registrar(t.name, suites[t.suiteID], r)) semCaso++;
  }
}

// Regras Firebase (JUnit)
const regras = {};
for (const variante of ['vigente', 'proposta']) {
  const xml = readFileSync(join(dir, `regras_${variante}_junit.xml`), 'utf8');
  const r = { pass: 0, fail: 0 };
  for (const m of xml.matchAll(/<testcase name="([^"]+)"[^>]*?(\/>|>([\s\S]*?)<\/testcase>)/g)) {
    const falhou = /<failure/.test(m[3] || '');
    r[falhou ? 'fail' : 'pass']++;
    if (variante === 'vigente') registrar(m[1].replace(/&quot;/g, '"'), 'rules.test.mjs', falhou ? 'fail' : 'pass');
  }
  regras[variante] = r;
}

const ordem = ['AUT', 'EMB', 'RAS', 'OFF', 'GEO', 'PAS', 'HCH', 'AGE', 'SEG', 'UI', 'NF', 'COM', 'UAT'];
const ids = Object.keys(casos).sort((a, b) => {
  const [, pa, na] = a.split('-'), [, pb, nb] = b.split('-');
  return ordem.indexOf(pa) - ordem.indexOf(pb) || na - nb;
});
const saida = ids.map((id) => {
  const c = casos[id];
  const estado = c.fail ? 'Reprovado' : c.pass ? 'Aprovado' : 'Não executado';
  return { caso: id, estado, testes: c.testes, pass: c.pass, fail: c.fail, skip: c.skip, arquivos: [...c.arquivos].sort() };
});
writeFileSync(join(dir, 'resumo_por_caso.json'), JSON.stringify({ regras, testesSemCaso: semCaso, casos: saida }, null, 2));
for (const s of saida) console.log(`${s.caso}\t${s.estado}\t${s.pass}/${s.testes}\t${s.arquivos.join(', ')}`);
console.log(`\ncasos com teste no computador: ${saida.length}; reprovados: ${saida.filter((s) => s.fail).length}; testes Flutter sem ID de caso: ${semCaso}`);
console.log('regras:', JSON.stringify(regras));
