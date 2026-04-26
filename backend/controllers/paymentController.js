const asyncHandler = require("../middleware/asyncHandler");
const aamarpay = require("../utils/aamarpay");
const prisma = require("../db/prismaClient");
const { v4: uuidv4 } = require("uuid");
const mapboxClient = require("@mapbox/mapbox-sdk");
const directions = require("@mapbox/mapbox-sdk/services/directions");

const mapboxToken = process.env.MAPBOX_ACCESS_TOKEN;
const mbxClient = mapboxClient({ accessToken: mapboxToken });
const mbxDirections = directions(mbxClient);

exports.estimateCost = asyncHandler(async (req, res) => {
  const { startLng, startLat, destLng, destLat } = req.query;

  if (!startLng || !startLat || !destLng || !destLat) {
    return res.status(400).json({
      success: false,
      error:
        "Missing required parameters: startLng, startLat, destLng, destLat",
    });
  }

  try {
    const response = await mbxDirections
      .getDirections({
        profile: "driving",
        waypoints: [
          { coordinates: [parseFloat(startLng), parseFloat(startLat)] },
          { coordinates: [parseFloat(destLng), parseFloat(destLat)] },
        ],
        geometries: "geojson",
        language: "en",
        overview: "full",
      })
      .send();

    if (
      response.statusCode === 200 &&
      response.body.routes &&
      response.body.routes.length > 0
    ) {
      const distanceKm = response.body.routes[0].distance / 1000; // Convert to km
      const durationMin = response.body.routes[0].duration / 60; // Convert to minutes

      // Cost calculation: Base fare 20 BDT + 8 BDT per km + 0.5 BDT per minute
      const baseFare = 20;
      const perKmRate = 8;
      const perMinRate = 0.5;
      const totalCost =
        baseFare + distanceKm * perKmRate + durationMin * perMinRate;
      const estimatedCost = Math.round(totalCost * 100) / 100; // Round to 2 decimal places
      const paymentAmount = estimatedCost / 2; // Half for sharing

      res.status(200).json({
        success: true,
        data: {
          distance: distanceKm,
          duration: durationMin,
          estimatedCost: estimatedCost,
          paymentAmount: paymentAmount,
          currency: "BDT",
        },
      });
    } else {
      res.status(400).json({
        success: false,
        error: "Could not calculate route",
      });
    }
  } catch (error) {
    console.error("Error estimating cost:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    });
  }
});

exports.initiatePayment = asyncHandler(async (req, res) => {
  const {
    amount,
    rideId,
    customerName,
    customerEmail,
    customerPhone,
    description,
  } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({
      success: false,
      error: "Valid amount is required",
    });
  }

  if (!customerPhone) {
    return res.status(400).json({
      success: false,
      error: "Customer phone is required",
    });
  }

  const orderId = `DRM-${Date.now()}-${uuidv4().substring(0, 8)}`;
  const userId = req.user ? req.user.user_id : null;

  try {
    const paymentData = {
      amount: parseFloat(amount),
      orderId: orderId,
      customerName: customerName || req.user?.full_name || "Dromos User",
      customerEmail: customerEmail || req.user?.email || "user@dromos.com",
      customerPhone: customerPhone,
      customerAddress: req.user?.address || "Bangladesh",
      description: description || "Payment for Dromos ride",
      returnUrl: `${process.env.FRONTEND_URL}/payment/success`,
      cancelUrl: `${process.env.FRONTEND_URL}/payment/cancel`,
    };

    const paymentResult = await aamarpay.initiatePayment(paymentData);

    if (!paymentResult.success) {
      return res.status(400).json({
        success: false,
        error: paymentResult.error,
        errorCode: paymentResult.errorCode,
      });
    }

    const payment = await prisma.payment.create({
      data: {
        orderId: orderId,
        userId: userId,
        rideId: rideId,
        amount: parseFloat(amount),
        status: "pending",
        customerName: paymentData.customerName,
        customerEmail: paymentData.customerEmail,
        customerPhone: paymentData.customerPhone,
        transactionId: paymentResult.transactionId,
      },
    });

    res.status(200).json({
      success: true,
      data: {
        orderId: orderId,
        paymentUrl: paymentResult.paymentUrl,
        amount: amount,
        currency: "BDT",
      },
    });
  } catch (error) {
    console.error("Error initiating payment:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    });
  }
});

exports.paymentCallback = asyncHandler(async (req, res) => {
  const callbackData = req.body;

  console.log("AamarPay Callback:", callbackData);

  const { order_id, amount, payment_status, pg_txnid, card_type, store_id } =
    callbackData;

  if (!order_id) {
    return res.status(400).json({
      success: false,
      error: "Order ID not found",
    });
  }

  const payment = await prisma.payment.findUnique({
    where: { orderId: order_id },
  });

  if (!payment) {
    console.error("Payment not found for order:", order_id);
    return res.status(404).json({
      success: false,
      error: "Payment record not found",
    });
  }

  const isValidSignature = aamarpay.verifyCallback({
    store_id,
    order_id,
    amount,
    payment_status,
    signature_key: callbackData.signature_key,
  });

  if (!isValidSignature && payment_status !== "failed") {
    console.error("Invalid signature for order:", order_id);
  }

  let newStatus;
  switch (payment_status?.toLowerCase()) {
    case "success":
      newStatus = "completed";
      payment.paymentTime = new Date();
      break;
    case "failed":
      newStatus = "failed";
      break;
    case "cancelled":
      newStatus = "cancelled";
      break;
    case "pending":
      newStatus = "processing";
      break;
    default:
      newStatus = "pending";
  }

  await prisma.payment.update({
    where: { orderId: order_id },
    data: {
      status: newStatus,
      paymentStatus: payment_status,
      transactionId: pg_txnid || payment.transactionId,
      paymentMethod: card_type || callbackData.card_brand,
      aamarPayResponse: callbackData,
      paymentTime: newStatus === "completed" ? new Date() : payment.paymentTime,
    },
  });

  if (payment_status === "Success") {
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
  } else if (payment_status === "failed") {
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

  const payment = await prisma.payment.findUnique({
    where: { orderId: orderId },
  });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: "Payment not found",
    });
  }

  if (payment.status === "completed") {
    const verification = await aamarpay.verifyPayment(payment.transactionId);
    await prisma.payment.update({
      where: { orderId: orderId },
      data: { aamarPayResponse: verification },
    });
  }

  res.status(200).json({
    success: true,
    data: {
      orderId: payment.orderId,
      status: payment.status,
      amount: payment.amount,
      transactionId: payment.transactionId,
      paymentTime: payment.paymentTime,
      paymentMethod: payment.paymentMethod,
    },
  });
});

