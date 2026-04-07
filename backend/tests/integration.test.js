/**
 * Integration Tests – User CRUD & Friendship Flow
 *
 * Diese Tests laufen gegen die echte Datenbank (kein Mocking).
 * Ein Test-Server wird auf einem zufälligen Port gestartet.
 */

require('dotenv').config();
const http = require('http');
const route = require('../src/router');
const pool = require('../src/db/pool');

jest.setTimeout(30000);

let server;
let baseURL;

// --- HTTP Helper ---

function request(method, path, body) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: new URL(baseURL).port,
            path,
            method,
            headers: { 'Content-Type': 'application/json' },
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                resolve({
                    status: res.statusCode,
                    body: data ? JSON.parse(data) : null,
                });
            });
        });

        req.on('error', reject);

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

// --- Setup & Teardown ---

beforeAll((done) => {
    server = http.createServer((req, res) => route(req, res));
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

beforeEach(async () => {
    // Reihenfolge beachten wegen Foreign Keys
    await pool.query('DELETE FROM notifications');
    await pool.query('DELETE FROM comments');
    await pool.query('DELETE FROM ratings');
    await pool.query('DELETE FROM friendships');
    await pool.query('DELETE FROM locations');
    await pool.query('DELETE FROM trips');
    await pool.query('DELETE FROM users');
});

// =============================================
// Test 1: User CRUD Flow
// =============================================

describe('Integration: User CRUD', () => {
    test('erstellt, liest, aktualisiert und löscht einen User', async () => {
        // 1. User erstellen
        const create = await request('POST', '/api/users', {
            email: 'integration@test.de',
            username: 'integrationuser',
            display_name: 'Integration Test',
        });
        expect(create.status).toBe(201);
        expect(create.body.data.username).toBe('integrationuser');
        expect(create.body.data.id).toBeDefined();

        const userId = create.body.data.id;

        // 2. User abrufen
        const get = await request('GET', `/api/users/${userId}`);
        expect(get.status).toBe(200);
        expect(get.body.data.email).toBe('integration@test.de');
        expect(get.body.data.display_name).toBe('Integration Test');

        // 3. User aktualisieren
        const update = await request('PUT', `/api/users/${userId}`, {
            username: 'updateduser',
            bio: 'Neues Bio',
        });
        expect(update.status).toBe(200);
        expect(update.body.data.username).toBe('updateduser');
        expect(update.body.data.bio).toBe('Neues Bio');

        // 4. Aktualisierung prüfen
        const getUpdated = await request('GET', `/api/users/${userId}`);
        expect(getUpdated.status).toBe(200);
        expect(getUpdated.body.data.username).toBe('updateduser');

        // 5. User löschen
        const del = await request('DELETE', `/api/users/${userId}`);
        expect(del.status).toBe(200);

        // 6. User nicht mehr auffindbar
        const getDeleted = await request('GET', `/api/users/${userId}`);
        expect(getDeleted.status).toBe(404);
    });

    test('doppelter Username gibt 409 zurück', async () => {
        await request('POST', '/api/users', {
            email: 'alice@test.de',
            username: 'alice',
            display_name: 'Alice',
        });

        const duplicate = await request('POST', '/api/users', {
            email: 'alice2@test.de',
            username: 'alice',
            display_name: 'Alice Zwei',
        });

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
        // Zwei User erstellen
        const alice = await request('POST', '/api/users', {
            email: 'alice@test.de',
            username: 'alice',
            display_name: 'Alice',
        });
        aliceId = alice.body.data.id;

        const bob = await request('POST', '/api/users', {
            email: 'bob@test.de',
            username: 'bob',
            display_name: 'Bob',
        });
        bobId = bob.body.data.id;
    });

    test('kompletter Friendship-Lifecycle: anfragen → akzeptieren → entfernen', async () => {
        // 1. Alice schickt Freundschaftsanfrage an Bob
        const sendReq = await request('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob',
        });
        expect(sendReq.status).toBe(201);
        expect(sendReq.body.data.status).toBe('pending');
        expect(sendReq.body.data.requester_id).toBe(aliceId);
        expect(sendReq.body.data.receiver_id).toBe(bobId);

        const friendshipId = sendReq.body.data.id;

        // 2. Bob sieht die ausstehende Anfrage
        const pending = await request('GET', `/api/friendships/pending/${bobId}`);
        expect(pending.status).toBe(200);
        expect(pending.body.data).toHaveLength(1);
        expect(pending.body.data[0].requester_username).toBe('alice');

        // 3. Bob akzeptiert die Anfrage
        const accept = await request('PATCH', `/api/friendships/${friendshipId}`, {
            status: 'accepted',
        });
        expect(accept.status).toBe(200);
        expect(accept.body.data.status).toBe('accepted');
        expect(accept.body.data.accepted_at).toBeDefined();

        // 4. Alice sieht Bob in ihrer Freundesliste
        const friends = await request('GET', `/api/friends/${aliceId}`);
        expect(friends.status).toBe(200);
        expect(friends.body.data).toHaveLength(1);

        // 5. Freundschaft entfernen
        const remove = await request('DELETE', `/api/friendships/${friendshipId}`);
        expect(remove.status).toBe(200);

        // 6. Freundesliste ist leer
        const empty = await request('GET', `/api/friends/${aliceId}`);
        expect(empty.status).toBe(200);
        expect(empty.body.data).toHaveLength(0);
    });

    test('Anfrage ablehnen und erneut senden funktioniert', async () => {
        // 1. Anfrage senden
        const send1 = await request('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob',
        });
        expect(send1.status).toBe(201);

        // 2. Bob lehnt ab
        const decline = await request('PATCH', `/api/friendships/${send1.body.data.id}`, {
            status: 'declined',
        });
        expect(decline.status).toBe(200);
        expect(decline.body.data.status).toBe('declined');

        // 3. Alice kann erneut anfragen (declined wird zurückgesetzt)
        const send2 = await request('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'bob',
        });
        expect(send2.status).toBe(201);
        expect(send2.body.data.status).toBe('pending');
    });

    test('Freundschaftsanfrage an sich selbst gibt 400', async () => {
        const self = await request('POST', '/api/friendships', {
            requester_id: aliceId,
            receiver_username: 'alice',
        });
        expect(self.status).toBe(400);
    });
});
