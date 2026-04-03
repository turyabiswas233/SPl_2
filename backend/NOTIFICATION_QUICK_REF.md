# Notification System - Quick Reference

## One-Liner Usage

```javascript
// Import
const { postNotification, postNotifications } = require('../controllers/notificationController');

// Single notification
await postNotification(userId, "Your message here", rideId);

// Multiple notifications
await postNotifications([
  { userId: 'user1', messageText: 'Message 1', rideId: 'ride1' },
  { userId: 'user2', messageText: 'Message 2', rideId: 'ride1' },
]);

// Inside transaction
await postNotification(userId, "Message", rideId, tx);
```

## Parameters

| Function | Param | Type | Required | Notes |
|----------|-------|------|----------|-------|
| `postNotification()` | userId | string | ✅ | UUID of recipient |
| | messageText | string | ✅ | Notification message |
| | rideId | string | ❌ | Ride association (optional) |
| | txClient | object | ❌ | Pass transaction object if in DB transaction |
| `postNotifications()` | notificationsList | array | ✅ | Array of notification objects |
| | txClient | object | ❌ | Transaction client (optional) |

## Common Patterns

### Pattern 1: Single User Notification
```javascript
await postNotification(
  ride.initiatorId,
  `${user.fullName} has joined your ride!`,
  rideId
);
```

### Pattern 2: Notify All Participants
```javascript
const participants = await tx.rideParticipant.findMany({ where: { rideId } });
const list = participants.map(p => ({
  userId: p.userId,
  messageText: "Trip completed!",
  rideId,
}));
await postNotifications(list, tx);
```

### Pattern 3: Inside Transaction
```javascript
const result = await prisma.$transaction(async (tx) => {
  // Create ride
  const ride = await tx.ride.create({ data: {...} });
  
  // Notify initiator
  await postNotification(userId, "Ride created!", ride.rideId, tx);
  
  return ride;
});
```

### Pattern 4: Conditional Batch
```javascript
if (participants.length > 0) {
  const notifications = participants.map(p => ({
    userId: p.userId,
    messageText: `Trip ${action}!`,
    rideId,
  }));
  await postNotifications(notifications, tx);
}
```

## Socket.IO Client Setup

```javascript
// Connect to socket
const socket = io('http://localhost:3000');

// Listen for notifications
socket.on('notificationReceived', (notification) => {
  console.log('New notification:', notification);
  // notification.userId
  // notification.messageText
  // notification.rideId
  // notification.isRead
  // notification.createdAt
});
```

## Common Message Templates

```javascript
// Ride creation
"Your ride from {start} to {destination} has been created!"

// Ride participation
`${participantName} has joined your ride to ${destination}!`

// Trip progress
"Trip is now in progress. Please be ready!"

// Trip completion
"Trip completed! Your share: ${amount}. Please rate co-passengers."

// Cancellation
"Trip cancelled by the initiator."

// Request response
"Your request to join the ride has been ${action}!"

// SOS Alert
"🚨 SOS Alert: ${alertType} reported in your ride!"
```

## Error Handling

```javascript
try {
  await postNotification(userId, "Message", rideId, tx);
} catch (err) {
  console.error("Notification failed:", err.message);
  // Handle gracefully - don't fail the whole transaction
}
```

## DB Schema Fields
- `notificationId` - UUID (auto-generated)
- `userId` - User receiving notification
- `rideId` - Associated ride (optional)
- `messageText` - The message content
- `isRead` - Boolean (default: false)
- `createdAt` - Timestamp (auto-set)

## File Locations

| Component | File | Type |
|-----------|------|------|
| Notification Class | `controllers/notificationController.js` | Implementation |
| Imports | All controllers | Usage |
| Socket.IO Instance | `index.js` | Global |
| DB Table | `prisma/schema.prisma` | Schema definition |
| Guide | `NOTIFICATION_GUIDE.md` | Documentation |

## DO's ✅

- ✅ Use `postNotification()` for single notifications
- ✅ Use `postNotifications()` for batch operations
- ✅ Pass `tx` client inside transactions
- ✅ Include `rideId` when notification relates to a ride
- ✅ Wrap in try-catch for error handling
- ✅ Use descriptive message text

## DON'Ts ❌

- ❌ Don't create UUID for notifications (auto-generated)
- ❌ Don't use `tx.notification.create()` directly
- ❌ Don't forget to import `postNotification` or `postNotifications`
- ❌ Don't pass wrong transaction client
- ❌ Don't use with direct db calls - use functions only
- ❌ Don't make notifications async without await

## Debugging

```javascript
// Check if notification was created
const notif = await postNotification(userId, "Test", null);
console.log(notif.notificationId); // Should print UUID

// Check Socket.IO connection
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  socket.join(userId); // User-specific room
});

// Check database
await prisma.notification.findMany({ where: { userId } });
```

---

**More details?** See `NOTIFICATION_GUIDE.md`
