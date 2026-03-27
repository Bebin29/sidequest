const crypto = require('crypto');
const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');
const { generateRingCode } = require('../ringCode');

async function getAll(req, res, query) {
    try {
        const limit = Math.min(parseInt(query.limit, 10) || 50, 100);
        const offset = parseInt(query.offset, 10) || 0;

        const result = await pool.query(
            'SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
            [limit, offset]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getAll users error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function getById(req, res, id) {
    try {
        const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }
        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('getById user error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function create(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { email, username, display_name, bio, profile_image_url } = body;

        if (!email || !username || !display_name) {
            return sendError(res, 400, 'email, username and display_name are required');
        }

        const ringCode = generateRingCode(crypto.randomUUID());

        const result = await pool.query(
            `INSERT INTO users (email, username, display_name, bio, profile_image_url, ring_code)
             VALUES ($1, $2, $3, $4, $5, $6)
             RETURNING *`,
            [email, username, display_name, bio || null, profile_image_url || null, ringCode]
        );

        sendJSON(res, 201, { data: result.rows[0] });
    } catch (err) {
        if (err.code === '23505') {
            return sendError(res, 409, 'Email or username already exists');
        }
        console.error('create user error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function update(req, res, id) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const fields = [];
        const values = [];
        let idx = 1;

        const allowed = ['email', 'username', 'display_name', 'bio', 'profile_image_url',
                         'preferences', 'favorite_categories', 'is_private', 'fcm_token'];

        for (const key of allowed) {
            if (body[key] !== undefined) {
                fields.push(`${key} = $${idx}`);
                values.push(key === 'preferences' ? JSON.stringify(body[key]) : body[key]);
                idx++;
            }
        }

        if (fields.length === 0) {
            return sendError(res, 400, 'No valid fields to update');
        }

        fields.push(`updated_at = CURRENT_TIMESTAMP`);
        values.push(id);

        const result = await pool.query(
            `UPDATE users SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
            values
        );

        if (result.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }

        // When username changes, update all denormalized copies
        if (body.username) {
            const newUsername = body.username;
            await Promise.all([
                pool.query('UPDATE ratings SET username = $1 WHERE user_id = $2', [newUsername, id]),
                pool.query('UPDATE comments SET username = $1 WHERE user_id = $2', [newUsername, id]),
                pool.query('UPDATE friendships SET requester_username = $1 WHERE requester_id = $2', [newUsername, id]),
                pool.query('UPDATE friendships SET receiver_username = $1 WHERE receiver_id = $2', [newUsername, id]),
                pool.query('UPDATE trips SET username = $1 WHERE user_id = $2', [newUsername, id]),
            ]);
        }

        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        if (err.code === '23505') {
            return sendError(res, 409, 'Email or username already exists');
        }
        console.error('update user error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function remove(req, res, id) {
    try {
        const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }
        sendJSON(res, 200, { message: 'User deleted' });
    } catch (err) {
        console.error('delete user error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function checkUsername(req, res, query) {
    try {
        const username = query.username;
        if (!username || username.length < 3) {
            return sendError(res, 400, 'Username must be at least 3 characters');
        }

        const result = await pool.query(
            'SELECT id FROM users WHERE username = $1',
            [username.toLowerCase()]
        );

        sendJSON(res, 200, { available: result.rowCount === 0 });
    } catch (err) {
        console.error('checkUsername error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function findByRingCode(req, res, query) {
    try {
        const code = query.code;
        if (!code || code.length < 10) {
            return sendError(res, 400, 'Valid ring code is required');
        }

        // Exact match first
        let result = await pool.query(
            'SELECT * FROM users WHERE ring_code = $1',
            [code]
        );

        // Fuzzy match: allow up to 6 bit differences (Hamming distance)
        if (result.rowCount === 0 && code.length >= 72) {
            const allUsers = await pool.query('SELECT * FROM users WHERE ring_code IS NOT NULL');
            let bestMatch = null;
            let bestDistance = 7; // max allowed + 1

            for (const user of allUsers.rows) {
                if (!user.ring_code || user.ring_code.length !== code.length) continue;
                let distance = 0;
                for (let idx = 0; idx < code.length; idx++) {
                    if (code[idx] !== user.ring_code[idx]) distance++;
                    if (distance >= bestDistance) break;
                }
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestMatch = user;
                }
            }

            if (bestMatch) {
                result = { rows: [bestMatch], rowCount: 1 };
            }
        }

        if (result.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }

        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('findByRingCode error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { getAll, getById, create, update, remove, checkUsername, findByRingCode };
