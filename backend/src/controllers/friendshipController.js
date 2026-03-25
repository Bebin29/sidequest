const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');

// Freundschaftsanfrage senden
async function sendRequest(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { requester_id, receiver_username } = body;

        if (!requester_id || !receiver_username) {
            return sendError(res, 400, 'requester_id and receiver_username are required');
        }

        // Receiver finden
        const receiver = await pool.query('SELECT id, username FROM users WHERE username = $1', [receiver_username]);
        if (receiver.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }

        const receiver_id = receiver.rows[0].id;

        if (requester_id === receiver_id) {
            return sendError(res, 400, 'Cannot send friend request to yourself');
        }

        // Requester Username holen
        const requester = await pool.query('SELECT username FROM users WHERE id = $1', [requester_id]);
        if (requester.rowCount === 0) {
            return sendError(res, 404, 'Requester not found');
        }

        const result = await pool.query(
            `INSERT INTO friendships (requester_id, receiver_id, requester_username, receiver_username)
             VALUES ($1, $2, $3, $4)
             RETURNING *`,
            [requester_id, receiver_id, requester.rows[0].username, receiver.rows[0].username]
        );

        sendJSON(res, 201, { data: result.rows[0] });
    } catch (err) {
        if (err.code === '23505') {
            return sendError(res, 409, 'Friend request already exists');
        }
        console.error('sendRequest error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Freundesliste (akzeptierte Freundschaften)
async function getFriends(req, res, userId) {
    try {
        const result = await pool.query(
            `SELECT * FROM friendships
             WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'
             ORDER BY accepted_at DESC`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getFriends error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Eingehende Anfragen
async function getPendingRequests(req, res, userId) {
    try {
        const result = await pool.query(
            `SELECT * FROM friendships
             WHERE receiver_id = $1 AND status = 'pending'
             ORDER BY created_at DESC`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getPendingRequests error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Anfrage akzeptieren/ablehnen
async function updateStatus(req, res, id) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { status } = body;

        if (!['accepted', 'declined'].includes(status)) {
            return sendError(res, 400, 'Status must be accepted or declined');
        }

        const acceptedAt = status === 'accepted' ? 'CURRENT_TIMESTAMP' : 'NULL';

        const result = await pool.query(
            `UPDATE friendships SET status = $1, accepted_at = ${acceptedAt} WHERE id = $2 RETURNING *`,
            [status, id]
        );

        if (result.rowCount === 0) {
            return sendError(res, 404, 'Friendship not found');
        }
        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('updateStatus error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Freund entfernen
async function remove(req, res, id) {
    try {
        const result = await pool.query('DELETE FROM friendships WHERE id = $1 RETURNING id', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'Friendship not found');
        }
        sendJSON(res, 200, { message: 'Friendship removed' });
    } catch (err) {
        console.error('remove friendship error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// User suchen (nach Username)
async function searchUsers(req, res, query) {
    try {
        const search = query.q;
        if (!search || search.length < 2) {
            return sendError(res, 400, 'Search query must be at least 2 characters');
        }

        const result = await pool.query(
            `SELECT * FROM users WHERE username ILIKE $1 LIMIT 20`,
            [`%${search}%`]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('searchUsers error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { sendRequest, getFriends, getPendingRequests, updateStatus, remove, searchUsers };
