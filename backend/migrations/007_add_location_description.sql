-- Migration: 007_add_location_description
-- Beschreibung für Locations

ALTER TABLE locations ADD COLUMN IF NOT EXISTS description TEXT;
