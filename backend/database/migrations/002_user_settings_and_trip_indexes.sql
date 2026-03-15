CREATE TABLE IF NOT EXISTS user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  emergency_contact_name VARCHAR(120),
  emergency_contact_phone VARCHAR(20),
  preferred_ride_type VARCHAR(30) DEFAULT 'economico',
  share_trip_default BOOLEAN NOT NULL DEFAULT FALSE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS pickup_notes TEXT,
  ADD COLUMN IF NOT EXISTS dropoff_notes TEXT;

CREATE INDEX IF NOT EXISTS idx_trips_driver_status ON trips (driver_id, status);
CREATE INDEX IF NOT EXISTS idx_trips_passenger_status ON trips (passenger_id, status);

