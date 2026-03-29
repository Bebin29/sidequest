-- Ring-Code Hamming-Distanz-Matching in SQL
-- Ersetzt den bisherigen Full-Table-Scan im Node.js-Code

-- Funktion: Berechnet minimale Hamming-Distanz zwischen zwei 72-Bit Ring-Codes
-- ueber alle 24 Rotationen (alle 3 Ringe rotieren gemeinsam um dieselbe Position)
CREATE OR REPLACE FUNCTION ring_code_min_hamming(scanned TEXT, stored TEXT)
RETURNS INTEGER AS $$
DECLARE
    min_dist INTEGER := 72;
    current_dist INTEGER;
    rotation INTEGER;
    ring INTEGER;
    pos INTEGER;
    rotated_pos INTEGER;
    ring_offset INTEGER;
BEGIN
    -- Beide Codes muessen 72 Zeichen lang sein
    IF length(scanned) != 72 OR length(stored) != 72 THEN
        RETURN 72;
    END IF;

    FOR rotation IN 0..23 LOOP
        current_dist := 0;
        FOR ring IN 0..2 LOOP
            ring_offset := ring * 24;
            FOR pos IN 1..24 LOOP
                rotated_pos := ((pos - 1 + rotation) % 24) + 1;
                IF substr(scanned, ring_offset + pos, 1) != substr(stored, ring_offset + rotated_pos, 1) THEN
                    current_dist := current_dist + 1;
                END IF;
            END LOOP;
            -- Early exit wenn bereits schlechter als bisher bester
            IF current_dist >= min_dist THEN
                EXIT;
            END IF;
        END LOOP;
        IF current_dist < min_dist THEN
            min_dist := current_dist;
        END IF;
        -- Perfekter Match gefunden
        IF min_dist = 0 THEN
            RETURN 0;
        END IF;
    END LOOP;

    RETURN min_dist;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
