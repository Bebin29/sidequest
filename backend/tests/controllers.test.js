const { Readable } = require('stream');

// --- Mock pg pool ---
const mockQuery = jest.fn();
jest.mock('../src/db/pool', () => ({
    query: (...args) => mockQuery(...args),
}));

const userController = require('../src/controllers/userController');
const locationController = require('../src/controllers/locationController');
const commentController = require('../src/controllers/commentController');
const monitoringController = require('../src/controllers/monitoringController');

// --- Test Helpers ---

function mockRequest(body) {
    const readable = new Readable();
    if (body) {
        readable.push(JSON.stringify(body));
    }
    readable.push(null);
    return readable;
}

function mockResponse() {
    const res = {
        statusCode: null,
        headers: {},
        body: null,
        writeHead(code, headers) {
            res.statusCode = code;
            Object.assign(res.headers, headers);
        },
        end(data) {
            res.body = data ? JSON.parse(data) : null;
        },
        setHeader() {},
    };
    return res;
}

beforeEach(() => {
    mockQuery.mockReset();
});

// --- User Controller Tests ---

describe('userController', () => {
    test('getAll returns users with pagination', async () => {
        const mockUsers = [
            { id: '1', username: 'alice', email: 'alice@test.de' },
            { id: '2', username: 'bob', email: 'bob@test.de' },
        ];
        mockQuery.mockResolvedValueOnce({ rows: mockUsers, rowCount: 2 });

        const res = mockResponse();
        await userController.getAll({}, res, { limit: '10', offset: '0' });

        expect(res.statusCode).toBe(200);
        expect(res.body.data).toHaveLength(2);
        expect(res.body.count).toBe(2);
        expect(mockQuery).toHaveBeenCalledWith(
            expect.stringContaining('SELECT * FROM users'),
            [10, 0]
        );
    });

    test('getAll limits to max 100', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await userController.getAll({}, res, { limit: '999' });

        expect(mockQuery).toHaveBeenCalledWith(
            expect.any(String),
            [100, 0]
        );
    });

    test('getById returns 404 for unknown user', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await userController.getById({}, res, 'nonexistent-id');

        expect(res.statusCode).toBe(404);
        expect(res.body.error).toBe('User not found');
    });

    test('getById returns user', async () => {
        const mockUser = { id: '1', username: 'alice' };
        mockQuery.mockResolvedValueOnce({ rows: [mockUser], rowCount: 1 });

        const res = mockResponse();
        await userController.getById({}, res, '1');

        expect(res.statusCode).toBe(200);
        expect(res.body.data.username).toBe('alice');
    });

    test('create requires email, username, display_name', async () => {
        const req = mockRequest({ email: 'test@test.de' });
        const res = mockResponse();
        await userController.create(req, res);

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('required');
    });

    test('create returns 409 on duplicate', async () => {
        const mockError = new Error('duplicate');
        mockError.code = '23505';
        mockQuery.mockRejectedValueOnce(mockError);

        const req = mockRequest({
            email: 'test@test.de',
            username: 'alice',
            display_name: 'Alice',
        });
        const res = mockResponse();
        await userController.create(req, res);

        expect(res.statusCode).toBe(409);
        expect(res.body.error).toContain('already exists');
    });

    test('create succeeds with valid data', async () => {
        const mockUser = { id: '1', username: 'alice', email: 'alice@test.de' };
        mockQuery.mockResolvedValueOnce({ rows: [mockUser], rowCount: 1 });

        const req = mockRequest({
            email: 'alice@test.de',
            username: 'alice',
            display_name: 'Alice',
        });
        const res = mockResponse();
        await userController.create(req, res);

        expect(res.statusCode).toBe(201);
        expect(res.body.data.username).toBe('alice');
    });

    test('checkUsername returns available true', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await userController.checkUsername({}, res, { username: 'newuser' });

        expect(res.statusCode).toBe(200);
        expect(res.body.available).toBe(true);
    });

    test('checkUsername rejects short usernames', async () => {
        const res = mockResponse();
        await userController.checkUsername({}, res, { username: 'ab' });

        expect(res.statusCode).toBe(400);
    });

    test('remove returns 404 for unknown user', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await userController.remove({}, res, 'nonexistent');

        expect(res.statusCode).toBe(404);
    });
});

// --- Location Controller Tests ---

