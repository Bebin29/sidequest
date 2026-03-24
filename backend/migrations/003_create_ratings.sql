-- Migration: 003_create_ratings
-- Tabelle: ratings

CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
    location_name TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    user_profile_image_url TEXT,

    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    image_urls TEXT[] NOT NULL DEFAULT '{}',
    thumbnail_urls TEXT[] NOT NULL DEFAULT '{}',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,

    trip_id UUID,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMPTZ,

    report_count INT NOT NULL DEFAULT 0,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,

    reaction_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    helpful_count INT NOT NULL DEFAULT 0,

    visit_date TIMESTAMPTZ,
    price_spent DOUBLE PRECISION,
    would_recommend BOOLEAN
);

CREATE INDEX idx_ratings_location_id ON ratings(location_id);
CREATE INDEX idx_ratings_user_id ON ratings(user_id);
CREATE INDEX idx_ratings_created_at ON ratings(created_at DESC);
CREATE INDEX idx_ratings_trip_id ON ratings(trip_id) WHERE trip_id IS NOT NULL;

-- Ein User kann eine Location nur einmal bewerten
CREATE UNIQUE INDEX idx_ratings_unique_user_location ON ratings(user_id, location_id);
