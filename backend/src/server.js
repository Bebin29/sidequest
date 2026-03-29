require('dotenv').config();

const http = require('http');
const fs = require('fs');
const path = require('path');
const route = require('./router');

const PORT = process.env.PORT || 3000;
const UPLOAD_DIR = process.env.UPLOAD_DIR || '/app/uploads';

const server = http.createServer((req, res) => {
    // Gzip-Flag fuer sendJSON (pruefen ob Client gzip akzeptiert)
    res._acceptsGzip = (req.headers['accept-encoding'] || '').includes('gzip');

    // Statische Dateien aus /uploads served
    if (req.method === 'GET' && req.url.startsWith('/uploads/')) {
        const filename = path.basename(req.url);
        const filepath = path.join(UPLOAD_DIR, filename);

        if (fs.existsSync(filepath)) {
            const ext = path.extname(filename).toLowerCase();
            const mimeTypes = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };
            res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
            fs.createReadStream(filepath).pipe(res);
            return;
        }

        res.writeHead(404);
        res.end('Not found');
        return;
    }

    route(req, res);
});

server.listen(PORT, () => {
    console.log(`Sidequest API running on port ${PORT}`);
});
