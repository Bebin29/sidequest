const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');

async function getAll(req, res, query) {
    try {
        const userId = query.user_id;

        if (!userId) {
            return sendError(res, 400, 'user_id is required');
        }

        // Eigene + Freunde IDs sammeln
        const friendsResult = await pool.query(
            `SELECT CASE
                WHEN requester_id = $1 THEN receiver_id
                ELSE requester_id
             END AS friend_id
             FROM friendships
             WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'`,
            [userId]
        );

        const allowedIds = [userId, ...friendsResult.rows.map(r => r.friend_id)];
        const placeholders = allowedIds.map((_, i) => `$${i + 1}`).join(', ');

        const result = await pool.query(
            `SELECT * FROM locations WHERE created_by IN (${placeholders}) ORDER BY created_at DESC`,
            allowedIds
        );

        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getAll locations error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function getById(req, res, id) {
    try {
        const result = await pool.query('SELECT * FROM locations WHERE id = $1', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'Location not found');
        }
        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('getById location error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function create(req, res) {
    try {
        const body = await parseBody(req);
        if (!body) return sendError(res, 400, 'Request body required');

        const { name, address, latitude, longitude, category, created_by,
                price_range, phone_number, website, instagram_handle, tags } = body;

        if (!name || !address || latitude == null || longitude == null || !category || !created_by) {
            return sendError(res, 400, 'name, address, latitude, longitude, category and created_by are required');
        }

        const geohash = `${Math.round(latitude * 1000)}${Math.round(longitude * 1000)}`;
        const coordinates = `(${longitude},${latitude})`;

        const result = await pool.query(
            `INSERT INTO locations (name, address, latitude, longitude, coordinates, geohash, category, created_by,
                price_range, phone_number, website, instagram_handle, tags)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
             RETURNING *`,
            [name, address, latitude, longitude, coordinates, geohash, category, created_by,
             price_range || null, phone_number || null, website || null, instagram_handle || null, tags || []]
        );

        sendJSON(res, 201, { data: result.rows[0] });
    } catch (err) {
        console.error('create location error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function remove(req, res, id) {
    try {
        const result = await pool.query('DELETE FROM locations WHERE id = $1 RETURNING id', [id]);
        if (result.rowCount === 0) {
            return sendError(res, 404, 'Location not found');
        }
        sendJSON(res, 200, { message: 'Location deleted' });
    } catch (err) {
        console.error('delete location error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { getAll, getById, create, remove };
