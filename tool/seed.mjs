
import { readFileSync } from 'node:fs';

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!keyPath) {
  console.error(
    'Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON path.',
  );
  process.exit(1);
}

const { initializeApp, cert } = await import('firebase-admin/app');
const { getAuth } = await import('firebase-admin/auth');
const { getFirestore, Timestamp } = await import('firebase-admin/firestore');

initializeApp({
  credential: cert(JSON.parse(readFileSync(keyPath, 'utf8'))),
  projectId: 'incident-report-5a32a',
});

const auth = getAuth();
const db = getFirestore();

const accounts = [
  {
    email: 'amina.hassan@campus.edu',
    password: 'campus123',
    name: 'Amina Hassan',
    department: 'Computer Science',
    location: 'Kigali Campus',
    role: 'student',
  },
  {
    email: 'jean.habimana@campus.edu',
    password: 'campus123',
    name: 'Jean Habimana',
    department: 'Facilities',
    location: 'Kigali Campus',
    role: 'staff',
  },
  {
    email: 'admin@campus.edu',
    password: 'campus123',
    name: 'Campus Admin',
    department: 'Facilities',
    location: 'Kigali Campus',
    role: 'admin',
  },
];

async function upsert(account) {
  let user;
  try {
    user = await auth.getUserByEmail(account.email);
    await auth.updateUser(user.uid, {
      password: account.password,
      displayName: account.name,
    });
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    user = await auth.createUser({
      email: account.email,
      password: account.password,
      displayName: account.name,
    });
  }
  await db.doc(`users/${user.uid}`).set({
    name: account.name,
    email: account.email,
    department: account.department,
    location: account.location,
    role: account.role,
  });
  return user.uid;
}

function at(iso) {
  return Timestamp.fromDate(new Date(iso));
}

function history(entries) {
  return entries.map(([status, iso]) => ({ status, at: at(iso) }));
}

function reports(reporterId) {
  const reporterName = 'Amina Hassan';
  return [
    {
      id: 'seed-1',
      title: 'No water in Block B',
      category: 'water',
      location: 'Block B, Room 204',
      description: 'Taps in the second-floor bathrooms have been dry since morning.',
      status: 'submitted',
      createdAt: '2026-11-10T08:30:00.000Z',
      statusHistory: history([['submitted', '2026-11-10T08:30:00.000Z']]),
    },
    {
      id: 'seed-2',
      title: 'Power outage in the library',
      category: 'electricity',
      location: 'Main library, 1st floor',
      description: 'Lights and sockets on the first floor cut out during the afternoon.',
      status: 'submitted',
      createdAt: '2026-11-09T14:00:00.000Z',
      statusHistory: history([['submitted', '2026-11-09T14:00:00.000Z']]),
    },
    {
      id: 'seed-3',
      title: 'Broken window in Lab 2',
      category: 'facilities',
      location: 'Science block, Lab 2',
      description: 'The window by the fume cupboard is cracked and does not close.',
      status: 'inProgress',
      createdAt: '2026-11-06T09:15:00.000Z',
      statusHistory: history([
        ['submitted', '2026-11-06T09:15:00.000Z'],
        ['inProgress', '2026-11-07T11:00:00.000Z'],
      ]),
    },
    {
      id: 'seed-4',
      title: 'Damaged chairs in Room 204',
      category: 'furniture',
      location: 'Block B, Room 204',
      description: 'Four lecture chairs have broken backs and are not safe to sit on.',
      status: 'inProgress',
      createdAt: '2026-11-04T10:00:00.000Z',
      statusHistory: history([
        ['submitted', '2026-11-04T10:00:00.000Z'],
        ['inProgress', '2026-11-05T08:40:00.000Z'],
      ]),
    },
    {
      id: 'seed-5',
      title: 'Blocked toilets in Hostel A',
      category: 'sanitation',
      location: 'Hostel A, ground floor',
      description: 'The ground-floor toilets have been blocked and smelling for two days.',
      status: 'resolved',
      createdAt: '2026-10-28T07:45:00.000Z',
      statusHistory: history([
        ['submitted', '2026-10-28T07:45:00.000Z'],
        ['inProgress', '2026-10-28T13:00:00.000Z'],
        ['resolved', '2026-10-29T16:20:00.000Z'],
      ]),
    },
    {
      id: 'seed-6',
      title: 'Loose railing on the east stairs',
      category: 'safety',
      location: 'East stairwell, Block C',
      description: 'The handrail between the first and second floor moves when you hold it.',
      status: 'resolved',
      createdAt: '2026-10-20T12:10:00.000Z',
      statusHistory: history([
        ['submitted', '2026-10-20T12:10:00.000Z'],
        ['inProgress', '2026-10-21T09:00:00.000Z'],
        ['resolved', '2026-10-22T15:30:00.000Z'],
      ]),
    },
  ].map((report) => ({
    id: report.id,
    data: {
      title: report.title,
      category: report.category,
      location: report.location,
      description: report.description,
      photoUrl: null,
      status: report.status,
      statusHistory: report.statusHistory,
      reporterId,
      reporterName,
      createdAt: at(report.createdAt),
    },
  }));
}

const studentId = await upsert(accounts[0]);
for (const account of accounts.slice(1)) {
  await upsert(account);
}

const batch = db.batch();
for (const report of reports(studentId)) {
  batch.set(db.doc(`reports/${report.id}`), report.data);
}
await batch.commit();

console.log('Seeded:');
for (const account of accounts) {
  console.log(`  ${account.email} / ${account.password} (${account.role})`);
}
console.log('  6 reports');
