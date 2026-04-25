# Payment Integration Test Checklist

## Backend API Test (Using curl/Postman)

### 1. Test Payment Initiation (Protected)

```bash
# First, login to get token
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' | jq -r '.data.token')

# Initiate payment
curl -X POST http://localhost:3000/api/v1/payment/initiate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "amount": 100.50,
    "customerPhone": "+8801712345678",
    "customerName": "Test User",
    "customerEmail": "test@example.com",
    "description": "Test payment",
    "rideId": null
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "paymentUrl": "https://sandbox.aamarpay.com/paynow.php?...",
    "orderId": "DRM-12345678-ABCDEF",
    "amount": 100.50,
    "currency": "BDT"
  }
}
```

### 2. Test Get Payment Status (Public - no auth needed for testing?)

```bash
curl http://localhost:3000/api/v1/payment/status/DRM-12345678-ABCDEF
```

Expected:
```json
{
  "success": true,
  "data": {
    "orderId": "...",
    "status": "pending", // or "completed" after payment
    "amount": 100.50,
    ...
  }
}
```

### 3. Test Get Payment History (Protected)

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/payment/user/USER_ID?page=1&limit=10"
```

---

## Flutter App Test Plan

### Manual Test Cases

| # | Test | Steps | Expected |
|---|------|-------|----------|
| 1 | Open Payment Screen | Login → Account → "Make a Payment" | Payment form appears |
| 2 | Validation - Empty amount | Leave amount blank, submit | "Please enter amount" error |
| 3 | Validation - Invalid amount | Enter "abc", submit | "Enter valid amount" error |
| 4 | Validation - Missing phone | Leave phone blank, submit | "Phone number required" |
| 5 | Initiate payment | Enter valid data, submit | WebView opens with AamarPay |
| 6 | Successful payment | Complete with test card | Redirect to success screen |
| 7 | Failed payment | Use declined card (e.g., 4000000000000002) | Failed screen |
| 8 | Cancel payment | Click cancel/back in WebView | Cancelled screen |
| 9 | Payment history | After success, view history | Entry appears with correct details |
| 10 | Offline mode | Disable internet, submit | "Network error" message |

### Test Card Numbers (AamarPay Sandbox)

Use these test cards on AamarPay sandbox:

| Card Number | Expected Result |
|-------------|-----------------|
| 4111111111111111 | Success |
| 4000000000000002 | Declined/Failed |
| 4000000000009995 | Insufficient funds |

---

## Automated Test Suggestions (Optional)

Write widget tests for:

```dart
testWidgets('Payment form validation', (tester) async {
  // Test empty fields
  // Test invalid email
  // Test invalid amount
});

testWidgets('Payment history loads', (tester) async {
  // Mock PaymentService
  // Verify list renders
});
```

---

## Quick Verification Checklist

- [ ] Backend running on port 3000 (or deployed)
- [ ] AamarPay sandbox credentials set in backend .env
- [ ] Flutter app updated with new dependencies (`flutter pub get`)
- [ ] Android device/emulator connected
- [ ] User logged in (token exists)
- [ ] PaymentScreen navigable from Account page
- [ ] WebView loads AamarPay page
- [ ] Success redirect shows order details
- [ ] Payment history displays entry
- [ ] Backend database shows new payment record

---

## What Gets Stored

Each payment record in MongoDB includes:

```javascript
{
  orderId: "DRM-...",
  userId: ObjectId(...),
  rideId: ObjectId(...), // nullable
  amount: 100.50,
  currency: "BDT",
  status: "completed", // pending|processing|completed|failed|cancelled
  transactionId: "AamarPay Txn ID",
  paymentMethod: "card",
  customerName: "...",
  customerEmail: "...",
  customerPhone: "...",
  paymentStatus: "Success", // as returned by AamarPay
  paymentTime: ISODate(...),
  aamarPayResponse: { ...full callback... },
  createdAt: ISODate(...),
  updatedAt: ISODate(...)
}
```

---

## Next Steps

After manual testing passes:

1. Test with real amount (BDT 1.00) in sandbox
2. Check email notifications (if configured in AamarPay)
3. Verify payment verification endpoint works
4. Test edge cases: app closed during payment, network drop
5. Deploy backend to Railway/Render
6. Update `Api.URL` in Flutter to production URL
7. Build release APK and test on device
8. Submit to Google Play

--- 

**Note:** AamarPay sandbox may occasionally be slow. If WebView hangs, retry or check network.
