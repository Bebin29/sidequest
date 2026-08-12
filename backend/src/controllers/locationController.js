const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');
const notificationService = require('../services/notificationService');

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

        let paramIdx = allowedIds.length + 1;
        const filters = [];
        const params = [...allowedIds];

        if (query.category) {
            filters.push(`category = $${paramIdx}`);
            params.push(query.category);
            paramIdx++;
        }

        if (query.search) {
            filters.push(`(name ILIKE $${paramIdx} OR address ILIKE $${paramIdx})`);
            params.push(`%${query.search}%`);
            paramIdx++;
        }

        if (query.lat && query.lon && query.radius) {
            const radiusMeters = parseFloat(query.radius);
            // Haversine-based distance filter using lat/lon columns
            filters.push(
                `(6371000 * acos(cos(radians($${paramIdx})) * cos(radians(latitude)) * cos(radians(longitude) - radians($${paramIdx + 1})) + sin(radians($${paramIdx})) * sin(radians(latitude)))) <= $${paramIdx + 2}`
            );
            params.push(parseFloat(query.lat), parseFloat(query.lon), radiusMeters);
            paramIdx += 3;
        }

        const whereClause = `created_by IN (${placeholders})` +
            (filters.length > 0 ? ' AND ' + filters.join(' AND ') : '');

        const result = await pool.query(
            `SELECT locations.*,
                    users.username AS creator_username,
                    users.display_name AS creator_display_name,
                    users.profile_image_url AS creator_profile_image_url
             FROM locations
             LEFT JOIN users ON locations.created_by = users.id
             WHERE ${whereClause}
             ORDER BY locations.created_at DESC`,
            params
        );

        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getAll locations error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function getById(req, res, id) {
    try {
        const result = await pool.query(
            `SELECT locations.*,
                    users.username AS creator_username,
                    users.display_name AS creator_display_name,
                    users.profile_image_url AS creator_profile_image_url
             FROM locations
             LEFT JOIN users ON locations.created_by = users.id
             WHERE locations.id = $1`,
            [id]
        );
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
                description, image_urls, price_range, phone_number, website, instagram_handle, tags } = body;

        if (!name || !address || latitude == null || longitude == null || !category || !created_by) {
            return sendError(res, 400, 'name, address, latitude, longitude, category and created_by are required');
        }

        const geohash = `${Math.round(latitude * 1000)}${Math.round(longitude * 1000)}`;
        const coordinates = `(${longitude},${latitude})`;

        const result = await pool.query(
            `INSERT INTO locations (name, address, latitude, longitude, coordinates, geohash, category, created_by,
                description, image_urls, price_range, phone_number, website, instagram_handle, tags)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
             RETURNING *`,
            [name, address, latitude, longitude, coordinates, geohash, category, created_by,
             description || null, image_urls || [], price_range || null, phone_number || null, website || null, instagram_handle || null, tags || []]
        );

        sendJSON(res, 201, { data: result.rows[0] });

        // Freunde ueber neuen Spot benachrichtigen (fire-and-forget)
        notificationService.notifyFriendNewSpot(created_by, name)
            .catch(err => console.error('notify friend_new_spot error:', err.message));
    } catch (err) {
        console.error('create location error:', err);
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

        const allowed = ['name', 'description', 'category', 'image_urls',
                         'price_range', 'phone_number', 'website', 'instagram_handle', 'tags'];

        for (const key of allowed) {
            if (body[key] !== undefined) {
                fields.push(`${key} = $${idx}`);
                values.push(body[key]);
                idx++;
            }
        }

        if (fields.length === 0) {
            return sendError(res, 400, 'No valid fields to update');
        }

        fields.push('updated_at = CURRENT_TIMESTAMP');
        values.push(id);

        const result = await pool.query(
            `UPDATE locations SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
            values
        );

        if (result.rowCount === 0) {
            return sendError(res, 404, 'Location not found');
        }
        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('update location error:', err);
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

async function getFeed(req, res, query) {
    try {
        const userId = query.user_id;
        if (!userId) {
            return sendError(res, 400, 'user_id is required');
        }

        const limit = parseInt(query.limit) || 20;
        const offset = parseInt(query.offset) || 0;

        // Freunde IDs sammeln (ohne eigene)
        const friendsResult = await pool.query(
            `SELECT CASE
                WHEN requester_id = $1 THEN receiver_id
                ELSE requester_id
             END AS friend_id
             FROM friendships
             WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'`,
            [userId]
        );

        const friendIds = friendsResult.rows.map(r => r.friend_id);

        if (friendIds.length === 0) {
            return sendJSON(res, 200, { data: [], count: 0, hasMore: false });
        }

        const placeholders = friendIds.map((_, i) => `$${i + 1}`).join(', ');

        const result = await pool.query(
            `SELECT locations.*,
                    users.username AS creator_username,
                    users.display_name AS creator_display_name,
                    users.profile_image_url AS creator_profile_image_url
             FROM locations
             LEFT JOIN users ON locations.created_by = users.id
             WHERE locations.created_by IN (${placeholders})
             ORDER BY locations.created_at DESC
             LIMIT $${friendIds.length + 1} OFFSET $${friendIds.length + 2}`,
            [...friendIds, limit, offset]
        );

        const hasMore = result.rowCount === limit;
        sendJSON(res, 200, { data: result.rows, count: result.rowCount, hasMore });
    } catch (err) {
        console.error('getFeed error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

async function getCategories(req, res) {
    try {
        const result = await pool.query(
            'SELECT DISTINCT category FROM locations ORDER BY category'
        );
        sendJSON(res, 200, { data: result.rows.map(r => r.category) });
    } catch (err) {
        console.error('getCategories error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { getAll, getById, create, update, remove, getFeed, getCategories };