describe('locationController', () => {
    test('getById returns 404 for unknown location', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await locationController.getById({}, res, 'nonexistent');

        expect(res.statusCode).toBe(404);
        expect(res.body.error).toBe('Location not found');
    });

    test('create requires mandatory fields', async () => {
        const req = mockRequest({ name: 'Test' });
        const res = mockResponse();
        await locationController.create(req, res);

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('required');
    });

    test('create succeeds with valid data', async () => {
        const mockLocation = {
            id: '1',
            name: 'Testcafé',
            category: 'Café',
        };
        mockQuery.mockResolvedValueOnce({ rows: [mockLocation], rowCount: 1 });

        const req = mockRequest({
            name: 'Testcafé',
            address: 'Torstr. 1',
            latitude: 52.53,
            longitude: 13.40,
            category: 'Café',
            created_by: '550e8400-e29b-41d4-a716-446655440000',
        });
        const res = mockResponse();
        await locationController.create(req, res);

        expect(res.statusCode).toBe(201);
        expect(res.body.data.name).toBe('Testcafé');
    });

    test('getFeed returns empty for user with no friends', async () => {
        // friendships query returns empty
        mockQuery.mockResolvedValueOnce({ rows: [] });

        const res = mockResponse();
        await locationController.getFeed({}, res, {
            user_id: '550e8400-e29b-41d4-a716-446655440000',
        });

        expect(res.statusCode).toBe(200);
        expect(res.body.data).toEqual([]);
        expect(res.body.hasMore).toBe(false);
    });

    test('getFeed requires user_id', async () => {
        const res = mockResponse();
        await locationController.getFeed({}, res, {});

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('user_id');
    });

    test('update returns 404 for unknown location', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const req = mockRequest({ name: 'Updated' });
        const res = mockResponse();
        await locationController.update(req, res, 'nonexistent');

        expect(res.statusCode).toBe(404);
    });

    test('remove returns 404 for unknown location', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await locationController.remove({}, res, 'nonexistent');

        expect(res.statusCode).toBe(404);
    });
});

// --- Comment Controller Tests ---

describe('commentController', () => {
    test('getByLocation returns comments', async () => {
        const mockComments = [
            { id: '1', text: 'Toll!', username: 'alice' },
        ];
        mockQuery.mockResolvedValueOnce({ rows: mockComments, rowCount: 1 });

        const res = mockResponse();
        await commentController.getByLocation({}, res, 'location-id');

        expect(res.statusCode).toBe(200);
        expect(res.body.data).toHaveLength(1);
        expect(res.body.data[0].text).toBe('Toll!');
    });

    test('create requires all fields', async () => {
        const req = mockRequest({ location_id: '1', text: 'hi' });
        const res = mockResponse();
        await commentController.create(req, res);

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('required');
    });

    test('create returns 404 for unknown user', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const req = mockRequest({
            location_id: 'loc-1',
            user_id: 'unknown-user',
            text: 'Hello',
        });
        const res = mockResponse();
        await commentController.create(req, res);

        expect(res.statusCode).toBe(404);
        expect(res.body.error).toBe('User not found');
    });

    test('remove returns 404 for unknown comment', async () => {
        mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

        const res = mockResponse();
        await commentController.remove({}, res, 'nonexistent');

        expect(res.statusCode).toBe(404);
    });
});

// --- Monitoring Controller Tests ---

describe('monitoringController', () => {
    test('getStatus returns server info when DB is healthy', async () => {
        mockQuery
            .mockResolvedValueOnce({ rows: [{ server_time: '2026-04-05T12:00:00Z' }] })
            .mockResolvedValueOnce({
                rows: [{ users: 5, locations: 10, ratings: 3, comments: 7, friendships: 2, notifications: 1 }],
            });

        const res = mockResponse();
        await monitoringController.getStatus({}, res);

        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe('ok');
        expect(res.body.server.node_version).toBeDefined();
        expect(res.body.server.uptime_seconds).toBeGreaterThanOrEqual(0);
        expect(res.body.database.connected).toBe(true);
        expect(res.body.database.response_ms).toBeGreaterThanOrEqual(0);
        expect(res.body.tables.users).toBe(5);
        expect(res.body.tables.locations).toBe(10);
    });

    test('getStatus returns degraded when DB is down', async () => {
        mockQuery.mockRejectedValueOnce(new Error('connection refused'));

        const res = mockResponse();
        await monitoringController.getStatus({}, res);

        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe('degraded');
        expect(res.body.database.connected).toBe(false);
        expect(res.body.database.error).toBe('connection refused');
        expect(res.body.tables).toBeNull();
    });
});
