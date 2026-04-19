const asyncHandler = require('../middleware/asyncHandler');
const aamarpay = require('../utils/aamarpay');
const Payment = require('../models/Payment');
const { v4: uuidv4 } = require('uuid');

exports.initiatePayment = asyncHandler(async (req, res) => {
  const { amount, rideId, customerName, customerEmail, customerPhone, description } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({
      success: false,
      error: 'Valid amount is required'
    });
  }

  if (!customerPhone) {
    return res.status(400).json({
      success: false,
      error: 'Customer phone is required'
    });
  }

  const orderId = `DRM-${Date.now()}-${uuidv4().substring(0, 8)}`;
  const userId = req.user ? req.user.user_id : null;

  const paymentData = {
    amount: parseFloat(amount),
    orderId: orderId,
    customerName: customerName || req.user?.full_name || 'Dromos User',
    customerEmail: customerEmail || req.user?.email || 'user@dromos.com',
    customerPhone: customerPhone,
    customerAddress: req.user?.address || 'Bangladesh',
    description: description || 'Payment for Dromos ride',
    returnUrl: `${process.env.FRONTEND_URL}/payment/success`,
    cancelUrl: `${process.env.FRONTEND_URL}/payment/cancel`
  };

  const paymentResult = await aamarpay.initiatePayment(paymentData);

  if (!paymentResult.success) {
    return res.status(400).json({
      success: false,
      error: paymentResult.error,
      errorCode: paymentResult.errorCode
    });
  }

  const payment = new Payment({
    orderId: orderId,
    userId: userId,
    rideId: rideId,
    amount: parseFloat(amount),
    status: 'pending',
    customerName: paymentData.customerName,
    customerEmail: paymentData.customerEmail,
    customerPhone: paymentData.customerPhone,
    transactionId: paymentResult.transactionId
  });

  await payment.save();

  res.status(200).json({
    success: true,
    data: {
      orderId: orderId,
      paymentUrl: paymentResult.paymentUrl,
      amount: amount,
      currency: 'BDT'
    }
  });
});

exports.paymentCallback = asyncHandler(async (req, res) => {
  const callbackData = req.body;
  
  console.log('AamarPay Callback:', callbackData);

  const { order_id, amount, payment_status, pg_txnid, card_type, store_id } = callbackData;

  if (!order_id) {
    return res.status(400).json({
      success: false,
      error: 'Order ID not found'
    });
  }

  const payment = await Payment.findOne({ orderId: order_id });

  if (!payment) {
    console.error('Payment not found for order:', order_id);
    return res.status(404).json({
      success: false,
      error: 'Payment record not found'
    });
  }

  const isValidSignature = aamarpay.verifyCallback({
    store_id,
    order_id,
    amount,
    payment_status,
    signature_key: callbackData.signature_key
  });

  if (!isValidSignature && payment_status !== 'failed') {
    console.error('Invalid signature for order:', order_id);
  }

  let newStatus;
  switch (payment_status?.toLowerCase()) {
    case 'success':
      newStatus = 'completed';
      payment.paymentTime = new Date();
      break;
    case 'failed':
      newStatus = 'failed';
      break;
    case 'cancelled':
      newStatus = 'cancelled';
      break;
    case 'pending':
      newStatus = 'processing';
      break;
    default:
      newStatus = 'pending';
  }

  payment.status = newStatus;
  payment.paymentStatus = payment_status;
  payment.transactionId = pg_txnid || payment.transactionId;
  payment.paymentMethod = card_type || callbackData.card_brand;
  payment.aamarPayResponse = callbackData;

  await payment.save();

  if (payment_status === 'Success') {
    return res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <script>
            window.location.href = "${process.env.FRONTEND_URL}/payment/success?order_id=${order_id}&status=success";
          </script>
        </head>
        <body>
          <p>Redirecting to success page...</p>
        </body>
      </html>
    `);
  } else if (payment_status === 'failed') {
    return res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <script>
            window.location.href = "${process.env.FRONTEND_URL}/payment/failed?order_id=${order_id}&status=failed";
          </script>
        </head>
        <body>
          <p>Redirecting to failed page...</p>
        </body>
      </html>
    `);
  }

  res.status(200).json({ success: true });
});

exports.getPaymentStatus = asyncHandler(async (req, res) => {
  const { orderId } = req.params;

  const payment = await Payment.findOne({ orderId });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: 'Payment not found'
    });
  }

  if (payment.status === 'completed') {
    const verification = await aamarpay.verifyPayment(payment.transactionId);
    payment.aamarPayResponse = verification;
    await payment.save();
  }

  res.status(200).json({
    success: true,
    data: {
      orderId: payment.orderId,
      status: payment.status,
      amount: payment.amount,
      transactionId: payment.transactionId,
      paymentTime: payment.paymentTime,
      paymentMethod: payment.paymentMethod
    }
  });
});

exports.getUserPayments = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { page = 1, limit = 10 } = req.query;

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const payments = await Payment.find({ userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit))
    .populate('rideId', 'start_location destination status');

  const total = await Payment.countDocuments({ userId });

  res.status(200).json({
    success: true,
    count: payments.length,
    total,
    page: parseInt(page),
    pages: Math.ceil(total / parseInt(limit)),
    data: payments
  });
});

exports.verifyPayment = asyncHandler(async (req, res) => {
  const { orderId } = req.body;

  const payment = await Payment.findOne({ orderId });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: 'Payment not found'
    });
  }

  if (!payment.transactionId) {
    return res.status(400).json({
      success: false,
      error: 'No transaction ID found'
    });
  }

  const verification = await aamarpay.verifyPayment(payment.transactionId);

  if (verification && (verification.status === 'Success' || verification.status === 'success')) {
    payment.status = 'completed';
    payment.paymentStatus = verification.status;
    payment.paymentTime = verification.date || new Date();
    payment.aamarPayResponse = verification;
    await payment.save();
  }

  res.status(200).json({
    success: true,
    data: payment
  });
});