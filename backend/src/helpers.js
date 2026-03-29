const zlib = require('zlib');

const MAX_BODY_SIZE = 1 * 1024 * 1024; // 1 MB default
const MAX_UPLOAD_BODY_SIZE = 10 * 1024 * 1024; // 10 MB for uploads

function parseBody(req, { maxSize = MAX_BODY_SIZE } = {}) {
    return new Promise((resolve, reject) => {
        let body = '';
        let size = 0;
        req.on('data', (chunk) => {
            size += chunk.length;
            if (size > maxSize) {
                req.destroy();
                return reject(Object.assign(new Error('Payload too large'), { statusCode: 413 }));
            }
            body += chunk;
        });
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
    const json = JSON.stringify(data);

    // Gzip wenn Client es unterstützt (Flag wird in server.js gesetzt)
    if (res._acceptsGzip && json.length > 1024) {
        zlib.gzip(json, (err, compressed) => {
            if (err) {
                // Fallback: unkomprimiert senden
                res.writeHead(statusCode, { 'Content-Type': 'application/json' });
                res.end(json);
                return;
            }
            res.writeHead(statusCode, {
                'Content-Type': 'application/json',
                'Content-Encoding': 'gzip',
                'Content-Length': compressed.length,
            });
            res.end(compressed);
        });
    } else {
        res.writeHead(statusCode, { 'Content-Type': 'application/json' });
        res.end(json);
    }
}

function sendError(res, statusCode, message) {
    sendJSON(res, statusCode, { error: message });
}

function getIdFromPath(pathname, prefix) {
    // e.g. /api/users/123 -> 123
    const parts = pathname.replace(prefix, '').split('/').filter(Boolean);
    return parts[0] || null;
}

module.exports = { parseBody, sendJSON, sendError, getIdFromPath, MAX_UPLOAD_BODY_SIZE };
