const pool = require('../db/pool');
const apns = require('./apnsService');

/**
 * Pruefen ob ein Notification-Typ in den User-Preferences aktiviert ist.
 * Default: alle aktiviert (fehlender Key = true).
 */
function isEnabled(preferences, type) {
    if (!preferences) return true;
    const key = `notif_${type}`;
    return preferences[key] !== 'false';
}

/**
 * Notification erstellen und optional Push senden.
 * @param {object} options
 * @param {string} options.recipientId - UUID des Empfaengers
 * @param {string} options.senderId - UUID des Absenders
 * @param {string} options.type - Notification-Typ
 * @param {string} options.title - Titel
 * @param {string} options.body - Text
 * @param {object} [options.data] - Zusaetzliche Daten (location_id etc.)
 */
async function createAndSend({ recipientId, senderId, type, title, body, data }) {
    // Notification in DB speichern
    await pool.query(
        `INSERT INTO notifications (recipient_id, sender_id, type, title, body, data)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [recipientId, senderId, type, title, body, data ? JSON.stringify(data) : null]
    );

    // Empfaenger-Daten holen fuer Push
    const result = await pool.query(
        'SELECT fcm_token, preferences FROM users WHERE id = $1',
        [recipientId]
    );

    if (result.rowCount === 0) return;

    const user = result.rows[0];

    // Preference pruefen
    if (!isEnabled(user.preferences, type)) return;

    // Push senden wenn Token vorhanden
    if (user.fcm_token) {
        await apns.sendPush(user.fcm_token, { title, body, data, type });
    }
}

// --- Typisierte Notification-Funktionen ---

async function notifyFriendRequest(senderId, receiverId) {
    const sender = await pool.query('SELECT display_name FROM users WHERE id = $1', [senderId]);
    if (sender.rowCount === 0) return;

    const name = sender.rows[0].display_name;

    await createAndSend({
        recipientId: receiverId,
        senderId,
        type: 'friend_request',
        title: 'Neue Freundschaftsanfrage',
        body: `${name} moechte mit dir befreundet sein`,
        data: { sender_id: senderId },
    });
}

async function notifyFriendAccepted(accepterId, requesterId) {
    const accepter = await pool.query('SELECT display_name FROM users WHERE id = $1', [accepterId]);
    if (accepter.rowCount === 0) return;

    const name = accepter.rows[0].display_name;

    await createAndSend({
        recipientId: requesterId,
        senderId: accepterId,
        type: 'friend_accepted',
        title: 'Freundschaftsanfrage akzeptiert',
        body: `${name} hat deine Freundschaftsanfrage angenommen`,
        data: { accepter_id: accepterId },
    });
}

async function notifyNewComment(commenterId, locationId) {
    // Location-Owner und Location-Name holen
    const loc = await pool.query('SELECT created_by, name FROM locations WHERE id = $1', [locationId]);
    if (loc.rowCount === 0) return;

    const ownerId = loc.rows[0].created_by;

    // Nicht benachrichtigen wenn man seinen eigenen Spot kommentiert
    if (ownerId === commenterId) return;

    const commenter = await pool.query('SELECT display_name FROM users WHERE id = $1', [commenterId]);
    if (commenter.rowCount === 0) return;

    const commenterName = commenter.rows[0].display_name;
    const locationName = loc.rows[0].name;

    await createAndSend({
        recipientId: ownerId,
        senderId: commenterId,
        type: 'new_comment',
        title: 'Neuer Kommentar',
        body: `${commenterName} hat "${locationName}" kommentiert`,
        data: { location_id: locationId, commenter_id: commenterId },
    });
}

async function notifyFriendNewSpot(creatorId, locationName) {
    // Alle Freunde des Erstellers holen
    const friends = await pool.query(
        `SELECT CASE
            WHEN requester_id = $1 THEN receiver_id
            ELSE requester_id
         END AS friend_id
         FROM friendships
         WHERE (requester_id = $1 OR receiver_id = $1) AND status = 'accepted'`,
        [creatorId]
    );

    if (friends.rowCount === 0) return;

    const creator = await pool.query('SELECT display_name FROM users WHERE id = $1', [creatorId]);
    if (creator.rowCount === 0) return;

    const creatorName = creator.rows[0].display_name;

    // An jeden Freund senden (parallel)
    const promises = friends.rows.map((row) =>
        createAndSend({
            recipientId: row.friend_id,
            senderId: creatorId,
            type: 'friend_new_spot',
            title: 'Neuer Spot',
            body: `${creatorName} hat "${locationName}" hinzugefuegt`,
            data: { creator_id: creatorId },
        }).catch((err) => console.error('notifyFriendNewSpot error:', err.message))
    );

    await Promise.all(promises);
}

module.exports = {
    notifyFriendRequest,
    notifyFriendAccepted,
    notifyNewComment,
    notifyFriendNewSpot,
};
