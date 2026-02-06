-- 1. Remove CREATE EXTENSION lines (We don't need them anymore!)

-- 2. Keep ENUMS (with IF NOT EXISTS to avoid errors on re-run)
DO $$ BEGIN
    CREATE TYPE app_role AS ENUM ('student', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('unverified', 'verified', 'banned');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ride_status AS ENUM ('open', 'in_progress', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE report_status AS ENUM ('pending', 'resolved', 'dismissed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Update Tables to accept manual UUIDs and Float Coordinates

CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY, -- Removed DEFAULT uuid_generate_v4()
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE, -- Made email nullable if not always provided
    password VARCHAR(255), -- Hashed password for email/password auth
    phone_number VARCHAR(15) UNIQUE,
    gender VARCHAR(10),
    role app_role DEFAULT 'student',
    
    registration_number VARCHAR(20) UNIQUE,
    dept_name VARCHAR(100),
    hall_name VARCHAR(100),
    verification_status user_status DEFAULT 'unverified',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rides (
    ride_id UUID PRIMARY KEY, -- Manual UUID
    initiator_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    preferred_gender gender_type DEFAULT 'any',

    start_location TEXT NOT NULL,
    start_lat FLOAT NOT NULL, -- Changed from GEOGRAPHY
    start_lng FLOAT NOT NULL, -- Changed from GEOGRAPHY
    
    destination_name TEXT NOT NULL,
    dest_lat FLOAT NOT NULL, -- Changed from GEOGRAPHY
    dest_lng FLOAT NOT NULL, -- Changed from GEOGRAPHY
    
    trip_qr_code TEXT UNIQUE NOT NULL,
    trip_otp CHAR(6) NOT NULL,
    max_seats INTEGER NOT NULL,
    status ride_status DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ride_participants (
    ride_participant_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    participant_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    
    meeting_lat FLOAT, -- Coordinate stored as simple number
    meeting_lng FLOAT, -- Coordinate stored as simple number
    
    has_met BOOLEAN DEFAULT FALSE,
    met_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(ride_id, user_id, participant_id)
);

CREATE TABLE IF NOT EXISTS reports (
    report_id UUID PRIMARY KEY,
    reporter_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    reported_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    issue_type VARCHAR(255) NOT NULL,
    status report_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    notification_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ride_requests (
    request_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    requester_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ride_id, requester_id)
);

CREATE TABLE IF NOT EXISTS messages (
    message_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ratings (
    rating_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    rater_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    rated_user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ride_id, rater_id, rated_user_id)
);

CREATE TABLE IF NOT EXISTS fares (
    fare_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    paid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sos_alerts (
    alert_id UUID PRIMARY KEY,
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL, -- route_deviation, emergency, other
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    status VARCHAR(20) DEFAULT 'active', -- active, resolved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- (Keep other tables, ensure UUID defaults removed where applicable)