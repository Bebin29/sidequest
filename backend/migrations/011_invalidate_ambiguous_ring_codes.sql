-- Alle Ring-Codes invalidieren: alte Codes haben nicht-eindeutige Sync-Marker.
-- Werden beim naechsten Login automatisch mit dem korrigierten Generator neu erzeugt.
UPDATE users SET ring_code = NULL WHERE ring_code IS NOT NULL;
