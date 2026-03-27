const crypto = require('crypto');
const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');
const { generateRingCode } = require('../ringCode');

async function signInWithApple(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { appleUserId, email, displayName } = body;

        if (!appleUserId) {
            return sendError(res, 400, 'appleUserId is required');
        }

        // Prüfen ob User schon existiert
        const existing = await pool.query(
            'SELECT * FROM users WHERE apple_user_id = $1',
            [appleUserId]
        );

        if (existing.rowCount > 0) {
            // Login: User existiert
            await pool.query(
                'UPDATE users SET last_seen_at = CURRENT_TIMESTAMP WHERE id = $1',
                [existing.rows[0].id]
            );
            return sendJSON(res, 200, { data: existing.rows[0], isNewUser: false });
        }

        // Registrierung: Neuen User anlegen
        // Apple liefert Email und Name nur beim ersten Login
        const username = (email ? email.split('@')[0] : `user_${Date.now()}`).toLowerCase();

        // Generate unique ring code for profile sharing
        const tempId = crypto.randomUUID();
        const ringCode = generateRingCode(tempId);

        const result = await pool.query(
            `INSERT INTO users (apple_user_id, email, username, display_name, ring_code)
             VALUES ($1, $2, $3, $4, $5)
             RETURNING *`,
            [
                appleUserId,
                email || `${appleUserId}@privaterelay.appleid.com`,
                username,
                displayName || username,
                ringCode
            ]
        );

        sendJSON(res, 201, { data: result.rows[0], isNewUser: true });
    } catch (err) {
        if (err.code === '23505') {
            return sendError(res, 409, 'User already exists');
        }
        console.error('signInWithApple error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { signInWithApple };
