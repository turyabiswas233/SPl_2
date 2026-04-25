const crypto = require('crypto');

class AamarPay {
  constructor() {
    this.storeId = process.env.AAMARPAY_STORE_ID || 'aamarpaytest';
    this.signatureKey = process.env.AAMARPAY_SIGNATURE_KEY || 'dbb74894e82415a2f7ff0ec3a97e4183';
    this.mode = process.env.AAMARPAY_MODE || 'sandbox';
    
    this.baseUrl = this.mode === 'live' 
      ? 'https://secure.aamarpay.com' 
      : 'https://sandbox.aamarpay.com';
    
    this.apiEndpoint = `${this.baseUrl}/jsonpost.php`;
    this.paymentUrl = `${this.baseUrl}/paynow.php`;
  }

  generateSignature(amount, orderId) {
    const data = `${this.storeId}${orderId}${amount}${this.signatureKey}`;
    return crypto.createHash('md5').update(data).digest('hex');
  }

  verifyCallback(data) {
    const { store_id, order_id, amount, payment_status, signature_key } = data;

    if (payment_status !== 'Success' && payment_status !== 'success') {
      return false;
    }

    const expectedSignature = this.generateSignature(amount, order_id);
    return signature_key === expectedSignature;
  }

  async initiatePayment(paymentData) {
    const {
      amount,
      orderId,
      customerName,
      customerEmail,
      customerPhone,
      customerAddress,
      description,
      returnUrl,
      cancelUrl,
      callbackUrl
    } = paymentData;

    const signature = this.generateSignature(amount, orderId);

    const payload = {
      store_id: this.storeId,
      signature_key: signature,
      amount: amount.toString(),
      order_id: orderId,
      currency: 'BDT',
      customer_name: customerName,
      customer_email: customerEmail,
      customer_phone: customerPhone,
      customer_address: customerAddress || 'Bangladesh',
      product_name: 'Dromos Ride Payment',
      product_category: 'Transportation',
      product_profile: 'general',
      desc: description || 'Payment for Dromos ride',
      return_url: returnUrl || `${process.env.AAMARPAY_CALLBACK_URL}?order_id=${orderId}`,
      cancel_url: cancelUrl || `${process.env.AAMARPAY_CALLBACK_URL}?status=cancelled&order_id=${orderId}`,
      ipn_url: callbackUrl || process.env.AAMARPAY_CALLBACK_URL
    };

    try {
      const formData = new URLSearchParams();
      for (const [key, value] of Object.entries(payload)) {
        formData.append(key, value);
      }

      const response = await fetch(this.apiEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString()
      });

      const result = await response.json();

      if (result.result === 'true' || result.result === true) {
        return {
          success: true,
          paymentUrl: result.payment_url,
          transactionId: result.pg_txnid || orderId,
          orderId: orderId
        };
      } else {
        return {
          success: false,
          error: result.error || 'Payment initiation failed',
          errorCode: result.failedreason
        };
      }
    } catch (error) {
      console.error('AamarPay Error:', error);
      return {
        success: false,
        error: 'Network error occurred'
      };
    }
  }

  async verifyPayment(transactionId) {
    const payload = {
      store_id: this.storeId,
      signature_key: this.signatureKey,
      type: 'verification',
      trx_id: transactionId
    };

    try {
      const formData = new URLSearchParams();
      for (const [key, value] of Object.entries(payload)) {
        formData.append(key, value);
      }

      const response = await fetch(this.apiEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData.toString()
      });

      return await response.json();
    } catch (error) {
      console.error('AamarPay Verification Error:', error);
      return { success: false, error: 'Verification failed' };
    }
  }
}

module.exports = new AamarPay();