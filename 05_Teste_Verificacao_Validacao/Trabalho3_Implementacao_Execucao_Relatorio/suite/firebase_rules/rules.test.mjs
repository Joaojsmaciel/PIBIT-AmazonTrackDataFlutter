// PROC-02 — tabela de decisão de autorização (EAPT-ATD-001, seção 3.4).
// Contas: A barqueiro proprietário, B passageiro, C terceiro autenticado.
//
// RULES=vigente (padrão): docs/FIRESTORE_RULES.txt e docs/STORAGE_RULES.txt
// RULES=proposta: firestore.rules.proposta e storage.rules.proposta

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, query, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';
import { ref, getBytes, uploadBytes } from 'firebase/storage';

const modo = process.env.RULES ?? 'vigente';
const docs = new URL('../../../../docs/', import.meta.url);
const regras =
  modo === 'proposta'
    ? {
        firestore: readFileSync(new URL('firestore.rules.proposta', import.meta.url), 'utf8'),
        storage: readFileSync(new URL('storage.rules.proposta', import.meta.url), 'utf8'),
      }
    : {
        firestore: readFileSync(new URL('FIRESTORE_RULES.txt', docs), 'utf8'),
        storage: readFileSync(new URL('STORAGE_RULES.txt', docs), 'utf8'),
      };

const R = '_root/amazontrackdata';
const A = 'uid-barqueiro-a';
const B = 'uid-passageiro-b';
const C = 'uid-atacante-c';
const D = 'uid-inativo-d';
const N = 'uid-novo-n';
const CHAT = [A, B].sort().join('_');
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0x10]);
const jpeg = { contentType: 'image/jpeg' };

let env;
const fs = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const st = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).storage();

before(async () => {
  console.log(`Regras avaliadas: ${modo}`);
  env = await initializeTestEnvironment({
    projectId: 'demo-atd',
    firestore: { rules: regras.firestore, host: '127.0.0.1', port: 8080 },
    storage: { rules: regras.storage, host: '127.0.0.1', port: 9199 },
  });
});

after(() => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `${R}/users/${A}`), {
      uid: A, fullName: 'Barqueiro A', cpf: '52998224725', userType: 'barqueiro', isActive: true,
    });
    await setDoc(doc(db, `${R}/users/${B}`), {
      uid: B, fullName: 'Passageiro B', cpf: '11144477735', userType: 'passageiro', isActive: true,
    });
    await setDoc(doc(db, `${R}/users/${D}`), {
      uid: D, fullName: 'Inativo D', cpf: '', userType: 'passageiro', isActive: false,
    });
    await setDoc(doc(db, `${R}/cpfs/52998224725`), { uid: A });
    await setDoc(doc(db, `${R}/cpfs/11144477735`), { uid: B });
    await setDoc(doc(db, `${R}/boats/boat-a`), { id: 'boat-a', ownerId: A, name: 'Comandante Silva', isActive: true });
    await setDoc(doc(db, `${R}/locations/${A}/tracks/1757239200000`), { userId: A, tripId: 't1', timestamp: 1757239200000 });
    await setDoc(doc(db, `${R}/chats/${CHAT}`), { participants: [A, B], lastTimestamp: 1 });
    await setDoc(doc(db, `${R}/chats/${CHAT}/messages/m1`), { senderId: B, text: 'Que horas sai?' });
    await setDoc(doc(db, `${R}/scheduledTrips/s1`), { ownerId: A, isCancelled: false });
    await uploadBytes(ref(ctx.storage(), 'boat_images/boat-a.jpg'), JPEG, jpeg);
  });
});

// ── Firestore ──────────────────────────────────────────────────────────────
test('CT-SEG-01 terceiro C não lê o perfil (com CPF) de A', () =>
  assertFails(getDoc(doc(fs(C), `${R}/users/${A}`))));

test('CT-SEG-01 A lê o próprio perfil', () =>
  assertSucceeds(getDoc(doc(fs(A), `${R}/users/${A}`))));

test('CT-SEG-02 anônimo não lê perfil', () =>
  assertFails(getDoc(doc(fs(null), `${R}/users/${A}`))));

test('CT-SEG-02 anônimo não grava localização', () =>
  assertFails(setDoc(doc(fs(null), `${R}/locations/${A}/tracks/1`), { userId: A })));

test('CT-SEG-08 C não altera userType/isActive de A', () =>
  assertFails(updateDoc(doc(fs(C), `${R}/users/${A}`), { userType: 'passageiro', isActive: false })));

test('CT-EMB-02 C não edita a embarcação de A', () =>
  assertFails(updateDoc(doc(fs(C), `${R}/boats/boat-a`), { name: 'Invadido' })));

test('CT-EMB-04 A edita a própria embarcação', () =>
  assertSucceeds(updateDoc(doc(fs(A), `${R}/boats/boat-a`), { name: 'Comandante Silva II' })));

