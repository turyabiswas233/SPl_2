# Notification System Guide

## Overview
The notification system has been refactored to use an **OOP Class-based approach** with **centralized notification creation and Socket.IO integration**. This eliminates code duplication and provides a single source of truth for all notifications.

## Architecture

### Key Components

#### 1. **Notification Class**
A reusable OOP class that encapsulates notification logic:

```javascript
class Notification {
  constructor(userId, messageText, rideId = null) { ... }
  async save(txClient = prisma) { ... }
  emit(ioInstance) { ... }
}
```

#### 2. **Core Functions**

##### `postNotification()` - Single Notification
Creates and sends a single notification to a user.

**Signature:**
```javascript
postNotification(
  userId: string,           // User receiving the notification
  messageText: string,      // Notification message
  rideId?: string,          // Associated ride ID (optional)
  txClient?: object         // Prisma transaction client (optional)
): Promise<object>          // Returns created notification object
```

**Usage Examples:**

```javascript
// Basic usage (no transaction)
await postNotification(userId, "Your ride is ready!");

// With ride ID
await postNotification(userId, "Ride confirmed", rideId);

// Inside a Prisma transaction
await prisma.$transaction(async (tx) => {
  // ... other DB operations
  await postNotification(userId, "Message", rideId, tx);
  // ... more operations
});
```

##### `postNotifications()` - Batch Notifications
Creates and sends multiple notifications efficiently.

**Signature:**
```javascript
postNotifications(
  notificationsList: Array<{userId, messageText, rideId}>  // Array of notification objects
  txClient?: object                                          // Prisma transaction client (optional)
): Promise<Array<object>>                                    // Returns array of created notifications
```

**Usage Examples:**

```javascript
// Batch notification to multiple users
const participants = await tx.rideParticipant.findMany({ where: { rideId } });

const notificationsList = participants.map(p => ({
  userId: p.userId,
  messageText: "Trip completed! Please rate co-passengers.",
  rideId: rideId,
}));

await postNotifications(notificationsList, tx);
```

## Controller Integration

### How Controllers Use the System

Controllers now follow a standard pattern for notifications:

**Before (Old Pattern):**
```javascript
// Multiple UUID generations
const notificationId = uuidv4();

// Direct DB creation with duplicated code
await tx.notification.create({
  data: {
    notificationId,
    userId,
    rideId,
    messageText: "Your message",
  },
});
```

**After (New Pattern):**
```javascript
// Single function call
await postNotification(userId, "Your message", rideId, tx);
```

## Updated Controllers

### 1. **rideController.js**
- `createRide()` → Single notification to initiator
- `completeRide()` → Batch notifications to all participants with fare info
- `startRide()` → Batch notifications about trip progress
- `cancelRide()` → Batch notifications about cancellation

### 2. **handshakeController.js**
- `joinByQr()` → 3 notifications:
  - User joining the ride
  - Ride initiator receiving new participant
  - Other requesters about rejection

### 3. **requestController.js**
- `createRideRequest()` → Notification to ride initiator
- `updateRideRequest()` → Notifications for accept/reject

### 4. **sosController.js**
- `createSOSAlert()` → Batch notifications to all ride participants

## Socket.IO Integration

### Real-Time Notifications

The system uses **Socket.IO** to send real-time notifications to connected clients.

**Emission Details:**
- **Event Name:** `notificationReceived`
- **Target:** User-specific room (socket.to(userId))
- **Async Behavior:** Uses `setImmediate()` to emit after transaction commits

**Payload Structure:**
```javascript
{
  notificationId: string,
  userId: string,
  messageText: string,
  rideId?: string,
  isRead: boolean,
  createdAt: Date,
}
```

**Client-Side Listening (Example):**
```javascript
socket.on('notificationReceived', (notification) => {
  console.log('New notification:', notification.messageText);
  // Update UI with notification
});
```

### Socket.IO Setup

The Socket.IO instance is initialized in `index.js` and exported for use across controllers:

```javascript
const { io } = require('../index');
```

## Transaction Safety

The system is fully compatible with Prisma transactions:

```javascript
const result = await prisma.$transaction(async (tx) => {
  // All operations are atomic
  await tx.ride.create({ ... });
  await tx.rideParticipant.create({ ... });
  
  // Pass transaction client to notifications
  await postNotification(userId, "Message", rideId, tx);
  
  return result;
});

// Socket.IO emission happens after transaction commits
```

## API Endpoints

### Get Notifications
- **Route:** `GET /api/v1/notifications/`
- **Auth:** Required
- **Returns:** Array of user's notifications with count

### Mark as Read
- **Route:** `PUT /api/v1/notifications/:notification_id/read`
- **Auth:** Required
- **Returns:** Updated notification object

## Database Schema

```prisma
model Notification {
  notificationId       String @id @db.Uuid
  userId               String @db.Uuid
  rideId               String? @db.Uuid
  messageText          String
  isRead               Boolean @default(false)
  createdAt            DateTime @default(now()) @db.Timestamptz()

  user                 User @relation(...)
  ride                 Ride? @relation(...)

  @@map("notifications")
}
```

## Best Practices

### 1. **Always Pass Ride ID**
When applicable, include the `rideId` to maintain data relationships:
```javascript
await postNotification(userId, "Payment received", rideId);
```

### 2. **Use Batch for Multiple Users**
For multiple users, use `postNotifications()` instead of looping:
```javascript
// ✅ Good
await postNotifications(notificationsList, tx);

// ❌ Avoid
for (const user of users) {
  await postNotification(user.userId, msg, rideId, tx);
}
```

### 3. **Handle Transaction Properly**
Always pass transaction client when inside a transaction:
```javascript
await prisma.$transaction(async (tx) => {
  // Pass tx to ensure atomicity
  await postNotification(userId, msg, rideId, tx);
});
```

### 4. **Error Handling**
Wrap notification calls with proper error handling:
```javascript
try {
  await postNotification(userId, "Message", rideId, tx);
} catch (err) {
  console.error("Notification creation failed:", err);
  // Handle error appropriately
}
```

## Troubleshooting

### Notifications Not Appearing
1. Check if Socket.IO is properly initialized in `index.js`
2. Verify userId is valid
3. Check browser console for WebSocket errors
4. Ensure client is listening to `notificationReceived` event

### Duplicate UUID Errors
- The system handles UUID generation internally
- Do not manually generate UUIDs for notifications

### Transaction Failures
- Ensure transaction client is passed correctly
- Check Prisma error logs for database issues

## Future Enhancements

Potential improvements to the system:
1. Notification categories/types
2. Notification templates
3. Email notifications integration
4. Notification preferences per user
5. Scheduled notifications
6. Notification history cleanup

## Questions?

Refer to the Notification Class source code in `controllers/notificationController.js` for implementation details.
