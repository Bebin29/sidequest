const zlib = require('zlib');
const crypto = require('crypto');

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

    // ETag: Hash der Response fuer Conditional Requests (nur bei 200 GET)
    if (statusCode === 200 && res._req) {
        const etag = '"' + crypto.createHash('md5').update(json).digest('hex').slice(0, 16) + '"';
        const ifNoneMatch = res._req.headers['if-none-match'];

        if (ifNoneMatch === etag) {
            res.writeHead(304);
            res.end();
            return;
        }

        // ETag-Header setzen (wird unten in writeHead uebernommen)
        res._etag = etag;
    }

    // Gzip wenn Client es unterstuetzt (Flag wird in server.js gesetzt)
    if (res._acceptsGzip && json.length > 1024) {
        zlib.gzip(json, (err, compressed) => {
            if (err) {
                // Fallback: unkomprimiert senden
                const headers = { 'Content-Type': 'application/json' };
                if (res._etag) headers['ETag'] = res._etag;
                res.writeHead(statusCode, headers);
                res.end(json);
                return;
            }
            const headers = {
                'Content-Type': 'application/json',
                'Content-Encoding': 'gzip',
                'Content-Length': compressed.length,
            };
            if (res._etag) headers['ETag'] = res._etag;
            res.writeHead(statusCode, headers);
            res.end(compressed);
        });
    } else {
        const headers = { 'Content-Type': 'application/json' };
        if (res._etag) headers['ETag'] = res._etag;
        res.writeHead(statusCode, headers);
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
