const pool = require('../db/pool');
const { parseBody, sendJSON, sendError } = require('../helpers');
const notificationService = require('../services/notificationService');

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

        if (requester_id.toLowerCase() === receiver_id.toLowerCase()) {
            return sendError(res, 400, 'Cannot send friend request to yourself');
        }

        // Requester Username holen
        const requester = await pool.query('SELECT username FROM users WHERE id = $1', [requester_id]);
        if (requester.rowCount === 0) {
            return sendError(res, 404, 'Requester not found');
        }

        // Prüfen ob eine abgelehnte Anfrage existiert — wenn ja, zurücksetzen
        const existing = await pool.query(
            `SELECT * FROM friendships
             WHERE LEAST(requester_id::text, receiver_id::text) = LEAST($1::text, $2::text)
               AND GREATEST(requester_id::text, receiver_id::text) = GREATEST($1::text, $2::text)`,
            [requester_id, receiver_id]
        );

        let result;
        if (existing.rowCount > 0 && existing.rows[0].status === 'declined') {
            result = await pool.query(
                `UPDATE friendships SET requester_id = $1, receiver_id = $2,
                    requester_username = $3, receiver_username = $4,
                    status = 'pending', updated_at = NOW()
                 WHERE id = $5 RETURNING *`,
                [requester_id, receiver_id, requester.rows[0].username, receiver.rows[0].username, existing.rows[0].id]
            );
        } else {
            result = await pool.query(
                `INSERT INTO friendships (requester_id, receiver_id, requester_username, receiver_username)
                 VALUES ($1, $2, $3, $4)
                 RETURNING *`,
                [requester_id, receiver_id, requester.rows[0].username, receiver.rows[0].username]
            );
        }

        sendJSON(res, 201, { data: result.rows[0] });

        // Push-Benachrichtigung (fire-and-forget)
        notificationService.notifyFriendRequest(requester_id, receiver_id)
            .catch(err => console.error('notify friend_request error:', err.message));
    } catch (err) {
        if (err.code === '23505') {
            return sendError(res, 409, 'Friend request already exists');
        }
        console.error('sendRequest error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Freunde-Vorschläge (Freunde von Freunden)
async function getSuggestions(req, res, userId) {
    try {
        const result = await pool.query(
            `WITH my_friends AS (
                SELECT CASE
                    WHEN requester_id = $1 THEN receiver_id
                    ELSE requester_id
                END AS friend_id
                FROM friendships
                WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'
            ),
            friend_of_friends AS (
                SELECT CASE
                    WHEN f.requester_id = mf.friend_id THEN f.receiver_id
                    ELSE f.requester_id
                END AS suggested_id,
                mf.friend_id AS via_friend_id
                FROM friendships f
                JOIN my_friends mf ON (f.requester_id = mf.friend_id OR f.receiver_id = mf.friend_id)
                WHERE f.status = 'accepted'
                  AND CASE WHEN f.requester_id = mf.friend_id THEN f.receiver_id ELSE f.requester_id END != $1
            )
            SELECT
                u.id, u.username, u.display_name, u.profile_image_url,
                COUNT(DISTINCT fof.via_friend_id)::int AS mutual_count,
                ARRAY_AGG(DISTINCT vu.username) AS mutual_usernames
            FROM friend_of_friends fof
            JOIN users u ON u.id = fof.suggested_id
            JOIN users vu ON vu.id = fof.via_friend_id
            WHERE fof.suggested_id NOT IN (SELECT friend_id FROM my_friends)
              AND fof.suggested_id NOT IN (
                  SELECT CASE WHEN requester_id = $1 THEN receiver_id ELSE requester_id END
                  FROM friendships WHERE (requester_id = $1 OR receiver_id = $1) AND status IN ('pending', 'declined', 'blocked')
              )
            GROUP BY u.id, u.username, u.display_name, u.profile_image_url
            ORDER BY mutual_count DESC
            LIMIT 10`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows });
    } catch (err) {
        console.error('getSuggestions error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Freundesliste (akzeptierte Freundschaften)
async function getFriends(req, res, userId) {
    try {
        const result = await pool.query(
            `SELECT f.*,
                req.display_name AS requester_display_name,
                req.profile_image_url AS requester_profile_image_url,
                rec.display_name AS receiver_display_name,
                rec.profile_image_url AS receiver_profile_image_url,
                (SELECT COUNT(*)::int FROM locations WHERE created_by = f.requester_id) AS requester_spot_count,
                (SELECT COUNT(*)::int FROM locations WHERE created_by = f.receiver_id) AS receiver_spot_count
             FROM friendships f
             JOIN users req ON req.id = f.requester_id
             JOIN users rec ON rec.id = f.receiver_id
             WHERE (f.requester_id = $1 OR f.receiver_id = $1) AND f.status = 'accepted'
             ORDER BY f.accepted_at DESC`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getFriends error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Eingehende Anfragen (mit Mutual Count und Profil-Info)
async function getPendingRequests(req, res, userId) {
    try {
        const result = await pool.query(
            `SELECT f.*,
                u.display_name AS requester_display_name,
                u.profile_image_url AS requester_profile_image_url,
                COALESCE(mc.mutual_count, 0)::int AS mutual_count
            FROM friendships f
            JOIN users u ON u.id = f.requester_id
            LEFT JOIN LATERAL (
                SELECT COUNT(*)::int AS mutual_count FROM (
                    SELECT CASE WHEN requester_id = f.requester_id THEN receiver_id ELSE requester_id END AS fid
                    FROM friendships WHERE (requester_id = f.requester_id OR receiver_id = f.requester_id) AND status = 'accepted'
                    INTERSECT
                    SELECT CASE WHEN requester_id = $1 THEN receiver_id ELSE requester_id END AS fid
                    FROM friendships WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'
                ) shared
            ) mc ON true
            WHERE f.receiver_id = $1 AND f.status = 'pending'
            ORDER BY f.created_at DESC`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getPendingRequests error:', err);
        sendError(res, 500, 'Internal server error');
    }
}

// Gesendete ausstehende Anfragen (mit Empfänger-Info und Mutual Count)
async function getSentRequests(req, res, userId) {
    try {
        const result = await pool.query(
            `SELECT f.*,
                u.display_name AS receiver_display_name,
                u.profile_image_url AS receiver_profile_image_url,
                COALESCE(mc.mutual_count, 0)::int AS mutual_count
            FROM friendships f
            JOIN users u ON u.id = f.receiver_id
            LEFT JOIN LATERAL (
                SELECT COUNT(*)::int AS mutual_count FROM (
                    SELECT CASE WHEN requester_id = f.receiver_id THEN receiver_id ELSE requester_id END AS fid
                    FROM friendships WHERE (requester_id = f.receiver_id OR receiver_id = f.receiver_id) AND status = 'accepted'
                    INTERSECT
                    SELECT CASE WHEN requester_id = $1 THEN receiver_id ELSE requester_id END AS fid
                    FROM friendships WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'
                ) shared
            ) mc ON true
            WHERE f.requester_id = $1 AND f.status = 'pending'
            ORDER BY f.created_at DESC`,
            [userId]
        );
        sendJSON(res, 200, { data: result.rows, count: result.rowCount });
    } catch (err) {
        console.error('getSentRequests error:', err);
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

        // Push-Benachrichtigung bei Akzeptierung (fire-and-forget)
        if (status === 'accepted') {
            const friendship = result.rows[0];
            notificationService.notifyFriendAccepted(friendship.receiver_id, friendship.requester_id)
                .catch(err => console.error('notify friend_accepted error:', err.message));
        }
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

module.exports = { sendRequest, getFriends, getSuggestions, getPendingRequests, getSentRequests, updateStatus, remove, searchUsers };
