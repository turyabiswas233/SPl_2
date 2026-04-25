# 🚀 Dromos AamarPay Integration - Quick Start

## ✅ What Was Created

### Flutter Frontend (10 new files)
```
lib/
├── models/
│   └── payment_model.dart          # Payment data model
├── services/
│   └── payment_service.dart        # Payment API service (EXTENDED)
├── screens/
│   └── payment/
│       ├── payment_screen.dart              # Payment form
│       ├── payment_webview_screen.dart      # AamarPay WebView
│       ├── payment_success_screen.dart      # Success page
│       ├── payment_failed_screen.dart       # Failed page
│       ├── payment_cancel_screen.dart       # Cancelled page
│       └── payment_history_screen.dart      # Transaction history
├── utils/
│   ├── payment_utils.dart         # Constants & helpers (EXTENDED)
│   └── payment_integration_example.dart     # Usage examples
└── docs/
    ├── PAYMENT_INTEGRATION.md     # Full documentation
    └── PAYMENT_TEST_CHECKLIST.md  # Testing guide
```

### Updated Files
- `pubspec.yaml` - Added `url_launcher` & `flutter_inappwebview`
- `main.dart` - Added payment routes
- `account_page.dart` - Added "Make a Payment" & "Payment History" buttons
- `payment_service.dart` - Extended with AamarPay methods

---

## 🧪 How to Test Now

### 1. **Backend Setup** (5 min)

```bash
cd /home/anando/Documents/SPl_2/backend

# If not already running:
npm install
npm start
```

Backend should be at `http://localhost:3000`

**Important:** Ensure `.env` has AamarPay sandbox credentials (default from `.env.example`):

```env
AAMARPAY_STORE_ID=aamarpaytest
AAMARPAY_SIGNATURE_KEY=dbb74894e82415a2f7ff0ec3a97e4183
AAMARPAY_MODE=sandbox
FRONTEND_URL=https://dromos.test  # Any HTTPS URL
```

### 2. **Flutter Setup** (1 min)

```bash
cd /home/anando/Documents/SPl_2/dromos
flutter pub get
flutter run
```

### 3. **Test Flow**

```
1. Login to app (or signup)
2. Go to Account tab (bottom right)
3. Tap "Make a Payment"
4. Enter:
   - Amount: 10.00
   - Phone: +8801712345678
   - Name/Email: optional
5. Tap "Pay Securely via AamarPay"
6. WebView opens → AamarPay sandbox page loads
7. Use test card:
   - Card: 4111 1111 1111 1111
   - CVV: 123
   - Expiry: Any future date (e.g., 12/25)
   - OTP (if asked): 123456
8. Submit → Should redirect to Success screen
9. Go back → Account → Payment History → See your payment!
```

---

## 🎯 Key Features Implemented

✅ **Payment Initiation** - Create order, get AamarPay URL
✅ **In-App WebView** - Secure payment inside app (no browser switch)
✅ **Redirect Handling** - Auto-detect success/cancel/failure URLs
✅ **Payment History** - List all user transactions with pagination
✅ **Status Colors** - Green=Completed, Orange=Pending, Red=Failed
✅ **Offline Handling** - Network error messages
✅ **Form Validation** - Amount, phone, email
✅ **User Pre-fill** - Auto-fills name/email from profile

---

## 📱 Integration Example

Add a payment button anywhere:

```dart
import 'package:dromos/screens/payment/payment_screen.dart';
import 'package:dromos/utils/payment_integration_example.dart';

// Simple way:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          amount: 150.0,           // Fare calculated
          rideId: ride.rideId,     // Optional ride link
          description: 'Trip from Dhanmondi to Gulshan',
        ),
      ),
    );
  },
  child: Text('Pay Now'),
)

// OR using helper:
PaymentIntegrationExample.initiateRidePayment(
  context,
  amount: fare,
  rideId: rideId,
);
```

---

## 🔧 Backend Configuration

Your backend already has all routes:

