const pool = require('../db/pool');
const { sendJSON, sendError } = require('../helpers');

async function getStatus(req, res) {
    const start = Date.now();

    try {
        // DB-Verbindungstest + Antwortzeit messen
        const dbResult = await pool.query('SELECT NOW() AS server_time');
        const dbResponseMs = Date.now() - start;

        // Tabellen-Statistiken parallel abfragen
        const counts = await pool.query(`
            SELECT
                (SELECT COUNT(*) FROM users)::int        AS users,
                (SELECT COUNT(*) FROM locations)::int     AS locations,
                (SELECT COUNT(*) FROM ratings)::int       AS ratings,
                (SELECT COUNT(*) FROM comments)::int      AS comments,
                (SELECT COUNT(*) FROM friendships)::int   AS friendships,
                (SELECT COUNT(*) FROM notifications)::int AS notifications
        `);

        const mem = process.memoryUsage();

        sendJSON(res, 200, {
            status: 'ok',
            timestamp: new Date().toISOString(),
            server: {
                uptime_seconds: Math.floor(process.uptime()),
                node_version: process.version,
                memory_mb: {
                    rss: Math.round(mem.rss / 1024 / 1024),
                    heap_used: Math.round(mem.heapUsed / 1024 / 1024),
                    heap_total: Math.round(mem.heapTotal / 1024 / 1024)
                }
            },
            database: {
                connected: true,
                response_ms: dbResponseMs,
                server_time: dbResult.rows[0].server_time
            },
            tables: counts.rows[0]
        });
    } catch (err) {
        sendJSON(res, 200, {
            status: 'degraded',
            timestamp: new Date().toISOString(),
            server: {
                uptime_seconds: Math.floor(process.uptime()),
                node_version: process.version,
                memory_mb: {
                    rss: Math.round(process.memoryUsage().rss / 1024 / 1024),
                    heap_used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
                    heap_total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
                }
            },
            database: {
                connected: false,
                error: err.message
            },
            tables: null
        });
    }
}

module.exports = { getStatus };
