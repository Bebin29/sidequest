/**
 * Integration Tests – User CRUD & Friendship Flow
 *
 * Diese Tests laufen gegen die echte Datenbank (kein Mocking).
 * Ein Test-Server wird auf einem zufälligen Port gestartet.
 * Jeder Test räumt NUR seine eigenen Daten auf — keine globalen DELETEs.
 */

require('dotenv').config();
const http = require('http');
const route = require('../src/router');
const pool = require('../src/db/pool');

// Sicherheitscheck: Nie gegen Produktions-DB laufen
const dbHost = process.env.DB_HOST || '';
if (!['localhost', '127.0.0.1'].includes(dbHost)) {
    throw new Error(
        `ABBRUCH: DB_HOST ist "${dbHost}" — Integration Tests duerfen nur gegen localhost laufen (SSH-Tunnel noetig). Niemals direkt gegen den Server!`
    );
}

jest.setTimeout(30000);

let server;
let baseURL;

// Sammelt alle IDs die in Tests erstellt werden, damit afterEach sie aufräumt
let createdUserIds = [];
let createdFriendshipIds = [];

// --- HTTP Helper ---

function req(method, path, body) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: new URL(baseURL).port,
            path,
            method,
            headers: { 'Content-Type': 'application/json' },
        };

        const r = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                resolve({
                    status: res.statusCode,
                    body: data ? JSON.parse(data) : null,
                });
            });
        });

        r.on('error', reject);

        if (body) {
            r.write(JSON.stringify(body));
        }
        r.end();
    });
}

// Erstellt einen Test-User und merkt sich die ID zum Aufräumen
async function createTestUser(email, username, displayName) {
    const res = await req('POST', '/api/users', {
        email,
        username,
        display_name: displayName,
    });
    if (res.body && res.body.data && res.body.data.id) {
        createdUserIds.push(res.body.data.id);
    }
    return res;
}

// --- Setup & Teardown ---

beforeAll((done) => {
    server = http.createServer((r, res) => route(r, res));
    server.listen(0, () => {
        const port = server.address().port;
        baseURL = `http://localhost:${port}`;
        done();
    });
});

afterAll(async () => {
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
});

afterEach(async () => {
    // Nur die in diesem Test erstellten Daten aufräumen (Foreign-Key-Reihenfolge)
    for (const id of createdFriendshipIds) {
        await pool.query('DELETE FROM friendships WHERE id = $1', [id]).catch(() => {});
    }
    for (const id of createdUserIds) {
        await pool.query('DELETE FROM friendships WHERE requester_id = $1 OR receiver_id = $1', [id]).catch(() => {});
        await pool.query('DELETE FROM users WHERE id = $1', [id]).catch(() => {});
    }
    createdUserIds = [];
    createdFriendshipIds = [];
});

// =============================================
// Test 1: User CRUD Flow
// =============================================

describe('Integration: User CRUD', () => {
    test('erstellt, liest, aktualisiert und löscht einen User', async () => {
        // 1. User erstellen
        const create = await createTestUser(
            'integration@test.de', 'integrationuser', 'Integration Test'
        );
        expect(create.status).toBe(201);
        expect(create.body.data.username).toBe('integrationuser');
        expect(create.body.data.id).toBeDefined();

        const userId = create.body.data.id;

        // 2. User abrufen
        const get = await req('GET', `/api/users/${userId}`);
        expect(get.status).toBe(200);
        expect(get.body.data.email).toBe('integration@test.de');
        expect(get.body.data.display_name).toBe('Integration Test');

        // 3. User aktualisieren
        const update = await req('PUT', `/api/users/${userId}`, {
            username: 'updateduser',
            bio: 'Neues Bio',
        });
        expect(update.status).toBe(200);
        expect(update.body.data.username).toBe('updateduser');
        expect(update.body.data.bio).toBe('Neues Bio');

        // 4. Aktualisierung prüfen
        const getUpdated = await req('GET', `/api/users/${userId}`);
        expect(getUpdated.status).toBe(200);
        expect(getUpdated.body.data.username).toBe('updateduser');

        // 5. User löschen
        const del = await req('DELETE', `/api/users/${userId}`);
        expect(del.status).toBe(200);

        // 6. User nicht mehr auffindbar
        const getDeleted = await req('GET', `/api/users/${userId}`);
        expect(getDeleted.status).toBe(404);
    });

    test('doppelter Username gibt 409 zurück', async () => {
        await createTestUser('alice-dup@test.de', 'alice_dup_test', 'Alice');

        const duplicate = await createTestUser('alice-dup2@test.de', 'alice_dup_test', 'Alice Zwei');

        expect(duplicate.status).toBe(409);
    });
});

