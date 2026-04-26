const asyncHandler = require("../middleware/asyncHandler");
const stripe = require("../utils/stripe");
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

  const orderId = `DRM-${Date.now()}-${uuidv4().substring(0, 8)}`;
  const userId = req.user ? req.user.userId : null;

  try {
    const paymentData = {
      amount: parseFloat(amount),
      currency: "usd",
      orderId: orderId,
      description: description || "Payment for Dromos ride",
      metadata: {
        userId: userId,
        rideId: rideId,
        customerName: customerName || req.user?.full_name || "Dromos User",
        customerEmail: customerEmail || req.user?.email || "user@dromos.com",
        customerPhone: customerPhone,
      },
    };

    // Create payment intent with Stripe
    const paymentResult = await stripe.createPaymentIntent(paymentData);

    if (!paymentResult.success) {
      return res.status(400).json({
        success: false,
        error: paymentResult.error,
        code: paymentResult.code,
      });
    }

    // Store payment in database
    const payment = await prisma.payment.create({
      data: {
        orderId: orderId,
        userId: userId,
        rideId: rideId,
        amount: parseFloat(amount),
        status: "pending",
        customerName: paymentData.metadata.customerName,
        customerEmail: paymentData.metadata.customerEmail,
        customerPhone: paymentData.metadata.customerPhone,
        transactionId: paymentResult.paymentIntentId,
      },
    });

    res.status(200).json({
      success: true,
      data: {
        orderId: orderId,
        clientSecret: paymentResult.clientSecret,
        publishableKey: paymentResult.publishableKey,
        paymentIntentId: paymentResult.paymentIntentId,
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
  const signature = req.headers["stripe-signature"];
  const body = req.body;

  if (!signature) {
    return res.status(400).json({
      success: false,
      error: "Missing Stripe signature",
    });
  }

  const verification = stripe.verifyWebhookSignature(body, signature);

  if (!verification.valid) {
    console.error("Invalid webhook signature:", verification.error);
    return res.status(400).json({
      success: false,
      error: "Invalid signature",
    });
  }

  const event = verification.event;
  console.log("Stripe Webhook Event:", event.type);

  try {
    switch (event.type) {
      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object;
        const orderId = paymentIntent.metadata?.orderId;

        if (orderId) {
          await prisma.payment.updateMany({
            where: { orderId: orderId },
            data: {
              status: "completed",
              transactionId: paymentIntent.id,
              paymentMethod: paymentIntent.payment_method_types?.[0],
              paymentTime: new Date(),
            },
          });
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object;
        const orderId = paymentIntent.metadata?.orderId;

        if (orderId) {
          await prisma.payment.updateMany({
            where: { orderId: orderId },
            data: {
              status: "failed",
              transactionId: paymentIntent.id,
            },
          });
        }
        break;
      }

      case "charge.refunded": {
        const charge = event.data.object;
        const paymentIntentId = charge.payment_intent;

        const payment = await prisma.payment.findFirst({
          where: { transactionId: paymentIntentId },
        });

        if (payment) {
          await prisma.payment.update({
            where: { paymentId: payment.paymentId },
            data: {
              status: "refunded",
            },
          });
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error("Error processing webhook:", error);
    res.status(500).json({
      success: false,
      error: "Webhook processing error",
    });
  }
});

exports.getPaymentStatus = asyncHandler(async (req, res) => {
  const { orderId } = req.params;

  let payment = await prisma.payment.findUnique({
    where: { orderId: orderId },
  });

  if (!payment) {
    return res.status(404).json({
      success: false,
      error: "Payment not found",
    });
  }

  // Verify status with Stripe if payment intent ID exists
  if (payment.transactionId) {
    const stripeData = await stripe.retrievePaymentIntent(payment.transactionId);
    if (stripeData.success) {
      const mappedStatus = stripe.mapPaymentStatus(stripeData.data.status);
      
      // Update payment status if it has changed
      if (mappedStatus !== payment.status) {
        payment = await prisma.payment.update({
          where: { orderId: orderId },
          data: { status: mappedStatus },
        });
      }
    }
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
      currency: "BDT",
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

  let payment = await prisma.payment.findUnique({
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

  // Retrieve payment intent from Stripe
  const verification = await stripe.retrievePaymentIntent(payment.transactionId);

  if (verification.success) {
    const mappedStatus = stripe.mapPaymentStatus(verification.data.status);

    if (mappedStatus !== payment.status) {
      payment = await prisma.payment.update({
        where: { orderId: orderId },
        data: {
          status: mappedStatus,
          paymentTime:
            mappedStatus === "completed" ? new Date() : payment.paymentTime,
        },
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        orderId: payment.orderId,
        status: payment.status,
        amount: payment.amount,
        transactionId: payment.transactionId,
        paymentTime: payment.paymentTime,
      },
    });
  } else {
    res.status(400).json({
      success: false,
      error: verification.error,
    });
  }
});
