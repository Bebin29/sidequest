const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { parseBody, sendJSON, sendError, MAX_UPLOAD_BODY_SIZE } = require('../helpers');

const UPLOAD_DIR = process.env.UPLOAD_DIR || '/app/uploads';
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

/**
 * Streaming Multipart-Parser fuer Datei-Uploads.
 * Liest Chunks und schreibt direkt auf Disk (kein Buffering im Speicher).
 */
function parseMultipart(req, destPath) {
    return new Promise((resolve, reject) => {
        const contentType = req.headers['content-type'] || '';
        const boundaryMatch = contentType.match(/boundary=(.+)$/);
        if (!boundaryMatch) {
            return reject(new Error('Missing multipart boundary'));
        }

        const boundary = '--' + boundaryMatch[1];
        const endBoundary = boundary + '--';

        let headersParsed = false;
        let fileStarted = false;
        let totalSize = 0;
        let buffer = Buffer.alloc(0);
        let writeStream = null;
        let fieldData = {};
        let currentFieldName = null;
        let currentFieldValue = '';
        let inFileField = false;

        const cleanup = () => {
            if (writeStream) {
                writeStream.destroy();
                writeStream = null;
            }
        };

        req.on('data', (chunk) => {
            totalSize += chunk.length;
            if (totalSize > MAX_FILE_SIZE) {
                cleanup();
                req.destroy();
                return reject(Object.assign(new Error('Payload too large'), { statusCode: 413 }));
            }

            buffer = Buffer.concat([buffer, chunk]);

            // Einfacher Line-basierter Multipart-Parser
            while (buffer.length > 0) {
                const bufStr = buffer.toString('latin1');

                if (!headersParsed) {
                    // Suche nach Ende der Part-Headers (\r\n\r\n)
                    const headerEnd = bufStr.indexOf('\r\n\r\n');
                    if (headerEnd === -1) return; // Noch nicht genug Daten

                    const headerSection = bufStr.substring(0, headerEnd);

                    // Pruefen ob Boundary
                    if (headerSection.includes(endBoundary)) {
                        buffer = Buffer.alloc(0);
                        return;
                    }

                    // Content-Disposition parsen
                    const nameMatch = headerSection.match(/name="([^"]+)"/);
                    const filenameMatch = headerSection.match(/filename="([^"]+)"/);

                    if (filenameMatch) {
                        // Datei-Feld
                        inFileField = true;
                        writeStream = fs.createWriteStream(destPath);
                        writeStream.on('error', (err) => {
                            cleanup();
                            reject(err);
                        });
                    } else if (nameMatch) {
                        // Normales Feld
                        inFileField = false;
                        currentFieldName = nameMatch[1];
                        currentFieldValue = '';
                    }

                    headersParsed = true;
                    fileStarted = true;
                    buffer = buffer.slice(headerEnd + 4);
                    continue;
                }

                // Suche nach naechster Boundary im aktuellen Buffer
                const boundaryIdx = bufStr.indexOf('\r\n' + boundary);

                if (boundaryIdx !== -1) {
                    // Daten vor der Boundary gehoeren zum aktuellen Part
                    const partData = buffer.slice(0, boundaryIdx);

                    if (inFileField && writeStream) {
                        writeStream.write(partData);
                        writeStream.end();
                        writeStream = null;
                    } else if (currentFieldName) {
                        fieldData[currentFieldName] = partData.toString('utf8');
                        currentFieldName = null;
                    }

                    // Naechsten Part vorbereiten
                    headersParsed = false;
                    inFileField = false;
                    buffer = buffer.slice(boundaryIdx + 2); // Skip \r\n, Boundary wird im Header-Parse behandelt
                    continue;
                }

                // Keine Boundary gefunden — wenn wir eine Datei schreiben, flush alles bis auf
                // die letzten Bytes (die koennte eine partielle Boundary sein)
                if (inFileField && writeStream) {
                    const keep = boundary.length + 4; // Genug fuer partielle Boundary
                    if (buffer.length > keep) {
                        writeStream.write(buffer.slice(0, buffer.length - keep));
                        buffer = buffer.slice(buffer.length - keep);
                    }
                }
                return; // Warten auf mehr Daten
            }
        });

        req.on('end', () => {
            if (writeStream) {
                writeStream.end();
            }
            resolve(fieldData);
        });

        req.on('error', (err) => {
            cleanup();
            reject(err);
        });
    });
}

async function upload(req, res) {
    try {
        const contentType = req.headers['content-type'] || '';

        if (contentType.includes('multipart/form-data')) {
            // Neuer Pfad: Streaming Multipart Upload
            const ext = 'jpg'; // Default, kann via Feld ueberschrieben werden
            const filename = `${crypto.randomUUID()}.${ext}`;
            const filepath = path.join(UPLOAD_DIR, filename);

            const fields = await parseMultipart(req, filepath);

            // Wenn eine Extension mitgegeben wurde, Datei umbenennen
            if (fields.extension && fields.extension !== ext) {
                const newFilename = `${crypto.randomUUID()}.${fields.extension}`;
                const newFilepath = path.join(UPLOAD_DIR, newFilename);
                await fs.promises.rename(filepath, newFilepath);
                const imageUrl = `${process.env.BASE_URL || 'http://217.154.243.150'}/uploads/${newFilename}`;
                return sendJSON(res, 201, { url: imageUrl });
            }

            const imageUrl = `${process.env.BASE_URL || 'http://217.154.243.150'}/uploads/${filename}`;
            sendJSON(res, 201, { url: imageUrl });
        } else {
            // Legacy-Pfad: Base64 JSON Upload (Backward-Kompatibilitaet)
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
        }
    } catch (err) {
        if (err.statusCode === 413) {
            return sendError(res, 413, 'Payload too large');
        }
        console.error('upload error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { upload };
