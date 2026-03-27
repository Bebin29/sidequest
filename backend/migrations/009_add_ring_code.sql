ALTER TABLE users ADD COLUMN IF NOT EXISTS ring_code VARCHAR(72);

-- Generate binary ring codes for existing users
UPDATE users
SET ring_code = (
    SELECT string_agg(
        CASE WHEN get_bit(sha256(users.id::text::bytea), i) = 1 THEN '1' ELSE '0' END, ''
    )
    FROM generate_series(0, 71) AS i
)
WHERE ring_code IS NULL;
