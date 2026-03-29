-- Migration: RoundCode-Format statt binaerer Ring-Codes.
-- ring_code speichert jetzt uppercase-hex UUID-Prefix (max 27 Zeichen)
-- statt 96-stelligem Binaerstring.
-- Alle alten Codes invalidieren — werden beim naechsten Login regeneriert.
UPDATE users SET ring_code = NULL WHERE ring_code IS NOT NULL;
ALTER TABLE users ALTER COLUMN ring_code TYPE VARCHAR(27);
