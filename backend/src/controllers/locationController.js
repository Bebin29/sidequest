const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');

async function getAll(req, res, query) {
    try {
        const limit = Math.min(parseInt(query.limit, 10) || 50, 100);
        const offset = parseInt(query.offset, 10) || 0;
        const category = query.category || null;

        let sql = 'SELECT * FROM locations';
        const values = [];

        if (category) {
            sql += ' WHERE category = $1';
            values.push(category);
        }

        sql += ` ORDER BY created_at DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`;
        values.push(limit, offset);

        const result = await pool.query(sql, values);
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
