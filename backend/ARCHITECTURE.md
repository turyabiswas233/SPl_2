# Dromos Backend - Professional RESTful API Structure

## 📁 New Folder Structure

```
backend/
├── server.js                 # Main entry point
├── package.json
├── .env
│
├── config/                   # Configuration files
│   ├── database.js          # Database connection configs
│   └── cors.js              # CORS configuration
│
├── controllers/              # Business logic
│   ├── authController.js    # Authentication/verification
│   ├── rideController.js    # Ride management
│   ├── requestController.js # Join requests
│   ├── handshakeController.js # QR verification
│   ├── trackingController.js  # GPS tracking
│   ├── messageController.js   # In-ride chat
│   ├── ratingController.js    # User ratings
│   ├── sosController.js       # Emergency alerts
│   ├── notificationController.js # Notifications
│   └── userController.js      # User profiles
│
├── routes/                   # API routes
│   ├── index.js             # Main router
│   ├── authRoutes.js
│   ├── rideRoutes.js
│   ├── requestRoutes.js
│   ├── messageRoutes.js
│   ├── ratingRoutes.js
│   ├── handshakeRoutes.js
│   ├── trackingRoutes.js
│   ├── sosRoutes.js
│   ├── notificationRoutes.js
│   └── userRoutes.js
│
├── middleware/               # Custom middleware
│   ├── errorHandler.js      # Global error handler
│   ├── validators.js        # Request validation
│   └── asyncHandler.js      # Async wrapper
│
├── models/                   # Database models
│   └── Movement.js          # MongoDB schema
│
├── db/                       # Database setup
│   ├── db.js               # PostgreSQL pool
│   ├── mongoose.js         # MongoDB connection
│   ├── initpsql.js         # Schema initialization
│   └── migrations/
│       └── init_schema.sql
│
└── utils/                    # Utility functions
    ├── responseFormatter.js # Standardize responses
    └── errors.js           # Custom error classes
```

## 🔄 API Route Changes

### Old Routes → New Routes

| Old Route | New Route | Method |
|-----------|-----------|--------|
| `/studentship/:id` | `/api/auth/studentship/:id` | GET |
| `/create-ride` | `/api/rides` | POST |
| `/track-movement` | `/api/tracking/movement` | POST |
| `/verify-handshake` | `/api/handshake/verify` | POST |
| `/rides` | `/api/rides` | GET |
| `/rides/:ride_id` | `/api/rides/:ride_id` | GET |
| `/rides/:ride_id/request` | `/api/rides/:ride_id/requests` | POST |
| `/rides/:ride_id/requests/:request_id` | `/api/rides/:ride_id/requests/:request_id` | PUT |
| `/rides/:ride_id/messages` | `/api/rides/:ride_id/messages` | GET/POST |
| `/rides/:ride_id/complete` | `/api/rides/:ride_id/complete` | POST |
| `/rides/:ride_id/ratings` | `/api/rides/:ride_id/ratings` | POST |
| `/sos` | `/api/sos` | POST |
| `/notifications/:user_id` | `/api/notifications/:user_id` | GET |
| `/notifications/:notification_id/read` | `/api/notifications/:notification_id/read` | PUT |
| `/users/:user_id/profile` | `/api/users/:user_id/profile` | GET |
| `/users/:user_id/ride-history` | `/api/users/:user_id/ride-history` | GET |

## 📝 Key Features

### 1. **Separation of Concerns**
- **Controllers**: Pure business logic
- **Routes**: Define endpoints and apply middleware
- **Middleware**: Validation, error handling, authentication
- **Utils**: Reusable helper functions

### 2. **Standardized Response Format**
All responses now follow a consistent structure:

```json
{
  "success": true/false,
  "message": "Optional message",
  "data": { /* response data */ }
}
```

### 3. **Centralized Error Handling**
- Custom error classes in `utils/errors.js`
- Global error handler in `middleware/errorHandler.js`
- Async error handling with `asyncHandler.js`

### 4. **Request Validation**
- Input validation middleware in `middleware/validators.js`
- UUID validation
- Required field checks
- Data type validation

### 5. **Modular Routes**
- Each resource has its own route file
- Nested routes using `mergeParams`
- Main router in `routes/index.js`

## 🚀 How to Run

```bash
# Install dependencies (if new packages needed)
npm install

# Start the server
npm start
```

The server will start on `http://localhost:3000` (or your configured PORT).

## 📚 API Documentation

Visit `http://localhost:3000/api/info` for complete API documentation.

## 🔧 Environment Variables

Required in `.env`:
```
PORT=3000
MONGO_URI=mongodb://localhost:27017/dromos
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=dromos
POSTGRES_USER=your_user
POSTGRES_PASSWORD=your_password
```

## 🎯 Benefits of New Structure

1. **Scalability**: Easy to add new features/endpoints
2. **Maintainability**: Clear separation makes debugging easier
3. **Testability**: Isolated controllers are easier to test
4. **Code Reusability**: Shared middleware and utilities
5. **Professional Standards**: Follows industry best practices
6. **Team Collaboration**: Clear structure for multiple developers

## 📋 Next Steps

1. ✅ Folder structure created
2. ✅ Controllers separated by resource
3. ✅ Routes modularized
4. ✅ Middleware implemented
5. ✅ Server refactored
6. 🔄 Update frontend to use new API endpoints (add `/api` prefix)
7. 🔄 Add authentication middleware (JWT)
8. 🔄 Add unit tests for controllers
9. 🔄 Add API rate limiting
10. 🔄 Add request logging

## 🔐 Security Improvements Suggested

- Add JWT authentication middleware
- Implement rate limiting
- Add helmet.js for security headers
- Validate all user inputs
- Add SQL injection prevention
- Implement CSRF protection
- Add request logging

## 📖 Example Usage

### Creating a Ride (New API)
```javascript
POST http://localhost:3000/api/rides
Content-Type: application/json

{
  "initiator_id": "uuid-here",
  "start_location": "Dhaka University",
  "start_lat": 23.7355,
  "start_lng": 90.3918,
  "destination": "Gulshan",
  "dest_lat": 23.7806,
  "dest_lng": 90.4193,
  "max_seats": 3
}
```

### Response
```json
{
  "success": true,
  "data": {
    "ride_id": "new-uuid",
    "trip_qr_code": "generated-qr",
    "trip_otp": "123456",
    ...
  }
}
```

---

**Note**: All old endpoints will need to be updated in the frontend to include the `/api` prefix.
