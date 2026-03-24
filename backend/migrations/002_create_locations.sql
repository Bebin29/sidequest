-- Migration: 002_create_locations
-- Tabelle: locations

CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    coordinates POINT NOT NULL,
    geohash TEXT NOT NULL,
    category TEXT NOT NULL,

    average_rating DOUBLE PRECISION NOT NULL DEFAULT 0,
    total_ratings INT NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES users(id),

    image_urls TEXT[] NOT NULL DEFAULT '{}',
    thumbnail_url TEXT,
    tags TEXT[] NOT NULL DEFAULT '{}',

    price_range TEXT,
    opening_hours JSONB,
    parking_info JSONB,
    accessibility JSONB,

    noise_level TEXT,
    wifi_available BOOLEAN,
    is_dog_friendly BOOLEAN,
    is_family_friendly BOOLEAN,

    phone_number TEXT,
    website TEXT,
    instagram_handle TEXT,

    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    report_count INT NOT NULL DEFAULT 0,
    trending_score DOUBLE PRECISION
);

CREATE INDEX idx_locations_category ON locations(category);
CREATE INDEX idx_locations_created_by ON locations(created_by);
CREATE INDEX idx_locations_geohash ON locations(geohash text_pattern_ops);
CREATE INDEX idx_locations_coordinates ON locations USING gist(coordinates);
CREATE INDEX idx_locations_average_rating ON locations(average_rating DESC);
CREATE INDEX idx_locations_created_at ON locations(created_at);
