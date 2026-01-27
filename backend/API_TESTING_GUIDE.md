# API Testing Guide

Quick reference for testing all endpoints with curl or Postman.

## Setup
```bash
# Start the server
npm start

# The server runs on http://localhost:3000
```

---

## 1. Identity Verification
```bash
# Verify student
curl http://localhost:3000/studentship/2019115042
```

---

## 2. Create a Ride
```bash
curl -X POST http://localhost:3000/create-ride \
  -H "Content-Type: application/json" \
  -d '{
    "initiator_id": "USER_UUID_HERE",
    "start_location": "TSC",
    "start_lat": 23.7367,
    "start_lng": 90.3932,
    "destination": "Science Lab",
    "dest_lat": 23.7422,
    "dest_lng": 90.3762,
    "max_seats": 3
  }'
```

---

## 3. Browse Rides
```bash
# All rides
curl http://localhost:3000/rides

# With filters
curl "http://localhost:3000/rides?gender_filter=female&min_seats=2&destination=Science%20Lab"

# Specific ride details
curl http://localhost:3000/rides/RIDE_UUID_HERE
```

---

## 4. Request to Join Ride
```bash
curl -X POST http://localhost:3000/rides/RIDE_UUID/request \
  -H "Content-Type: application/json" \
  -d '{
    "requester_id": "USER_UUID_HERE"
  }'
```

---

## 5. Accept/Reject Request
```bash
# Accept
curl -X PUT http://localhost:3000/rides/RIDE_UUID/requests/REQUEST_UUID \
  -H "Content-Type: application/json" \
  -d '{
    "action": "accept",
    "meeting_lat": 23.7367,
    "meeting_lng": 90.3932
  }'

# Reject
curl -X PUT http://localhost:3000/rides/RIDE_UUID/requests/REQUEST_UUID \
  -H "Content-Type: application/json" \
  -d '{
    "action": "reject"
  }'
```

---

## 6. Handshake Verification
```bash
curl -X POST http://localhost:3000/verify-handshake \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": "RIDE_UUID_HERE",
    "user_id": "USER_UUID_HERE",
    "scanned_qr_code": "QR_CODE_FROM_RIDE",
    "current_lat": 23.7367,
    "current_lng": 90.3932
  }'
```

---

## 7. In-App Messaging
```bash
# Send message
curl -X POST http://localhost:3000/rides/RIDE_UUID/messages \
  -H "Content-Type: application/json" \
  -d '{
    "sender_id": "USER_UUID_HERE",
    "message_text": "I am wearing a red jacket"
  }'

# Get messages
curl http://localhost:3000/rides/RIDE_UUID/messages
```

---

## 8. GPS Tracking
```bash
curl -X POST http://localhost:3000/track-movement \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": "RIDE_UUID_HERE",
    "user_id": "USER_UUID_HERE",
    "latitude": 23.7367,
    "longitude": 90.3932
  }'
```

---

## 9. Complete Trip
```bash
curl -X POST http://localhost:3000/rides/RIDE_UUID/complete \
  -H "Content-Type: application/json" \
  -d '{
    "initiator_id": "USER_UUID_HERE",
    "total_fare": 150.00
  }'
```

---

## 10. Submit Rating
```bash
curl -X POST http://localhost:3000/rides/RIDE_UUID/ratings \
  -H "Content-Type: application/json" \
  -d '{
    "rater_id": "USER_UUID_HERE",
    "rated_user_id": "OTHER_USER_UUID",
    "rating": 5,
    "comment": "Great co-passenger!"
  }'
```

---

## 11. SOS Emergency
```bash
curl -X POST http://localhost:3000/sos \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": "RIDE_UUID_HERE",
    "user_id": "USER_UUID_HERE",
    "alert_type": "emergency",
    "latitude": 23.7367,
    "longitude": 90.3932
  }'
```

---

## 12. User Profile & History
```bash
# Get profile
curl http://localhost:3000/users/USER_UUID/profile

# Get ride history
curl http://localhost:3000/users/USER_UUID/ride-history
```

---

## 13. Notifications
```bash
# Get notifications
curl http://localhost:3000/notifications/USER_UUID

# Mark as read
curl -X PUT http://localhost:3000/notifications/NOTIFICATION_UUID/read
```

---

## 14. API Documentation
```bash
# Get all endpoints
curl http://localhost:3000/api-info
```

---

## Sample Test Flow

### Step 1: Create two users
```bash
# User A (Initiator)
curl http://localhost:3000/studentship/2019115042
# Note the user_id returned

# User B (Requester)
curl http://localhost:3000/studentship/2019115043
# Note the user_id returned
```

### Step 2: User A creates a ride
```bash
curl -X POST http://localhost:3000/create-ride \
  -H "Content-Type: application/json" \
  -d '{
    "initiator_id": "USER_A_UUID",
    "start_location": "TSC",
    "start_lat": 23.7367,
    "start_lng": 90.3932,
    "destination": "Science Lab",
    "dest_lat": 23.7422,
    "dest_lng": 90.3762,
    "max_seats": 3
  }'
# Note the ride_id returned
```

### Step 3: User B browses and requests
```bash
# Browse
curl http://localhost:3000/rides

# Request to join
curl -X POST http://localhost:3000/rides/RIDE_UUID/request \
  -H "Content-Type: application/json" \
  -d '{"requester_id": "USER_B_UUID"}'
# Note the request_id returned
```

### Step 4: User A accepts
```bash
curl -X PUT http://localhost:3000/rides/RIDE_UUID/requests/REQUEST_UUID \
  -H "Content-Type: application/json" \
  -d '{
    "action": "accept",
    "meeting_lat": 23.7367,
    "meeting_lng": 90.3932
  }'
```

### Step 5: They chat
```bash
# User A sends message
curl -X POST http://localhost:3000/rides/RIDE_UUID/messages \
  -H "Content-Type: application/json" \
  -d '{"sender_id": "USER_A_UUID", "message_text": "Meet at gate 3"}'

# User B reads
curl http://localhost:3000/rides/RIDE_UUID/messages
```

### Step 6: User B scans QR
```bash
curl -X POST http://localhost:3000/verify-handshake \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": "RIDE_UUID",
    "user_id": "USER_B_UUID",
    "scanned_qr_code": "QR_FROM_STEP_2",
    "current_lat": 23.7367,
    "current_lng": 90.3932
  }'
```

### Step 7: User A completes trip
```bash
curl -X POST http://localhost:3000/rides/RIDE_UUID/complete \
  -H "Content-Type: application/json" \
  -d '{"initiator_id": "USER_A_UUID", "total_fare": 100}'
```

### Step 8: Both rate each other
```bash
# User A rates User B
curl -X POST http://localhost:3000/rides/RIDE_UUID/ratings \
  -H "Content-Type: application/json" \
  -d '{
    "rater_id": "USER_A_UUID",
    "rated_user_id": "USER_B_UUID",
    "rating": 5,
    "comment": "Great passenger!"
  }'

# User B rates User A
curl -X POST http://localhost:3000/rides/RIDE_UUID/ratings \
  -H "Content-Type: application/json" \
  -d '{
    "rater_id": "USER_B_UUID",
    "rated_user_id": "USER_A_UUID",
    "rating": 5,
    "comment": "Excellent driver!"
  }'
```

---

## Environment Variables Required

Create a `.env` file:
```env
PORT=3000
MONGO_URI=mongodb://localhost:27017/dromos
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_password
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=dromos
```
