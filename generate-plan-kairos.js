const fs = require('fs');
const vm = require('vm');
const path = require('path');

// Orden intercalado: OT y NT libro por libro
// Genesis → Mateo → Exodo → Marcos → ... → Daniel → Apocalipsis → Oseas...Malaquias
const BOOK_ORDER = [
  ['genesis', 'Génesis'],     ['mateo', 'Mateo'],
  ['exodo', 'Éxodo'],          ['marcos', 'Marcos'],
  ['levitico', 'Levítico'],    ['lucas', 'Lucas'],
  ['numeros', 'Números'],      ['juan', 'Juan'],
  ['deuteronomio', 'Deuteronomio'], ['hechos', 'Hechos'],
  ['josue', 'Josué'],          ['romanos', 'Romanos'],
  ['jueces', 'Jueces'],        ['1_corintios', '1 Corintios'],
  ['rut', 'Rut'],              ['2_corintios', '2 Corintios'],
  ['1_samuel', '1 Samuel'],    ['galatas', 'Gálatas'],
  ['2_samuel', '2 Samuel'],    ['efesios', 'Efesios'],
  ['1_reyes', '1 Reyes'],      ['filipenses', 'Filipenses'],
  ['2_reyes', '2 Reyes'],      ['colosenses', 'Colosenses'],
  ['1_cronicas', '1 Crónicas'],['1_tesalonicenses', '1 Tesalonicenses'],
  ['2_cronicas', '2 Crónicas'],['2_tesalonicenses', '2 Tesalonicenses'],
  ['esdras', 'Esdras'],        ['1_timoteo', '1 Timoteo'],
  ['nehemias', 'Nehemías'],    ['2_timoteo', '2 Timoteo'],
  ['ester', 'Ester'],          ['tito', 'Tito'],
  ['job', 'Job'],              ['filemon', 'Filemón'],
  ['salmos', 'Salmos'],        ['hebreos', 'Hebreos'],
  ['proverbios', 'Proverbios'],['santiago', 'Santiago'],
  ['eclesiastes', 'Eclesiastés'],['1_pedro', '1 Pedro'],
  ['cantares', 'Cantares'],    ['2_pedro', '2 Pedro'],
  ['isaias', 'Isaías'],        ['1_juan', '1 Juan'],
  ['jeremias', 'Jeremías'],    ['2_juan', '2 Juan'],
  ['lamentaciones', 'Lamentaciones'],['3_juan', '3 Juan'],
  ['ezequiel', 'Ezequiel'],    ['judas', 'Judas'],
  ['daniel', 'Daniel'],        ['apocalipsis', 'Apocalipsis'],
  // Restantes AT sin par NT
  ['oseas', 'Oseas'], ['joel', 'Joel'], ['amos', 'Amós'],
  ['abdias', 'Abdías'], ['jonas', 'Jonás'], ['miqueas', 'Miqueas'],
  ['nahum', 'Nahúm'], ['habacuc', 'Habacuc'], ['sofonias', 'Sofonías'],
  ['hageo', 'Hageo'], ['zacarias', 'Zacarías'], ['malaquias', 'Malaquías'],
];

const BIBLE_DIR = path.join(__dirname, 'bible-json-master/procesados');

function loadBook(filename) {
  const filePath = path.join(BIBLE_DIR, filename + '.js');
  const raw = fs.readFileSync(filePath, 'utf8');
  const code = raw.replace(/^export\s+default\s+/, 'module.exports = ');
  const ctx = { module: { exports: null } };
  vm.runInNewContext(code, ctx);
  return ctx.module.exports;
}

function makeLabel(verses) {
  const first = verses[0];
  const last = verses[verses.length - 1];
  if (first.chapter === last.chapter) {
    return `${first.book} ${first.chapter}:${first.verse}-${last.verse}`;
  } else {
    return `${first.book} ${first.chapter}:${first.verse} - ${last.chapter}:${last.verse}`;
  }
}

const DAYS = 365;
const READINGS_PER_DAY = 10;
const TOTAL_READINGS = DAYS * READINGS_PER_DAY; // 3650

// 1. Calcular total versículos en todo el plan
let totalVerses = 0;
const bookData = [];
for (const [file, name] of BOOK_ORDER) {
  const chapters = loadBook(file);
  const verses = [];
  for (let ci = 0; ci < chapters.length; ci++) {
    for (let vi = 0; vi < chapters[ci].length; vi++) {
      verses.push({ book: name, chapter: ci + 1, verse: vi + 1 });
    }
  }
  bookData.push({ name, verses });
  totalVerses += verses.length;
}

process.stderr.write(`Total versículos: ${totalVerses}\n`);
process.stderr.write(`Lecturas objetivo: ${TOTAL_READINGS}\n`);
process.stderr.write(`Versículos por lectura: ${(totalVerses / TOTAL_READINGS).toFixed(2)}\n\n`);

// 2. Distribuir lecturas por libro proporcional a versículos
//    Cada libro tiene sus propias lecturas (sin cruzar libros)
const allReadings = [];
let assignedTotal = 0;

for (let bi = 0; bi < bookData.length; bi++) {
  const { name, verses } = bookData[bi];
  // Lecturas para este libro (proporcional, ajustando último libro)
  const isLast = bi === bookData.length - 1;
  const bookReadings = isLast
    ? TOTAL_READINGS - assignedTotal
    : Math.round(verses.length * TOTAL_READINGS / totalVerses);

  const count = Math.max(1, bookReadings);
  assignedTotal += count;

  for (let i = 0; i < count; i++) {
    const start = Math.round(i * verses.length / count);
    const end = Math.round((i + 1) * verses.length / count);
    allReadings.push(makeLabel(verses.slice(start, Math.min(end, verses.length))));
  }

  process.stderr.write(`${name}: ${verses.length} versículos → ${count} lecturas\n`);
}

// Ajustar si hay diferencia residual
while (allReadings.length < TOTAL_READINGS) allReadings.push(allReadings[allReadings.length - 1]);
while (allReadings.length > TOTAL_READINGS) allReadings.pop();

process.stderr.write(`\nTotal lecturas generadas: ${allReadings.length}\n`);

// 3. Distribuir en 365 días × 10 lecturas
const lines = [];
lines.push('DELETE FROM public.plan_lectura;');

for (let d = 0; d < DAYS; d++) {
  const base = d * READINGS_PER_DAY;
  const dayReadings = allReadings.slice(base, base + READINGS_PER_DAY);
  const dia = d + 1;
  const titulo = `Día ${dia}`;
  const lecturas = JSON.stringify(dayReadings).replace(/'/g, "''");
  lines.push(`INSERT INTO public.plan_lectura (dia, titulo, lecturas) VALUES (${dia}, '${titulo}', '${lecturas}');`);
}

const outPath = path.join(__dirname, 'supabase/plan_kairos.sql');
fs.writeFileSync(outPath, lines.join('\n') + '\n', 'utf8');
process.stderr.write(`\nPlan generado: ${DAYS} días × ${READINGS_PER_DAY} lecturas/día\n`);
process.stderr.write(`Día 1: ${allReadings.slice(0, 3).join(' | ')} ...\n`);
process.stderr.write(`Día 365: ${allReadings.slice(-3).join(' | ')}\n`);