```
POST   /api/v1/payment/initiate      (protected)
GET    /api/v1/payment/status/:id    (protected)
GET    /api/v1/payment/user/:userId  (protected)
POST   /api/v1/payment/verify        (protected)
POST   /api/v1/payment/callback      (AamarPay webhook)
```

### Environment Variables Required:

| Variable | Description | Example |
|----------|-------------|---------|
| `AAMARPAY_STORE_ID` | AamarPay merchant ID | `aamarpaytest` |
| `AAMARPAY_SIGNATURE_KEY` | Hash key from AamarPay | `dbb74894...` |
| `AAMARPAY_MODE` | `sandbox` or `live` | `sandbox` |
| `FRONTEND_URL` | Frontend redirect base | `https://yourapp.com` |

Get live credentials from AamarPay merchant dashboard.

---

## 🐛 Debugging

### Payment not initiating?
- Check token exists: `UserService().isLoggedIn`
- Backend reachable? `curl http://localhost:3000/api/info`
- Check `Api.URL` in Flutter matches backend

### WebView blank?
- Internet permission: Already in AndroidManifest.xml ✅
- Check `flutter_inappwebview` installed
- Test URL: `flutter run -d chrome` to debug

### Success screen not appearing?
- Verify URL contains `/payment/success`
- Check WebView interceptor code in `payment_webview_screen.dart:58`
- Add `debugPrint('Redirect: $url');` to see URL changes

### History empty?
- Ensure user has payments in DB
- Call `PaymentService.getPaymentHistory(userId)`
- Check MongoDB: `db.payments.find({})`

---

## 📊 Database Schema

MongoDB `Payment` model (already in backend):

```javascript
{
  orderId: String,      // Unique: DRM-timestamp-random
  userId: ObjectId,     // Who paid
  rideId: ObjectId,     // Which ride (optional)
  amount: Number,
  currency: String,     // BDT
  status: String,       // pending|processing|completed|failed|cancelled
  transactionId: String, // AamarPay txn ID
  paymentMethod: String, // card|qr|etc
  customerPhone: String,
  paymentTime: Date,
  aamarPayResponse: Object, // Full AamarPay response
  createdAt: Date
}
```

---

## 🚀 Going Live

When ready for production:

1. Get AamarPay live credentials (business verification required)
2. Update backend `.env`:
   ```env
   AAMARPAY_MODE=live
   AAMARPAY_STORE_ID=your_live_store_id
   AAMARPAY_SIGNATURE_KEY=your_live_key
   ```
3. Deploy backend to Railway/Render/ Fly.io
4. Update `Api.URL` in Flutter to production URL
5. Set `FRONTEND_URL` to your app's deep link scheme or web domain
6. Build release APK/AAB
7. Upload to Google Play

---

## 📚 Payment Status Lifecycle

```
pending → processing → completed
                ↓
              failed / cancelled
```

Backend updates:
- `pending` → when order created
- `processing` → when AamarPay returns pending
- `completed` → on success callback
- `failed` → on failure/cancel

---

## ❓ FAQ

**Q: Is AamarPay the only gateway?**
A: Currently yes. Backend is modular - you could add bKash, Nagad by creating new utils.

**Q: Can I test without real money?**
A: Yes! Sandbox mode uses test cards. No real charges.

**Q: Does it work on iOS?**
A: Yes, both Android & iOS. Uses WebView.

**Q: What if user closes WebView mid-payment?**
A: Order stays `pending`. You can check status later or cancel manually.

**Q: Can I get refunds?**
A: AamarPay supports refunds via their dashboard/API. Not implemented here.

**Q: Are there transaction limits?**
A: AamarPay may have limits. Check their docs.

---

## 📞 Support

- Backend API docs: Visit `http://localhost:3000/api/info` when backend running
- AamarPay docs: https://docs.aamarpay.com/
- Flutter errors: `flutter analyze`, `flutter run -v`

---

**Status:** ✅ Ready for testing
**Last Updated:** 2026-04-25
