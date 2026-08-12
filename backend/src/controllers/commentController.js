const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');
const notificationService = require('../services/notificationService');

async function getByLocation(req, res, locationId) {
    try {
        const result = await pool.query(
            'SELECT * FROM comments WHERE location_id = $1 ORDER BY created_at ASC',
            [locationId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getByLocation comments error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function create(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { location_id, user_id, text } = body;

        if (!location_id || !user_id || !text) {
            return sendError(res, 400, 'location_id, user_id and text are required');
        }

        // Username holen
        const user = await pool.query('SELECT username FROM users WHERE id = $1', [user_id]);
        if (user.rowCount === 0) {
            return sendError(res, 404, 'User not found');
        }

        const result = await pool.query(
            `INSERT INTO comments (location_id, user_id, username, text)
             VALUES ($1, $2, $3, $4)
             RETURNING *`,
            [location_id, user_id, user.rows[0].username, text]
        );

        sendJSON(res, 201, { data: result.rows[0] });

        // Push-Benachrichtigung an Location-Owner (fire-and-forget)
        notificationService.notifyNewComment(user_id, location_id)
            .catch(err => console.error('notify new_comment error:', err.message));
    } catch (err) {
        console.error('create comment error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function remove(req, res, id) {
    try {
        const result = await pool.query('DELETE FROM comments WHERE id = $1 RETURNING id', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'Comment not found');
        }
        sendJSON(res, 200, { message: 'Comment deleted' });
    } catch (err) {
        console.error('delete comment error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { getByLocation, create, remove };
