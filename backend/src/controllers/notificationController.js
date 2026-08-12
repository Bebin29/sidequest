const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');

// Notifications eines Users abrufen (paginiert)
async function getByUser(req, res, userId, query) {
    try {
        const limit = Math.min(parseInt(query.limit) || 20, 50);
        const offset = parseInt(query.offset) || 0;

        const result = await pool.query(
            `SELECT n.*, u.display_name AS sender_name, u.username AS sender_username
             FROM notifications n
             LEFT JOIN users u ON n.sender_id = u.id
             WHERE n.recipient_id = $1
             ORDER BY n.created_at DESC
             LIMIT $2 OFFSET $3`,
            [userId, limit, offset]
        );

        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getByUser notifications error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Anzahl ungelesener Notifications
async function getUnreadCount(req, res, userId) {
    try {
        const result = await pool.query(
            'SELECT COUNT(*) AS count FROM notifications WHERE recipient_id = $1 AND is_read = FALSE',
            [userId]
        );

        sendJSON(res, 200, { data: { count: parseInt(result.rows[0].count) } });
    } catch (err) {
        console.error('getUnreadCount error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Einzelne Notification als gelesen markieren
async function markRead(req, res, id) {
    try {
        const result = await pool.query(
            'UPDATE notifications SET is_read = TRUE WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rowCount === 0) {
            return sendError(res, 404, 'Notification not found');
        }

        sendJSON(res, 200, { data: result.rows[0] });
    } catch (err) {
        console.error('markRead error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Alle Notifications eines Users als gelesen markieren
async function markAllRead(req, res, userId) {
    try {
        const result = await pool.query(
            'UPDATE notifications SET is_read = TRUE WHERE recipient_id = $1 AND is_read = FALSE',
            [userId]
        );

        sendJSON(res, 200, { message: 'All notifications marked as read', count: result.rowCount });
    } catch (err) {
        console.error('markAllRead error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

module.exports = { getByUser, getUnreadCount, markRead, markAllRead };
