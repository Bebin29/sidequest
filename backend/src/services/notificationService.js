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
    // Preferences ZUERST pruefen (spart Insert wenn deaktiviert)
    const result = await pool.query(
        'SELECT fcm_token, preferences FROM users WHERE id = $1',
        [recipientId]
    );

    if (result.rowCount === 0) return;

    const user = result.rows[0];

    // Wenn Notification-Typ deaktiviert, weder speichern noch senden
    if (!isEnabled(user.preferences, type)) return;

    // Notification in DB speichern
    await pool.query(
        `INSERT INTO notifications (recipient_id, sender_id, type, title, body, data)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [recipientId, senderId, type, title, body, data ? JSON.stringify(data) : null]
    );

    // Push senden wenn Token vorhanden
    if (user.fcm_token) {
        await apns.sendPush(user.fcm_token, { title, body, data, type });
    }
}

// --- Typisierte Notification-Funktionen ---

async function notifyFriendRequest(senderId, receiverId) {
    await createAndSend({
        recipientId: receiverId,
        senderId,
        type: 'friend_request',
        title: 'Neue Freundschaftsanfrage erhalten',
        body: 'Jemand moechte sich mit dir verbinden. Schau nach, wer es ist!',
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
        title: `${name} hat deine Anfrage angenommen`,
        body: 'Ihr seid jetzt befreundet. Entdeckt gemeinsam neue Spots!',
        data: { accepter_id: accepterId },
    });
}

async function notifyNewComment(commenterId, locationId) {
    const loc = await pool.query('SELECT created_by, name FROM locations WHERE id = $1', [locationId]);
    if (loc.rowCount === 0) return;

    const ownerId = loc.rows[0].created_by;

    if (ownerId === commenterId) return;

    await createAndSend({
        recipientId: ownerId,
        senderId: commenterId,
        type: 'new_comment',
        title: 'Neuer Kommentar auf deinem Spot',
        body: 'Jemand hat einen deiner Beitraege kommentiert.',
        data: { location_id: locationId, commenter_id: commenterId },
    });
}

async function notifyFriendNewSpot(creatorId, locationName) {
    // 1. Alle Freunde + deren Preferences in einem Query holen (statt N einzelne)
    const friends = await pool.query(
        `SELECT u.id AS friend_id, u.fcm_token, u.preferences
         FROM friendships f
         JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.receiver_id ELSE f.requester_id END
         WHERE (f.requester_id = $1 OR f.receiver_id = $1) AND f.status = 'accepted'`,
        [creatorId]
    );

    if (friends.rowCount === 0) return;

    const type = 'friend_new_spot';
    const title = 'Neuer Spot von einem Freund';
    const body = 'Jemand aus deiner Freundesliste hat einen neuen Ort entdeckt.';
    const data = { creator_id: creatorId };
    const dataJson = JSON.stringify(data);

    // 2. Filtern: nur Freunde mit aktiviertem Notification-Typ
    const enabledFriends = friends.rows.filter(f => isEnabled(f.preferences, type));

    if (enabledFriends.length === 0) return;

    // 3. Batch-INSERT statt N einzelne INSERTs
    const values = [];
    const placeholders = [];
    let idx = 1;

    for (const friend of enabledFriends) {
        placeholders.push(`($${idx}, $${idx + 1}, $${idx + 2}, $${idx + 3}, $${idx + 4}, $${idx + 5})`);
        values.push(friend.friend_id, creatorId, type, title, body, dataJson);
        idx += 6;
    }

    await pool.query(
        `INSERT INTO notifications (recipient_id, sender_id, type, title, body, data)
         VALUES ${placeholders.join(', ')}`,
        values
    );

    // 4. Push-Notifications parallel senden (nur an Freunde mit Token)
    const pushPromises = enabledFriends
        .filter(f => f.fcm_token)
        .map(f =>
            apns.sendPush(f.fcm_token, { title, body, data, type })
                .catch(err => console.error('notifyFriendNewSpot push error:', err.message))
        );

    await Promise.all(pushPromises);
}

module.exports = {
    notifyFriendRequest,
    notifyFriendAccepted,
    notifyNewComment,
    notifyFriendNewSpot,
};
