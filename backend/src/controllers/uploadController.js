const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require('sharp');
const { parseBody, sendJSON, sendError } = require('../helpers');

const UPLOAD_DIR = process.env.UPLOAD_DIR || '/app/uploads';
const MAX_WIDTH = 1200;
const JPEG_QUALITY = 70;

async function upload(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { image, extension } = body;

        if (!image) {
            return sendError(res, 400, 'image (base64) is required');
        }

        const filename = `${crypto.randomUUID()}.jpg`;
        const filepath = path.join(UPLOAD_DIR, filename);

        const buffer = Buffer.from(image, 'base64');

        // Resize to max 1200px wide and compress as JPEG
        const compressed = await sharp(buffer)
            .resize(MAX_WIDTH, null, { withoutEnlargement: true })
            .jpeg({ quality: JPEG_QUALITY })
            .toBuffer();

        fs.writeFileSync(filepath, compressed);

        const imageUrl = `${process.env.BASE_URL || 'http://217.154.243.150'}/uploads/${filename}`;

        sendJSON(res, 201, { url: imageUrl });
    } catch (err) {
        console.error('upload error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { upload };
