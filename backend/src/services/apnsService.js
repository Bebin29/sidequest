const http2 = require('node:http2');
const fs = require('node:fs');
const jwt = require('jsonwebtoken');
const pool = require('../db/pool');

// APNs Konfiguration aus ENV
const KEY_PATH = process.env.APNS_KEY_PATH;
const KEY_ID = process.env.APNS_KEY_ID;
const TEAM_ID = process.env.APNS_TEAM_ID;
const BUNDLE_ID = process.env.APNS_BUNDLE_ID;
const IS_PRODUCTION = process.env.APNS_ENVIRONMENT === 'production';

const APNS_HOST = IS_PRODUCTION
    ? 'https://api.push.apple.com'
    : 'https://api.sandbox.push.apple.com';

// JWT Cache (APNs erlaubt max 60 Min, wir refreshen nach 50)
let cachedToken = null;
let tokenGeneratedAt = 0;
const TOKEN_TTL_MS = 50 * 60 * 1000;

// Persistent HTTP/2 Session
let client = null;

function isConfigured() {
    return KEY_PATH && KEY_ID && TEAM_ID && BUNDLE_ID;
}

function getSigningKey() {
    return fs.readFileSync(KEY_PATH, 'utf8');
}

function getToken() {
    const now = Date.now();
    if (cachedToken && (now - tokenGeneratedAt) < TOKEN_TTL_MS) {
        return cachedToken;
    }

    const key = getSigningKey();
    cachedToken = jwt.sign({}, key, {
        algorithm: 'ES256',
        keyid: KEY_ID,
        issuer: TEAM_ID,
        expiresIn: '1h',
    });
    tokenGeneratedAt = now;
    return cachedToken;
}

function getClient() {
    if (client && !client.closed && !client.destroyed) {
        return client;
    }

    client = http2.connect(APNS_HOST);

    client.on('error', (err) => {
        console.error('APNs HTTP/2 connection error:', err.message);
        client = null;
    });

    client.on('goaway', () => {
        console.warn('APNs sent GOAWAY, reconnecting on next push');
        if (client) {
            client.close();
            client = null;
        }
    });

    return client;
}

/**
 * Push-Notification an ein Geraet senden
 * @param {string} deviceToken - Hex-String des APNs Device Tokens
 * @param {object} options
 * @param {string} options.title - Notification Titel
 * @param {string} options.body - Notification Text
 * @param {string} options.type - Notification Typ (fuer thread-id Gruppierung)
 * @param {object} [options.data] - Custom Payload fuer Deep-Linking
 * @returns {Promise<{success: boolean, status?: number, reason?: string}>}
 */
function sendPush(deviceToken, { title, body, data, type }) {
    if (!isConfigured()) {
        console.warn('APNs not configured, skipping push');
        return Promise.resolve({ success: false, reason: 'not_configured' });
    }

    return new Promise((resolve) => {
        const session = getClient();
        const token = getToken();

        const payload = JSON.stringify({
            aps: {
                alert: { title, body },
                sound: 'default',
                'thread-id': type || 'general',
            },
            data: data || {},
        });

        const headers = {
            ':method': 'POST',
            ':path': `/3/device/${deviceToken}`,
            'authorization': `bearer ${token}`,
            'apns-topic': BUNDLE_ID,
            'apns-push-type': 'alert',
            'apns-priority': '10',
            'content-type': 'application/json',
        };

        const req = session.request(headers);

        let responseData = '';
        let statusCode = 0;

        req.on('response', (headers) => {
            statusCode = headers[':status'];
        });

        req.on('data', (chunk) => {
            responseData += chunk;
        });

        req.on('end', () => {
            if (statusCode === 200) {
                resolve({ success: true, status: 200 });
            } else {
                let reason = 'unknown';
                try {
                    const parsed = JSON.parse(responseData);
                    reason = parsed.reason || 'unknown';
                } catch (_) {}

                console.error(`APNs push failed: status=${statusCode} reason=${reason} token=${deviceToken.substring(0, 8)}...`);

                // 410 = Unregistered: Token ist ungueltig, aus DB entfernen
                if (statusCode === 410) {
                    pool.query('UPDATE users SET fcm_token = NULL WHERE fcm_token = $1', [deviceToken])
                        .catch((err) => console.error('Failed to clear invalid token:', err.message));
                }

                resolve({ success: false, status: statusCode, reason });
            }
        });

        req.on('error', (err) => {
            console.error('APNs request error:', err.message);
            resolve({ success: false, reason: err.message });
        });

        req.end(payload);
    });
}

module.exports = { sendPush, isConfigured };