// =============================================
// Test 2: Friendship Flow
// =============================================

describe('Integration: Friendship Flow', () => {
    let aliceId;
    let bobId;

    beforeEach(async () => {
        const alice = await createTestUser('alice-fr@test.de', 'alice_fr_test', 'Alice');
        aliceId = alice.body.data.id;

        const bob = await createTestUser('bob-fr@test.de', 'bob_fr_test', 'Bob');
        bobId = bob.body.data.id;
    });

    test('kompletter Friendship-Lifecycle: anfragen → akzeptieren → entfernen', async () => {
        // 1. Alice schickt Freundschaftsanfrage an Bob
        const sendRes = await req('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob_fr_test',
        });
        expect(sendRes.status).toBe(201);
        expect(sendRes.body.data.status).toBe('pending');
        expect(sendRes.body.data.requester_id).toBe(aliceId);
        expect(sendRes.body.data.receiver_id).toBe(bobId);

        const friendshipId = sendRes.body.data.id;
        createdFriendshipIds.push(friendshipId);

        // 2. Bob sieht die ausstehende Anfrage
        const pending = await req('GET', `/api/friendships/pending/${bobId}`);
        expect(pending.status).toBe(200);
        expect(pending.body.data).toHaveLength(1);
        expect(pending.body.data[0].requester_username).toBe('alice_fr_test');

        // 3. Bob akzeptiert die Anfrage
        const accept = await req('PATCH', `/api/friendships/${friendshipId}`, {
            status: 'accepted',
        });
        expect(accept.status).toBe(200);
        expect(accept.body.data.status).toBe('accepted');
        expect(accept.body.data.accepted_at).toBeDefined();

        // 4. Alice sieht Bob in ihrer Freundesliste
        const friends = await req('GET', `/api/friends/${aliceId}`);
        expect(friends.status).toBe(200);
        expect(friends.body.data).toHaveLength(1);

        // 5. Freundschaft entfernen
        const remove = await req('DELETE', `/api/friendships/${friendshipId}`);
        expect(remove.status).toBe(200);

        // 6. Freundesliste ist leer
        const empty = await req('GET', `/api/friends/${aliceId}`);
        expect(empty.status).toBe(200);
        expect(empty.body.data).toHaveLength(0);
    });

    test('Anfrage ablehnen und erneut senden funktioniert', async () => {
        // 1. Anfrage senden
        const send1 = await req('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob_fr_test',
        });
        expect(send1.status).toBe(201);
        createdFriendshipIds.push(send1.body.data.id);

        // 2. Bob lehnt ab
        const decline = await req('PATCH', `/api/friendships/${send1.body.data.id}`, {
            status: 'declined',
        });
        expect(decline.status).toBe(200);
        expect(decline.body.data.status).toBe('declined');

        // 3. Alice kann erneut anfragen (declined wird zurückgesetzt)
        const send2 = await req('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob_fr_test',
        });
        expect(send2.status).toBe(201);
        expect(send2.body.data.status).toBe('pending');
    });

    test('Freundschaftsanfrage an sich selbst gibt 400', async () => {
        const self = await req('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'alice_fr_test',
        });
        expect(self.status).toBe(400);
    });
});
