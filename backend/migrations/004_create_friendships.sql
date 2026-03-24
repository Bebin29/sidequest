-- Migration: 004_create_friendships
-- Tabelle: friendships

CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMPTZ,

    requester_username TEXT NOT NULL,
    receiver_username TEXT NOT NULL,

    CONSTRAINT no_self_friendship CHECK (requester_id != receiver_id)
);

CREATE UNIQUE INDEX idx_friendships_pair ON friendships(
    LEAST(requester_id, receiver_id),
    GREATEST(requester_id, receiver_id)
);
CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_receiver ON friendships(receiver_id);
CREATE INDEX idx_friendships_status ON friendships(status);
