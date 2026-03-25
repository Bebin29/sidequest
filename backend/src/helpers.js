function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', (chunk) => { body += chunk; });
        req.on('end', () => {
            if (!body) return resolve(null);
            try {
                resolve(JSON.parse(body));
            } catch {
                reject(new Error('Invalid JSON'));
            }
        });
        req.on('error', reject);
    });
}

function sendJSON(res, statusCode, data) {
    res.writeHead(statusCode, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
}

function sendError(res, statusCode, message) {
    sendJSON(res, statusCode, { error: message });
}

function getIdFromPath(pathname, prefix) {
    // e.g. /api/users/123 -> 123
    const parts = pathname.replace(prefix, '').split('/').filter(Boolean);
    return parts[0] || null;
}

module.exports = { parseBody, sendJSON, sendError, getIdFromPath };
