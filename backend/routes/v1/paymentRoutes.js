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

router.get("/estimate", protect, estimateCost);
router.post("/callback", paymentCallback);

router.post("/initiate", protect, initiatePayment);
router.get("/status/:orderId", protect, getPaymentStatus);
router.get("/user/:userId", protect, getUserPayments);
router.post("/verify", protect, verifyPayment);

module.exports = router;
