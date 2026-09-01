// Behavioural tests for firestore.rules, run against the Firestore emulator.
//
//     cd firestore-tests && npm install
//     ./run.sh
//
// Collection names are read out of the generated ../firestore.rules rather than
// hardcoded, so no real collection name lives in this repository.

import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, addDoc, getDocs, serverTimestamp, Timestamp } from 'firebase/firestore';
import fs from 'fs';

const rules = fs.readFileSync('../firestore.rules', 'utf8');
const names = [...rules.matchAll(/^    match \/([a-zA-Z0-9_]+)\/\{(\w+)\}/gm)].map(m => m[1]);
if (names.length < 3) {
  console.error('could not parse collection names — run ../scripts/generate-firestore-rules.sh first');
  process.exit(1);
}
const [WORDS, CHALLENGES, SUGGESTED] = names;

const testEnv = await initializeTestEnvironment({
  projectId: 'demo-gamoitsani',
  firestore: { rules, host: '127.0.0.1', port: 8677 },
});

await testEnv.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, WORDS, 'w1'), {
    base_word: 'ტესტი', language: 'ka',
    review_stats: { positive_count: 0, negative_count: 2, reviewed_by: ['dev1'] },
  });
  await setDoc(doc(db, CHALLENGES, 'c1'), { text: 'do a thing' });
  await setDoc(doc(db, SUGGESTED, 's1'), { base_word: 'x', language: 'ka', last_updated: Timestamp.now() });
});

// The app never authenticates — FirebaseAuthHelper.ensureAnonymousAuth has zero call
// sites — so every check runs unauthenticated, exactly like the shipped client.
const db = testEnv.unauthenticatedContext().firestore();

const results = [];
const check = async (name, mustPass, op) => {
  try {
    await (mustPass ? assertSucceeds(op()) : assertFails(op()));
    results.push([true, name, mustPass ? 'allowed' : 'denied']);
  } catch {
    results.push([false, name, `UNEXPECTED — wanted ${mustPass ? 'allow' : 'deny'}`]);
  }
};

// Things the shipped app must keep being able to do. A failure here is an outage.
await check('read a word',                 true,  () => getDoc(doc(db, WORDS, 'w1')));
await check('list words',                  true,  () => getDocs(collection(db, WORDS)));
await check('read challenges',             true,  () => getDocs(collection(db, CHALLENGES)));
await check('read suggestions (dedupe)',   true,  () => getDocs(collection(db, SUGGESTED)));
await check('create a valid suggestion',   true,  () => addDoc(collection(db, SUGGESTED), {
  base_word: 'ახალი', language: 'ka', last_updated: serverTimestamp() }));

// The hole being closed. A failure here means the word database is destroyable.
await check('DELETE a word',               false, () => deleteDoc(doc(db, WORDS, 'w1')));
await check('update word review_stats',    false, () => updateDoc(doc(db, WORDS, 'w1'), {
  'review_stats.negative_count': 3 }));
await check('create a word',               false, () => setDoc(doc(db, WORDS, 'evil'), { base_word: 'x' }));
await check('write challenges',            false, () => setDoc(doc(db, CHALLENGES, 'c2'), { text: 'x' }));

// Suggestion payload validation.
await check('suggestion w/ extra field',   false, () => addDoc(collection(db, SUGGESTED), {
  base_word: 'x', language: 'ka', last_updated: serverTimestamp(), is_admin: true }));
await check('suggestion w/ bad language',  false, () => addDoc(collection(db, SUGGESTED), {
  base_word: 'x', language: 'zz', last_updated: serverTimestamp() }));
await check('suggestion w/ client clock',  false, () => addDoc(collection(db, SUGGESTED), {
  base_word: 'x', language: 'ka', last_updated: Timestamp.fromMillis(0) }));
await check('suggestion w/ empty word',    false, () => addDoc(collection(db, SUGGESTED), {
  base_word: '', language: 'ka', last_updated: serverTimestamp() }));
await check('suggestion w/ 500-char word', false, () => addDoc(collection(db, SUGGESTED), {
  base_word: 'a'.repeat(500), language: 'ka', last_updated: serverTimestamp() }));
await check('suggestion w/ wrong types',   false, () => addDoc(collection(db, SUGGESTED), {
  base_word: 123, language: true, last_updated: 'nope' }));
await check('edit a suggestion',           false, () => updateDoc(doc(db, SUGGESTED, 's1'), { base_word: 'y' }));
await check('delete a suggestion',         false, () => deleteDoc(doc(db, SUGGESTED, 's1')));

// Anything not explicitly matched.
await check('read an unlisted collection', false, () => getDocs(collection(db, 'admin_secrets')));
await check('write an unlisted collection',false, () => setDoc(doc(db, 'admin_secrets', 'x'), { a: 1 }));

await testEnv.cleanup();

let failed = 0;
for (const [ok, name, note] of results) {
  if (!ok) failed++;
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${name.padEnd(28)} ${note}`);
}
console.log(`\n  ${results.length - failed}/${results.length} passed`);
process.exit(failed ? 1 : 0);
