# AamarPay Payment Integration - Testing Guide

## Overview
This document describes the complete AamarPay payment integration for the Dromos Flutter app.

---

## Architecture

### Backend (Node.js/Express)
- **Endpoint:** `POST /api/v1/payment/initiate` - Creates payment order, returns payment URL
- **Endpoint:** `GET /api/v1/payment/status/:orderId` - Check payment status
- **Endpoint:** `GET /api/v1/payment/user/:userId` - Get payment history
- **Endpoint:** `POST /api/v1/payment/verify` - Manually verify payment
- **Callback:** `POST /api/v1/payment/callback` - AamarPay webhook (handles redirects)

### Frontend (Flutter)
- **PaymentScreen** - Enter amount & phone, initiate payment
- **PaymentWebviewScreen** - In-app browser for AamarPay
- **PaymentSuccessScreen** - Payment succeeded
- **PaymentFailedScreen** - Payment failed
- **PaymentCancelScreen** - Payment cancelled by user
- **PaymentHistoryScreen** - View all user payments

---

## Prerequisites

### 1. Backend Configuration

Update your backend `.env` file with AamarPay sandbox credentials:

```env
# AamarPay Configuration (Sandbox)
AAMARPAY_STORE_ID=aamarpaytest
AAMARPAY_SIGNATURE_KEY=dbb74894e82415a2f7ff0ec3a97e4183
AAMARPAY_MODE=sandbox

# Important: Set this to your actual Flutter app URL pattern
# This is used for redirect after payment.
# For testing, you can use any domain pattern (e.g., https://dromos.test)
# because we intercept the URL in the WebView before it loads.
FRONTEND_URL=https://dromos.test

# Other required vars
PORT=3000
DATABASE_URL=postgresql://...
MONGO_URI=mongodb://...
JWT_SECRET_KEY=your-secret-key
```

**Note:** `FRONTEND_URL` can be any HTTPS URL. The app intercepts `/payment/success`, `/payment/cancel`, and `/payment/failed` paths regardless of domain.

### 2. Flutter Dependencies

Already added to `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.2.0
  flutter_inappwebview: ^6.0.0
```

Run:
```bash
cd /home/anando/Documents/SPl_2/dromos
flutter pub get
```

### 3. API URL Configuration

Update `lib/utils/api.dart` to point to your deployed backend:

```dart
class Api {
  // Change to your deployed backend URL
  static String URL = 'https://your-backend.railway.app/api/v1';
  // Or for local testing:
  // static String URL = 'http://10.0.2.2:3000/api/v1'; // Android emulator
}
```

---

## Testing Steps

### Step 1: Start Backend

```bash
cd /home/anando/Documents/SPl_2/backend
npm install
npm start
```

Backend should run on `http://localhost:3000` (or your deployed URL).

### Step 2: Run Flutter App

```bash
cd /home/anando/Documents/SPl_2/dromos
flutter run
```

### Step 3: Login

Use existing test credentials or register a new user via signup page.

### Step 4: Navigate to Payment

1. Open Account page (bottom navigation: Account tab)
2. Tap **"Make a Payment"** button
   - Or from code: `Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen()));`

### Step 5: Fill Payment Form

| Field | Description | Example |
|-------|-------------|---------|
| Amount | Payment amount in BDT | `150.50` |
| Phone Number | Customer phone (required by AamarPay) | `+8801712345678` |
| Full Name | (Optional) | `John Doe` |
| Email | (Optional) | `john@example.com` |

Note: Phone number is required by AamarPay.

### Step 6: Initiate Payment

Tap **"Pay Securely via AamarPay"**

Expected:
- Backend returns `{ paymentUrl, orderId }`
- WebView opens loading AamarPay sandbox

### Step 7: Complete Payment in WebView

The AamarPay sandbox page will appear with payment options:

#### Test Card Numbers (AamarPay Sandbox)
Use these test card numbers (no real money charged):

| Card Number | CVV | Expiry | PIN |
|-------------|-----|--------|-----|
| `4111111111111111` | `123` | Any future date | `12345` (for test accounts) |

**Steps in sandbox:**
1. Enter card number
2. Expiry date (any future, e.g., `12/25`)
3. CVV (`123`)
4. Click "Pay Now"
5. If prompted for OTP, use test OTP: `123456` (sandbox may auto-approve)

### Step 8: Handle Redirect

After payment:
- **Success:** WebView redirects to `/payment/success` → Shows success screen with order details
- **Failed:** Shows failed screen with order ID
- **Cancelled:** Shows cancelled screen

### Step 9: Verify in Payment History

Go back to Account → "Payment History"

Expected:
- New payment entry appears with status `COMPLETED`
- Shows: Amount, Order ID, Transaction ID, Date, Phone

### Step 10: Verify Backend Database

Check MongoDB collection `payments`:

