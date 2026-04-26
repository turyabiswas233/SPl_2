const express = require("express");
const router = express.Router();
const {
  estimateCost,
  paymentCallback,
  initiatePayment,
  getPaymentStatus,
  getUserPayments,
  verifyPayment,
} = require("../../controllers/paymentController");
const { protect } = require("../../middleware/auth");

// Route for estimating cost
router.get("/estimate", protect, estimateCost);

// Route for initiating payment with Stripe
router.post("/initiate", protect, initiatePayment);

// Route for getting payment status
router.get("/status/:orderId", protect, getPaymentStatus);

// Route for getting user's payment history
router.get("/user/:userId", protect, getUserPayments);

// Route for verifying payment
router.post("/verify", protect, verifyPayment);

// Stripe webhook endpoint (no auth required - uses signature verification)
router.post("/webhook/stripe", express.raw({ type: "application/json" }), paymentCallback);

module.exports = router;