test('CT-HCH-04 C não lê a conversa A–B', () =>
  assertFails(getDoc(doc(fs(C), `${R}/chats/${CHAT}/messages/m1`))));

test('CT-HCH-04 C não grava na conversa A–B', () =>
  assertFails(setDoc(doc(fs(C), `${R}/chats/${CHAT}/messages/m2`), { senderId: C, text: 'oi' })));

test('CT-HCH-04 participante B lê a conversa', () =>
  assertSucceeds(getDoc(doc(fs(B), `${R}/chats/${CHAT}/messages/m1`))));

test('CT-HCH-10 C não grava no histórico de A', () =>
  assertFails(setDoc(doc(fs(C), `${R}/locations/${A}/tracks/2`), { userId: A })));

test('CT-HCH-10 A grava no próprio histórico', () =>
  assertSucceeds(setDoc(doc(fs(A), `${R}/locations/${A}/tracks/2`), { userId: A })));

test('CT-AGE-02 C não cancela a agenda de A', () =>
  assertFails(updateDoc(doc(fs(C), `${R}/scheduledTrips/s1`), { isCancelled: true })));

test('CT-AGE-04 A cancela a própria agenda', () =>
  assertSucceeds(updateDoc(doc(fs(A), `${R}/scheduledTrips/s1`), { isCancelled: true })));

// ── Perfil, conta inativa e unicidade de CPF (DEF-09, DEF-10) ─────────────
const perfil = (uid, cpf) => ({
  uid, email: `${uid}@teste.example`, fullName: 'Novo', cpf,
  userType: 'passageiro', createdAt: 1, isActive: true,
});

test('CT-SEG-08 A não altera o próprio userType nem isActive', async () => {
  await assertFails(updateDoc(doc(fs(A), `${R}/users/${A}`), { userType: 'passageiro' }));
  await assertFails(updateDoc(doc(fs(A), `${R}/users/${A}`), { isActive: false }));
});

test('CT-SEG-08 A atualiza o próprio nome mantendo os campos de controle', () =>
  assertSucceeds(updateDoc(doc(fs(A), `${R}/users/${A}`), {
    uid: A, fullName: 'Barqueiro A Silva', cpf: '52998224725', userType: 'barqueiro', isActive: true,
  })));

test('CT-SEG-05 conta inativa D não se reativa', () =>
  assertFails(updateDoc(doc(fs(D), `${R}/users/${D}`), { isActive: true })));

test('CT-AUT-03 novo usuário N cria perfil e reserva o CPF na mesma operação', () => {
  const db = fs(N);
  const b = writeBatch(db);
  b.set(doc(db, `${R}/users/${N}`), perfil(N, '39053344705'));
  b.set(doc(db, `${R}/cpfs/39053344705`), { uid: N });
  return assertSucceeds(b.commit());
});

test('CT-AUT-03 CPF já reservado por A não é reutilizado por N', () => {
  const db = fs(N);
  const b = writeBatch(db);
  b.set(doc(db, `${R}/users/${N}`), perfil(N, '52998224725'));
  b.set(doc(db, `${R}/cpfs/52998224725`), { uid: N });
  return assertFails(b.commit());
});

test('CT-AUT-03 perfil com CPF sem reserva no índice é negado', () =>
  assertFails(setDoc(doc(fs(N), `${R}/users/${N}`), perfil(N, '39053344705'))));

test('CT-SEG-08 N não cria perfil já inativo nem com outro uid', async () => {
  await assertFails(setDoc(doc(fs(N), `${R}/users/${N}`), { ...perfil(N, ''), isActive: false }));
  await assertFails(setDoc(doc(fs(N), `${R}/users/${N}`), { ...perfil(N, ''), uid: A }));
});

// ── Caixa de entrada do barqueiro (consulta usada pelo app) ────────────────
test('CT-HCH-01 participante lista as próprias conversas', () =>
  assertSucceeds(getDocs(query(collection(fs(B), `${R}/chats`), where('participants', 'array-contains', B)))));

test('CT-HCH-04 C não lista conversas de A', () =>
  assertFails(getDocs(query(collection(fs(C), `${R}/chats`), where('participants', 'array-contains', A)))));

// ── Storage ────────────────────────────────────────────────────────────────
test('CT-EMB-06 dono A envia foto no caminho usado pelo app', () =>
  assertSucceeds(uploadBytes(ref(st(A), 'boat_images/boat-a.jpg'), JPEG, jpeg)));

test('CT-SEG-06 C não substitui a foto da embarcação de A', () =>
  assertFails(uploadBytes(ref(st(C), 'boat_images/boat-a.jpg'), JPEG, jpeg)));

test('CT-SEG-07 gravação fora dos caminhos permitidos é negada', () =>
  assertFails(uploadBytes(ref(st(A), 'outros/arquivo.txt'), new Uint8Array([1]), { contentType: 'text/plain' })));

test('CT-SEG-02 anônimo não lê foto', () =>
  assertFails(getBytes(ref(st(null), 'boat_images/boat-a.jpg'))));
