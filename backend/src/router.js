const url = require('url');
const { sendJSON, sendError } = require('./helpers');
const userController = require('./controllers/userController');

function route(req, res) {
    const parsed = url.parse(req.url, true);
    const pathname = parsed.pathname;
    const method = req.method;

    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (method === 'OPTIONS') {
        res.writeHead(204);
        return res.end();
    }

    // Health Check
    if (pathname === '/api/health' && method === 'GET') {
        return sendJSON(res, 200, { status: 'ok', timestamp: new Date().toISOString() });
    }

    // Users routes
    if (pathname === '/api/users' && method === 'GET') {
        return userController.getAll(req, res, parsed.query);
    }
    if (pathname === '/api/users' && method === 'POST') {
        return userController.create(req, res);
    }

    // Users routes with ID: /api/users/:id
    const userIdMatch = pathname.match(/^\/api\/users\/([^/]+)$/);
    if (userIdMatch) {
        const id = userIdMatch[1];
        if (method === 'GET') return userController.getById(req, res, id);
        if (method === 'PUT') return userController.update(req, res, id);
        if (method === 'DELETE') return userController.remove(req, res, id);
    }

    // 404
    sendError(res, 404, 'Route not found');
}

module.exports = route;
