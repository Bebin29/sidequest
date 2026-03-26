const url = require('url');
const { sendJSON, sendError } = require('./helpers');
const userController = require('./controllers/userController');
const authController = require('./controllers/authController');
const friendshipController = require('./controllers/friendshipController');
const locationController = require('./controllers/locationController');
const commentController = require('./controllers/commentController');
const uploadController = require('./controllers/uploadController');

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

    // Auth routes
    if (pathname === '/api/auth/apple' && method === 'POST') {
        return authController.signInWithApple(req, res);
    }

    // User search (muss vor /api/users/:id stehen)
    if (pathname === '/api/users/search' && method === 'GET') {
        return friendshipController.searchUsers(req, res, parsed.query);
    }

    // Username availability check
    if (pathname === '/api/users/check-username' && method === 'GET') {
        return userController.checkUsername(req, res, parsed.query);
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

    // Locations routes
    if (pathname === '/api/locations' && method === 'GET') {
        return locationController.getAll(req, res, parsed.query);
    }
    if (pathname === '/api/locations' && method === 'POST') {
        return locationController.create(req, res);
    }

    const locationIdMatch = pathname.match(/^\/api\/locations\/([^/]+)$/);
    if (locationIdMatch) {
        const id = locationIdMatch[1];
        if (method === 'GET') return locationController.getById(req, res, id);
        if (method === 'PUT') return locationController.update(req, res, id);
        if (method === 'DELETE') return locationController.remove(req, res, id);
    }

    // Comments routes: GET /api/locations/:id/comments
    const commentsMatch = pathname.match(/^\/api\/locations\/([^/]+)\/comments$/);
    if (commentsMatch) {
        if (method === 'GET') return commentController.getByLocation(req, res, commentsMatch[1]);
    }

    if (pathname === '/api/comments' && method === 'POST') {
        return commentController.create(req, res);
    }

    const commentIdMatch = pathname.match(/^\/api\/comments\/([^/]+)$/);
    if (commentIdMatch && method === 'DELETE') {
        return commentController.remove(req, res, commentIdMatch[1]);
    }

    // Friendships routes
    if (pathname === '/api/friendships' && method === 'POST') {
        return friendshipController.sendRequest(req, res);
    }

    // Friends list: GET /api/friends/:userId
    const friendsMatch = pathname.match(/^\/api\/friends\/([^/]+)$/);
    if (friendsMatch && method === 'GET') {
        return friendshipController.getFriends(req, res, friendsMatch[1]);
    }

    // Pending requests: GET /api/friendships/pending/:userId
    const pendingMatch = pathname.match(/^\/api\/friendships\/pending\/([^/]+)$/);
    if (pendingMatch && method === 'GET') {
        return friendshipController.getPendingRequests(req, res, pendingMatch[1]);
    }

    // Update friendship: PATCH /api/friendships/:id
    const friendshipIdMatch = pathname.match(/^\/api\/friendships\/([^/]+)$/);
    if (friendshipIdMatch) {
        const id = friendshipIdMatch[1];
        if (method === 'PATCH') return friendshipController.updateStatus(req, res, id);
        if (method === 'DELETE') return friendshipController.remove(req, res, id);
    }

    // Upload
    if (pathname === '/api/uploads' && method === 'POST') {
        return uploadController.upload(req, res);
    }

    // 404
    sendError(res, 404, 'Route not found');
}

module.exports = route;
