const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

class StripePayment {
  constructor() {
    this.stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    this.stripePublishableKey = process.env.STRIPE_PUBLISHABLE_KEY;
  }

  /**
   * Create a payment intent for Stripe
   * @param {Object} paymentData - Payment data
   * @returns {Promise<Object>} - Payment intent or error
   */
  async createPaymentIntent(paymentData) {
    const {
      amount,
      currency,
      customerId,
      orderId,
      description,
      metadata,
    } = paymentData;

    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency || "usd", // Stripe uses lowercase currency codes
        customer: customerId,
        description: description || "Dromos Ride Payment",
        metadata: {
          orderId: orderId,
          ...metadata,
        },
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        publishableKey: this.stripePublishableKey,
        paymentIntentId: paymentIntent.id,
        amount: amount,
        currency: currency || "usd",
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        code: error.code,
      };
    }
  }

  /**
   * Create a customer for Stripe
   * @param {Object} customerData - Customer data
   * @returns {Promise<Object>} - Customer or error
   */
  async createCustomer(customerData) {
    const { email, name, phone } = customerData;

    try {
      const customer = await stripe.customers.create({
        email: email,
        name: name,
        phone: phone,
      });

      return {
        success: true,
        customerId: customer.id,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Retrieve payment intent details
   * @param {string} paymentIntentId - Payment intent ID
   * @returns {Promise<Object>} - Payment intent details
   */
  async retrievePaymentIntent(paymentIntentId) {
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId
      );

      return {
        success: true,
        data: {
          id: paymentIntent.id,
          status: paymentIntent.status,
          amount: paymentIntent.amount / 100, // Convert back to main currency unit
          currency: paymentIntent.currency,
          charges: paymentIntent.charges,
          metadata: paymentIntent.metadata,
        },
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Refund a payment
   * @param {string} paymentIntentId - Payment intent ID
   * @returns {Promise<Object>} - Refund result
   */
  async refundPayment(paymentIntentId) {
    try {
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
      });

      return {
        success: true,
        refundId: refund.id,
        amount: refund.amount / 100,
        status: refund.status,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Verify webhook signature from Stripe
   * @param {string} body - Raw request body
   * @param {string} signature - Stripe signature header
   * @returns {boolean} - Whether signature is valid
   */
  verifyWebhookSignature(body, signature) {
    try {
      const event = stripe.webhooks.constructEvent(
        body,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET
      );
      return { valid: true, event };
    } catch (error) {
      return { valid: false, error: error.message };
    }
  }

  /**
   * Get payment status mapping
   * @param {string} stripeStatus - Stripe payment status
   * @returns {string} - Normalized payment status
   */
  mapPaymentStatus(stripeStatus) {
    const statusMap = {
      requires_payment_method: "pending",
      requires_confirmation: "pending",
      requires_action: "processing",
      processing: "processing",
      requires_capture: "processing",
      succeeded: "completed",
      canceled: "cancelled",
    };

    return statusMap[stripeStatus] || "pending";
  }
}

module.exports = new StripePayment();
