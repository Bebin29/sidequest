-- Migration: 006_add_apple_user_id
-- Apple Sign In User-Verknüpfung

ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_user_id TEXT UNIQUE;
