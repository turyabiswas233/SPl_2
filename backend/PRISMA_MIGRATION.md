# Prisma ORM Migration Guide

## Completed Conversions
- ✅ Database Configuration (`config/database.js`)
- ✅ Prisma Schema (`prisma/schema.prisma`)
- ✅ Prisma Client (`db/prismaClient.js`)
- ✅ Auth Controller (`controllers/authController.js`)
- ✅ User Controller (`controllers/userController.js`)

## Remaining Controllers to Convert
- 🔄 Ride Controller (`controllers/rideController.js`) - 336 lines
- 🔄 Message Controller (`controllers/messageController.js`)
- 🔄 Notification Controller (`controllers/notificationController.js`)
- 🔄 Rating Controller (`controllers/ratingController.js`)
- 🔄 Request Controller (`controllers/requestController.js`)
- 🔄 SOS Controller (`controllers/sosController.js`)
- 🔄 Tracking Controller (`controllers/trackingController.js`)
- 🔄 Handshake Controller (`controllers/handshakeController.js`)
- 🔄 Mapbox Controller (`controllers/mapboxController.js`)

## Key Changes for All Controllers

Replace pool queries with Prisma client:

### Before (with pool):
```javascript
const pool = require('../db/db');
const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [userId]);
```

### After (with Prisma):
```javascript
const prisma = require('../db/prismaClient');
const user = await prisma.user.findUnique({
  where: { userId },
});
```

## Field Name Mapping
When converting queries, note the camelCase field names in Prisma:
- `user_id` → `userId`
- `full_name` → `fullName`
- `phone_number` → `phoneNumber`
- `registration_number` → `registrationNumber`
- `dept_name` → `deptName`
- `hall_name` → `hallName`
- `verification_status` → `verificationStatus`
- `preferred_gender` → `preferredGender`
- `start_location` → `startLocation`
- `start_lat` → `startLat`
- `start_lng` → `startLng`
- `destination_name` → `destinationName`
- `dest_lat` → `destLat`
- `dest_lng` → `destLng`
- `trip_qr_code` → `tripQrCode`
- `trip_otp` → `tripOtp`
- `max_seats` → `maxSeats`
- `ride_id` → `rideId`
- `initiator_id` → `initiatorId`
- `ride_status` → `RideStatus` (enum)
- etc.

## Setup Instructions

1. **Generate Prisma Client:**
   ```bash
   npx prisma generate
   ```

2. **Create Migration (if needed):**
   ```bash
   npx prisma migrate dev --name init
   ```

3. **Update Main Application File:**
   Replace imports in `index.js`:
   ```javascript
   // OLD
   const { pool, mongoose, initDB } = require("./config/database");
   
   // NEW
   const { prisma, initDB } = require("./config/database");
   ```

4. **Update Database Initialization in index.js:**
   ```javascript
   // Initialize database
   await initDB();
   ```

## Important Notes

- All Prisma operations are promise-based (async/await)
- UUID fields should not be generated in models; specify them as strings
- Use Prisma transactions for multi-table operations
- Error handling should wrap Prisma calls in try-catch blocks
- Field selection with `select` can improve performance
- Relations can be eagerly loaded with `include`

## Testing Checklist

After conversion:
- [ ] All authentication flows work
- [ ] User profiles can be retrieved
- [ ] Rides can be created and updated
- [ ] Participants can be added to rides
- [ ] Messages can be sent and retrieved
- [ ] Notifications are created properly
- [ ] Ratings are saved correctly
- [ ] SOS alerts work
- [ ] All timestamps work correctly
