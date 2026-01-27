# Dromos Backend Architecture Diagram

## 📊 Request Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                           CLIENT REQUEST                             │
│                    (Frontend/Mobile App)                             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          EXPRESS SERVER                              │
│                         (server.js)                                  │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Middleware Layer                          │   │
│  │  • express.json() - Parse JSON                              │   │
│  │  • express.urlencoded() - Parse URL encoded                 │   │
│  │  • cors() - Handle CORS                                     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Routes Layer                             │   │
│  │              (routes/index.js)                              │   │
│  │                                                              │   │
│  │  /api/auth          → authRoutes.js                         │   │
│  │  /api/rides         → rideRoutes.js                         │   │
│  │  /api/handshake     → handshakeRoutes.js                    │   │
│  │  /api/tracking      → trackingRoutes.js                     │   │
│  │  /api/sos           → sosRoutes.js                          │   │
│  │  /api/notifications → notificationRoutes.js                 │   │
│  │  /api/users         → userRoutes.js                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Validation Middleware                           │   │
│  │          (middleware/validators.js)                         │   │
│  │  • validateRideCreation()                                   │   │
│  │  • validateMovementTracking()                               │   │
│  │  • validateRating()                                         │   │
│  │  • validateUUID()                                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Async Handler Wrapper                           │   │
│  │          (middleware/asyncHandler.js)                       │   │
│  │  • Catches async errors automatically                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  Controllers Layer                           │   │
│  │              (Business Logic)                               │   │
│  │                                                              │   │
│  │  • authController.js        • messageController.js          │   │
│  │  • rideController.js        • ratingController.js           │   │
│  │  • requestController.js     • sosController.js              │   │
│  │  • handshakeController.js   • notificationController.js     │   │
│  │  • trackingController.js    • userController.js             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   Database Layer                             │   │
│  │                                                              │   │
│  │  ┌────────────────────┐      ┌────────────────────┐        │   │
│  │  │   PostgreSQL       │      │     MongoDB        │        │   │
│  │  │   (db/db.js)       │      │  (db/mongoose.js)  │        │   │
│  │  │                    │      │                    │        │   │
│  │  │ • Users            │      │ • Movement Logs    │        │   │
│  │  │ • Rides            │      │   (GPS Tracking)   │        │   │
│  │  │ • Participants     │      │                    │        │   │
│  │  │ • Requests         │      │                    │        │   │
│  │  │ • Messages         │      │                    │        │   │
│  │  │ • Ratings          │      │                    │        │   │
│  │  │ • Notifications    │      │                    │        │   │
│  │  │ • SOS Alerts       │      │                    │        │   │
│  │  └────────────────────┘      └────────────────────┘        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Error Handler Middleware                        │   │
│  │          (middleware/errorHandler.js)                       │   │
│  │  • Catches all errors                                       │   │
│  │  • Formats error response                                   │   │
│  │  • Logs errors                                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         JSON RESPONSE                                │
│                  { success, data/error }                             │
└─────────────────────────────────────────────────────────────────────┘
```

## 🏗️ Layer Responsibilities

### 1. **Server Layer** (server.js)
- Initialize Express app
- Configure middleware
- Mount routes
- Connect to databases
- Start server

### 2. **Routes Layer** (routes/)
- Define API endpoints
- Apply middleware to routes
- Connect routes to controllers
- Handle nested routes

### 3. **Middleware Layer** (middleware/)
- **validators.js**: Validate incoming requests
- **asyncHandler.js**: Wrap async functions
- **errorHandler.js**: Catch and format errors

### 4. **Controllers Layer** (controllers/)
- Contain business logic
- Interact with database
- Process data
- Return responses

### 5. **Database Layer**
- **PostgreSQL**: Relational data (users, rides, messages, etc.)
- **MongoDB**: GPS tracking data (movement logs)

### 6. **Config Layer** (config/)
- Database configurations
- CORS settings
- Environment variables

### 7. **Utils Layer** (utils/)
- Reusable helper functions
- Custom error classes
- Response formatters

## 🔄 Data Flow Example: Creating a Ride

```
1. Frontend sends POST request to /api/rides
                    ↓
2. Express middleware parses JSON body
                    ↓
3. CORS middleware validates origin
                    ↓
4. Route matches: POST /api/rides
                    ↓
5. validateRideCreation() checks required fields
                    ↓
6. asyncHandler() wraps the controller function
                    ↓
7. rideController.createRide() executes:
   - Generate QR code & OTP
   - Start PostgreSQL transaction
   - Insert ride
   - Add initiator as participant
   - Create notification
   - Commit transaction
                    ↓
8. Controller returns success response
                    ↓
9. Response sent to frontend
```

## 🛡️ Error Handling Flow

```
Error occurs in controller
        ↓
asyncHandler catches it
        ↓
Passes to errorHandler middleware
        ↓
errorHandler formats error
        ↓
Returns JSON error response to client
```

## 📦 File Organization

```
backend/
│
├── server.js                  # Entry point
│
├── config/                    # Configuration
│   ├── database.js           # DB connections
│   └── cors.js               # CORS settings
│
├── routes/                    # API routes
│   ├── index.js              # Main router
│   └── [resource]Routes.js   # Individual routes
│
├── controllers/               # Business logic
│   └── [resource]Controller.js
│
├── middleware/                # Custom middleware
│   ├── errorHandler.js
│   ├── validators.js
│   └── asyncHandler.js
│
├── models/                    # Database models
│   └── Movement.js
│
├── db/                        # Database setup
│   ├── db.js
│   ├── mongoose.js
│   └── initpsql.js
│
└── utils/                     # Utilities
    ├── errors.js
    └── responseFormatter.js
```

## 🎯 Design Principles

1. **Separation of Concerns**: Each layer has a specific responsibility
2. **Single Responsibility**: Each file/function does one thing well
3. **DRY (Don't Repeat Yourself)**: Reusable middleware and utilities
4. **Modularity**: Easy to add/remove features
5. **Scalability**: Structure supports growth
6. **Testability**: Isolated components are easy to test
7. **Maintainability**: Clear organization makes debugging easier

## 🔐 Security Layers

```
Request
  ↓
CORS Validation
  ↓
Input Validation (validators.js)
  ↓
Business Logic (controllers)
  ↓
Database Queries (parameterized)
  ↓
Response
```

---

This architecture follows industry best practices for building scalable, maintainable RESTful APIs.
