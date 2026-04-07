const pool = require('../db/pool');
const { sendJSON } = require('../helpers');

async function getDashboard(req, res) {
    const start = Date.now();

    try {
        const [
            dbCheck,
            tableCounts,
            dbSize,
            userGrowth,
            userEngagement,
            topContributors,
            categoryDist,
            locationGrowth,
            friendshipStats,
            networkDensity,
            commentStats,
            activityFeed
        ] = await Promise.all([
            // 1 - DB health
            pool.query('SELECT NOW() AS server_time'),

            // 2 - Table counts
            pool.query(`
                SELECT
                    (SELECT COUNT(*) FROM users)::int AS users,
                    (SELECT COUNT(*) FROM locations)::int AS locations,
                    (SELECT COUNT(*) FROM comments)::int AS comments,
                    (SELECT COUNT(*) FROM friendships)::int AS friendships,
                    (SELECT COUNT(*) FROM notifications)::int AS notifications
            `),

            // 3 - Database + table sizes
            pool.query(`
                SELECT
                    pg_size_pretty(pg_database_size(current_database())) AS db_size,
                    (SELECT pg_size_pretty(pg_total_relation_size('users'))) AS users_size,
                    (SELECT pg_size_pretty(pg_total_relation_size('locations'))) AS locations_size,
                    (SELECT pg_size_pretty(pg_total_relation_size('comments'))) AS comments_size,
                    (SELECT pg_size_pretty(pg_total_relation_size('friendships'))) AS friendships_size,
                    (SELECT pg_size_pretty(pg_total_relation_size('notifications'))) AS notifications_size
            `),

            // 4 - User signups last 30 days
            pool.query(`
                SELECT d.day::date AS date, COALESCE(COUNT(u.id), 0)::int AS count
                FROM generate_series(CURRENT_DATE - INTERVAL '29 days', CURRENT_DATE, '1 day') AS d(day)
                LEFT JOIN users u ON u.created_at::date = d.day::date
                GROUP BY d.day ORDER BY d.day
            `),

            // 5 - User engagement snapshot
            pool.query(`
                SELECT
                    COUNT(*) FILTER (WHERE last_seen_at > NOW() - INTERVAL '24 hours')::int AS active_24h,
                    COUNT(*) FILTER (WHERE last_seen_at > NOW() - INTERVAL '7 days')::int AS active_7d,
                    COUNT(*) FILTER (WHERE last_seen_at > NOW() - INTERVAL '30 days')::int AS active_30d,
                    COUNT(*) FILTER (WHERE is_verified)::int AS verified_count,
                    COUNT(*) FILTER (WHERE is_moderator)::int AS moderator_count,
                    COUNT(*) FILTER (WHERE profile_image_url IS NOT NULL)::int AS with_avatar,
                    COUNT(*) FILTER (WHERE bio IS NOT NULL AND bio != '')::int AS with_bio,
                    COUNT(*)::int AS total
                FROM users
            `),

            // 6 - Top 5 contributors
            pool.query(`
                SELECT u.username, u.display_name,
                    COUNT(DISTINCT l.id)::int AS spot_count,
                    COUNT(DISTINCT c.id)::int AS comment_count
                FROM users u
                LEFT JOIN locations l ON l.created_by = u.id
                LEFT JOIN comments c ON c.user_id = u.id
                GROUP BY u.id, u.username, u.display_name
                ORDER BY spot_count DESC, comment_count DESC
                LIMIT 5
            `),

            // 7 - Category distribution
            pool.query(`
                SELECT category, COUNT(*)::int AS count
                FROM locations GROUP BY category ORDER BY count DESC
            `),

            // 8 - Location growth last 30 days
            pool.query(`
                SELECT d.day::date AS date, COALESCE(COUNT(l.id), 0)::int AS count
                FROM generate_series(CURRENT_DATE - INTERVAL '29 days', CURRENT_DATE, '1 day') AS d(day)
                LEFT JOIN locations l ON l.created_at::date = d.day::date
                GROUP BY d.day ORDER BY d.day
            `),

            // 9 - Friendship statistics
            pool.query(`
                SELECT
                    COUNT(*) FILTER (WHERE status = 'accepted')::int AS accepted,
                    COUNT(*) FILTER (WHERE status = 'pending')::int AS pending,
                    COUNT(*) FILTER (WHERE status = 'declined')::int AS declined,
                    COUNT(*) FILTER (WHERE status = 'blocked')::int AS blocked,
                    COUNT(*)::int AS total,
                    ROUND(AVG(EXTRACT(EPOCH FROM (accepted_at - created_at)) / 3600) FILTER (WHERE accepted_at IS NOT NULL)::numeric, 1) AS avg_accept_hours
                FROM friendships
            `),

            // 10 - Network density
            pool.query(`
                SELECT
                    ROUND(COUNT(*)::numeric * 2 / NULLIF((SELECT COUNT(*) FROM users), 0), 1) AS avg_friends_per_user,
                    COALESCE(MAX(sub.cnt), 0)::int AS max_friends
                FROM friendships f
                LEFT JOIN LATERAL (
                    SELECT COUNT(*) AS cnt FROM (
                        SELECT requester_id AS uid FROM friendships WHERE status = 'accepted'
                        UNION ALL
                        SELECT receiver_id FROM friendships WHERE status = 'accepted'
                    ) all_friends GROUP BY uid ORDER BY cnt DESC LIMIT 1
                ) sub ON true
                WHERE f.status = 'accepted'
            `),

            // 11 - Comment engagement
            pool.query(`
                SELECT
                    COUNT(*)::int AS total_comments,
                    COUNT(DISTINCT user_id)::int AS unique_commenters,
                    COUNT(DISTINCT location_id)::int AS locations_with_comments,
                    ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT location_id), 0), 1) AS avg_per_location
                FROM comments
            `),

            // 12 - Recent activity feed
            pool.query(`
                (
                    SELECT 'signup' AS type, username AS actor, display_name AS detail, NULL AS target, created_at
                    FROM users ORDER BY created_at DESC LIMIT 5
                )
                UNION ALL
                (
                    SELECT 'spot', u.username, l.name, l.category, l.created_at
                    FROM locations l JOIN users u ON l.created_by = u.id ORDER BY l.created_at DESC LIMIT 5
                )
                UNION ALL
                (
                    SELECT 'comment', c.username, LEFT(c.text, 50), l.name, c.created_at
                    FROM comments c JOIN locations l ON c.location_id = l.id ORDER BY c.created_at DESC LIMIT 5
                )
                UNION ALL
                (
                    SELECT 'friendship', requester_username, receiver_username, status, created_at
                    FROM friendships ORDER BY created_at DESC LIMIT 5
                )
                ORDER BY created_at DESC LIMIT 15
            `)
        ]);

        const queryMs = Date.now() - start;
        const mem = process.memoryUsage();
        const sizes = dbSize.rows[0];

        sendJSON(res, 200, {
            status: 'ok',
            timestamp: new Date().toISOString(),
            query_ms: queryMs,
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
                response_ms: Date.now() - start,
                server_time: dbCheck.rows[0].server_time,
                db_size: sizes.db_size,
                table_sizes: {
                    users: sizes.users_size,
                    locations: sizes.locations_size,
                    comments: sizes.comments_size,
                    friendships: sizes.friendships_size,
                    notifications: sizes.notifications_size
                }
            },
            tables: tableCounts.rows[0],
            user_analytics: {
                growth: userGrowth.rows.map(r => ({ date: r.date.toISOString().slice(0, 10), count: r.count })),
                engagement: userEngagement.rows[0],
                top_contributors: topContributors.rows
            },
            location_analytics: {
                growth: locationGrowth.rows.map(r => ({ date: r.date.toISOString().slice(0, 10), count: r.count })),
                categories: categoryDist.rows
            },
            social_analytics: {
                friendships: {
                    ...friendshipStats.rows[0],
                    avg_accept_hours: parseFloat(friendshipStats.rows[0].avg_accept_hours) || null
                },
                network: {
                    ...(networkDensity.rows[0] || { max_friends: 0 }),
                    avg_friends_per_user: parseFloat((networkDensity.rows[0] || {}).avg_friends_per_user) || 0
                },
                comments: {
                    ...commentStats.rows[0],
                    avg_per_location: parseFloat(commentStats.rows[0].avg_per_location) || null
                }
            },
            activity_feed: activityFeed.rows.map(r => ({
                type: r.type,
                actor: r.actor,
                detail: r.detail,
                target: r.target,
                created_at: r.created_at
            }))
        });
    } catch (err) {
        const mem = process.memoryUsage();
        sendJSON(res, 200, {
            status: 'degraded',
            timestamp: new Date().toISOString(),
            query_ms: Date.now() - start,
            server: {
                uptime_seconds: Math.floor(process.uptime()),
                node_version: process.version,
                memory_mb: {
                    rss: Math.round(mem.rss / 1024 / 1024),
                    heap_used: Math.round(mem.heapUsed / 1024 / 1024),
                    heap_total: Math.round(mem.heapTotal / 1024 / 1024)
                }
            },
            database: { connected: false, error: err.message },
            tables: null,
            user_analytics: null,
            location_analytics: null,
            social_analytics: null,
            activity_feed: null
        });
    }
}

module.exports = { getDashboard };
