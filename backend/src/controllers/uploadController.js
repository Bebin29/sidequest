const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { parseBody, sendJSON, sendError, MAX_UPLOAD_BODY_SIZE } = require('../helpers');

const UPLOAD_DIR = process.env.UPLOAD_DIR || '/app/uploads';

async function upload(req, res) {
    try {
        const body = await parseBody(req, { maxSize: MAX_UPLOAD_BODY_SIZE });
        if (!body) return sendError(res, 400, 'Request body required');

        const { image, extension } = body;

        if (!image) {
            return sendError(res, 400, 'image (base64) is required');
        }

        const ext = extension || 'jpg';
        const filename = `${crypto.randomUUID()}.${ext}`;
        const filepath = path.join(UPLOAD_DIR, filename);

        const buffer = Buffer.from(image, 'base64');
        await fs.promises.writeFile(filepath, buffer);

        const imageUrl = `${process.env.BASE_URL || 'http://217.154.243.150'}/uploads/${filename}`;

        sendJSON(res, 201, { url: imageUrl });
    } catch (err) {
        if (err.statusCode === 413) {
            return sendError(res, 413, 'Payload too large');
        }
        console.error('upload error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { upload };