```bash
# In backend, you can log:
db.payments.find({ orderId: "DRM-..." }).pretty()
```

Should show:
```json
{
  "_id": "...",
  "orderId": "DRM-...",
  "userId": "...",
  "amount": 150.50,
  "status": "completed",
  "transactionId": "...",
  "paymentStatus": "Success",
  "customerPhone": "+8801712345678",
  "createdAt": ISODate(...),
  "updatedAt": ISODate(...)
}
```

---

## Common Issues & Fixes

### Issue: "Could not launch payment URL"
**Fix:** Ensure `url_launcher` is properly installed. Android: Check `AndroidManifest.xml` has INTERNET permission. iOS: Add `LSApplicationQueriesSchemes` in Info.plist.

### Issue: WebView crashes or shows blank page
**Fix:** 
- Check `flutter_inappwebview` is correctly added.
- Ensure `android:hardwareAccelerated="true"` in AndroidManifest (already set).
- Test with a simple URL first.

### Issue: Payment success screen not showing
**Fix:** 
- Verify backend `FRONTEND_URL` is set correctly.
- Check WebView's `shouldOverrideUrlLoading` intercepts the redirect URLs.
- Ensure redirect URLs contain `/payment/success`, `/payment/cancel`, or `/payment/failed`.

### Issue: Payment status stuck in "pending"
**Fix:**
- Backend processes callback from AamarPay. Ensure callback URL is publicly accessible.
- Check backend logs for callback errors.
- Manually verify: call `GET /api/v1/payment/status/:orderId` to refresh status.

### Issue: 403 Forbidden on payment initiation
**Fix:**
- Ensure user is logged in (JWT token present).
- Check `protect` middleware is working.
- Verify token in SharedPreferences.

### Issue: CORS error
**Fix:**
- Backend `config/cors.js` should allow your frontend origin.
- For mobile apps, CORS is less strict, but ensure backend allows your dev server IP.

---

## Additional Testing Scenarios

### 1. Low Connectivity
- Turn off WiFi/mobile data during payment initiation
- Expect: "Network error" message

### 2. Invalid Amount
- Enter `0` or negative amount
- Expect: Validation error

### 3. Missing Phone
- Leave phone empty
- Expect: "Phone number required" validation

### 4. Payment Cancellation
- In AamarPay page, click "Cancel" or close window
- Expect: Redirect to cancelled screen

### 5. Payment History Pagination
- Create >10 payments
- Scroll through history
- Pull to refresh

---

## Integration Example in Ride Flow

```dart
// Inside your ride completion logic:
import 'package:dromos/utils/payment_integration_example.dart';

void _handleRideComplete(Ride ride) async {
  final userService = UserService();

  // Check if user can pay
  if (!PaymentIntegrationExample.canUserPay(userService)) {
    // Show login prompt
    return;
  }

  // Calculate fare based on ride distance/time
  final fare = ride.calculateFare(); // implement this

  // Initiate payment
  if (mounted) {
    PaymentIntegrationExample.initiateRidePayment(
      context,
      amount: fare,
      rideId: ride.rideId,
      description: 'Ride from ${ride.startLocation} to ${ride.destination}',
    );
  }
}
```

---

## Debugging Tips

### Backend Logs
```bash
# Watch logs for payment flow
cd /home/anando/Documents/SPl_2/backend
npm start
# Look for:
# - AamarPay Callback: ...
# - Payment found for order: ...
# - MongoDB Connected
```

### Flutter Debug
```dart
// Enable debug prints in PaymentWebviewScreen
debugPrint('Redirect URL: $url');
```

### Inspect Network Calls
Use `http` logging interceptor or Charles Proxy to inspect:
- `POST /api/v1/payment/initiate`
- `GET /api/v1/payment/status/:orderId`

---

## Deploy Checklist

Before going live (production):

1. **Backend:**
   - Set `AAMARPAY_MODE=live`
   - Update `AAMARPAY_STORE_ID` and `AAMARPAY_SIGNATURE_KEY` to live credentials
   - Set `FRONTEND_URL` to your production domain (if using hosted web redirect)
   - Whitelist callback URL in AamarPay merchant dashboard

2. **Flutter:**
   - Update `Api.URL` to production backend URL
   - Test on real device (not just emulator)
   - Build release APK/AAB

3. **Security:**
   - Use strong `JWT_SECRET_KEY`
   - Enable HTTPS on backend
   - Use environment variables/secrets management

4. **AamarPay:**
   - Ensure your business is verified with AamarPay
   - Set proper callback URLs in AamarPay settings
   - Test in sandbox thoroughly before going live

---

## Support

- Backend issues: Check `/api/info` route for API documentation
- Flutter errors: Run `flutter analyze` and check logs
- AamarPay docs: https://docs.aamarpay.com/

---
**Last Updated:** 2026-04-25
