ALTER TABLE users ADD COLUMN IF NOT EXISTS ring_code VARCHAR(96);

-- Generate ring codes for existing users that don't have one
UPDATE users
SET ring_code = substring(encode(sha256(id::text::bytea), 'hex') from 1 for 24)
WHERE ring_code IS NULL;
