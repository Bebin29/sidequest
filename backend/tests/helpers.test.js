const { parseBody, sendJSON, sendError, getIdFromPath } = require('../src/helpers');
const { Readable } = require('stream');

// Helper: create a mock request from a string body
function mockRequest(body) {
    const readable = new Readable();
    readable.push(body);
    readable.push(null);
    return readable;
}

// Helper: create a mock response that captures output
function mockResponse() {
    const res = {
        statusCode: null,
        headers: {},
        body: '',
        writeHead(code, headers) {
            res.statusCode = code;
            Object.assign(res.headers, headers);
        },
        end(data) {
            res.body = data || '';
        },
        setHeader() {},
    };
    return res;
}

describe('helpers', () => {
    describe('parseBody', () => {
        test('parses valid JSON body', async () => {
            const req = mockRequest('{"name":"test"}');
            const result = await parseBody(req);
            expect(result).toEqual({ name: 'test' });
        });

        test('returns null for empty body', async () => {
            const req = mockRequest('');
            const result = await parseBody(req);
            expect(result).toBeNull();
        });

        test('rejects invalid JSON', async () => {
            const req = mockRequest('not json');
            await expect(parseBody(req)).rejects.toThrow('Invalid JSON');
        });
    });

    describe('sendJSON', () => {
        test('sends correct status and JSON body', () => {
            const res = mockResponse();
            sendJSON(res, 200, { status: 'ok' });
            expect(res.statusCode).toBe(200);
            expect(res.headers['Content-Type']).toBe('application/json');
            expect(JSON.parse(res.body)).toEqual({ status: 'ok' });
        });

        test('sends 201 for created resources', () => {
            const res = mockResponse();
            sendJSON(res, 201, { data: { id: '123' } });
            expect(res.statusCode).toBe(201);
            expect(JSON.parse(res.body).data.id).toBe('123');
        });
    });

    describe('sendError', () => {
        test('sends error with correct format', () => {
            const res = mockResponse();
            sendError(res, 400, 'Bad request');
            expect(res.statusCode).toBe(400);
            expect(JSON.parse(res.body)).toEqual({ error: 'Bad request' });
        });

        test('sends 500 for server errors', () => {
            const res = mockResponse();
            sendError(res, 500, 'Internal server error');
            expect(res.statusCode).toBe(500);
        });
    });

    describe('getIdFromPath', () => {
        test('extracts ID from path', () => {
            const result = getIdFromPath('/api/users/abc-123', '/api/users/');
            expect(result).toBe('abc-123');
        });

        test('returns null for empty path', () => {
            const result = getIdFromPath('/api/users/', '/api/users/');
            expect(result).toBeNull();
        });
    });
});
