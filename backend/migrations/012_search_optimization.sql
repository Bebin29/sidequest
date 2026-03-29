-- Trigram-Index fuer performante ILIKE-Suche auf Usernamen
-- PostgreSQL nutzt diesen Index automatisch bei ILIKE '%pattern%' Queries
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_users_username_trgm
ON users USING gin(username gin_trgm_ops);