exports.getUserPayments = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { page = 1, limit = 10 } = req.query;
  console.log(
    `Fetching payments for user ${userId} - Page: ${page}, Limit: ${limit}`,
  );

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const payments = await prisma.payment.findMany({
    where: { userId: userId },
    orderBy: { createdAt: "desc" },
    skip: skip,
    take: parseInt(limit),
    include: {
      ride: {
        select: {
          startLocation: true,
          destinationName: true,
          status: true,
        },
      },
    },
  });

  const total = await prisma.payment.count({
    where: { userId: userId },
  });

  res.status(200).json({
    success: true,
    count: payments.length,
    total,
    page: parseInt(page),
    pages: Math.ceil(total / parseInt(limit)),
    data: payments,
  });
});

exports.verifyPayment = asyncHandler(async (req, res) => {
  const { orderId } = req.body;

  const payment = await prisma.payment.findUnique({
    where: { orderId: orderId },
  });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: "Payment not found",
    });
  }

  if (!payment.transactionId) {
    return res.status(400).json({
      success: false,
      error: "No transaction ID found",
    });
  }

  const verification = await aamarpay.verifyPayment(payment.transactionId);

  if (
    verification &&
    (verification.status === "Success" || verification.status === "success")
  ) {
    await prisma.payment.update({
      where: { orderId: orderId },
      data: {
        status: "completed",
        paymentStatus: verification.status,
        paymentTime: verification.date
          ? new Date(verification.date)
          : new Date(),
        aamarPayResponse: verification,
      },
    });
  }

  res.status(200).json({
    success: true,
    data: payment,
  });
});
