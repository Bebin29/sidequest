/**
 * In-Memory Rate Limiter.
 * Begrenzt Requests pro IP-Adresse mit konfigurierbaren Limits pro Route-Kategorie.
 */

const limits = {
    read: { windowMs: 60000, maxRequests: 100 },   // 100 Reads pro Minute
    write: { windowMs: 60000, maxRequests: 30 },    // 30 Writes pro Minute
    auth: { windowMs: 60000, maxRequests: 10 },     // 10 Auth-Versuche pro Minute
    upload: { windowMs: 60000, maxRequests: 10 },   // 10 Uploads pro Minute
};

// Map<ip, Map<category, { count, resetAt }>>
const store = new Map();

// Alte Eintraege alle 5 Minuten aufraeumen
setInterval(() => {
    const now = Date.now();
    for (const [ip, categories] of store) {
        for (const [cat, entry] of categories) {
            if (entry.resetAt < now) {
                categories.delete(cat);
            }
        }
        if (categories.size === 0) {
            store.delete(ip);
        }
    }
}, 5 * 60 * 1000);

/**
 * Bestimmt die Rate-Limit-Kategorie basierend auf Method und Pfad.
 */
function getCategory(method, pathname) {
    if (pathname.includes('/api/auth')) return 'auth';
    if (pathname.includes('/api/uploads')) return 'upload';
    if (method === 'GET') return 'read';
    return 'write'; // POST, PUT, PATCH, DELETE
}

/**
 * Prueft ob ein Request das Rate Limit ueberschreitet.
 * @param {string} ip - Client IP-Adresse
 * @param {string} method - HTTP Method
 * @param {string} pathname - URL Pfad
 * @returns {{ allowed: boolean, remaining: number, resetAt: number }}
 */
function checkRateLimit(ip, method, pathname) {
    const category = getCategory(method, pathname);
    const config = limits[category];
    const now = Date.now();

    if (!store.has(ip)) {
        store.set(ip, new Map());
    }
    const ipStore = store.get(ip);

    if (!ipStore.has(category) || ipStore.get(category).resetAt < now) {
        ipStore.set(category, { count: 0, resetAt: now + config.windowMs });
    }

    const entry = ipStore.get(category);
    entry.count++;

    const remaining = Math.max(0, config.maxRequests - entry.count);
    const allowed = entry.count <= config.maxRequests;

    return { allowed, remaining, resetAt: entry.resetAt };
}

module.exports = { checkRateLimit };
