const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

router.post('/callback', paymentController.paymentCallback);

router.post('/initiate', protect, paymentController.initiatePayment);
router.get('/status/:orderId', protect, paymentController.getPaymentStatus);
router.get('/user/:userId', protect, paymentController.getUserPayments);
router.post('/verify', protect, paymentController.verifyPayment);

module.exports = router;