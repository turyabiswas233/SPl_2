-- 1. Enable Spatial Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. Create Custom Types (Enums)
CREATE TYPE app_role AS ENUM ('student', 'admin');
CREATE TYPE user_status AS ENUM ('unverified', 'verified', 'banned');
CREATE TYPE ride_status AS ENUM ('open', 'in_progress', 'completed', 'cancelled');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'any');
CREATE TYPE report_status AS ENUM ('pending', 'under_review', 'resolved', 'dismissed');

-- 3. Users Table (Academic & Identity Data)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(15) UNIQUE,
    role app_role DEFAULT 'student',
    
    -- Fields extracted via OCR/QR
    registration_number VARCHAR(20) UNIQUE,
    dept_name VARCHAR(100),
    session VARCHAR(15),
    hall_name VARCHAR(100),
    
    verification_status user_status DEFAULT 'unverified',
    id_card_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Rides Table (Trip Header)
CREATE TABLE rides (
    ride_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    initiator_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Starting Point
    start_location TEXT NOT NULL,
    start_coords GEOGRAPHY(POINT, 4326) NOT NULL,
    
    -- Destination
    destination_name TEXT NOT NULL,
    destination_coords GEOGRAPHY(POINT, 4326) NOT NULL,
    
    -- Security Handshake
    trip_qr_code TEXT UNIQUE NOT NULL,
    trip_otp CHAR(6) NOT NULL,
    
    -- Preferences & Status
    max_seats INTEGER NOT NULL CHECK (max_seats > 0),
    preferred_gender gender_type DEFAULT 'any',
    status ride_status DEFAULT 'open',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Ride Participants Table (Multi-passenger & Meeting Points)
CREATE TABLE ride_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID REFERENCES rides(ride_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Specific Meeting Point for this Passenger
    meeting_location TEXT,
    meeting_coords GEOGRAPHY(POINT, 4326),
    
    -- Handshake Status
    has_met BOOLEAN DEFAULT FALSE,
    met_at TIMESTAMP WITH TIME ZONE,
    
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent a user from joining the same ride multiple times
    UNIQUE(ride_id, user_id)
);

-- 6. Reports Table (Safety & Disciplinary)
CREATE TABLE reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(user_id),
    reported_user_id UUID REFERENCES users(user_id),
    ride_id UUID REFERENCES rides(ride_id),
    
    issue_type VARCHAR(50) NOT NULL, -- e.g., 'Route Deviation', 'Misconduct'
    description TEXT,
    status report_status DEFAULT 'pending',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Admin Audit Logs
CREATE TABLE admin_audit_logs (
    log_id SERIAL PRIMARY KEY,
    admin_id UUID REFERENCES users(user_id),
    action_type VARCHAR(50), -- e.g., 'BAN_USER', 'RESOLVE_REPORT'
    target_user_id UUID REFERENCES users(user_id),
    reason TEXT,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Indexes for Performance
CREATE INDEX idx_rides_start_coords ON rides USING GIST (start_coords);
CREATE INDEX idx_rides_status ON rides (status);
CREATE INDEX idx_participants_ride ON ride_participants (ride_id);
CREATE INDEX idx_users_reg_no ON users (registration_number);