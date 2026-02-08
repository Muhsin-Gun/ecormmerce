const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const getMpesaConfig = () => {
  const config = functions.config && functions.config().mpesa ? functions.config().mpesa : {};
  return {
    consumerKey: config.consumer_key || process.env.MPESA_CONSUMER_KEY,
    consumerSecret: config.consumer_secret || process.env.MPESA_CONSUMER_SECRET,
    shortCode: config.short_code || process.env.MPESA_SHORT_CODE,
    passKey: config.pass_key || process.env.MPESA_PASS_KEY,
    callbackUrl: config.callback_url || process.env.MPESA_CALLBACK_URL,
    baseUrl: (config.env || process.env.MPESA_ENV) === 'production'
      ? 'https://api.safaricom.co.ke'
      : 'https://sandbox.safaricom.co.ke',
  };
};

const normalizePhoneNumber = (phoneNumber) => {
  let formattedPhone = String(phoneNumber || '').replace(/\s+/g, '').replace('+', '');
  if (formattedPhone.startsWith('0')) {
    formattedPhone = `254${formattedPhone.substring(1)}`;
  }
  return formattedPhone;
};

const getAccessToken = async (config) => {
  const credentials = Buffer.from(`${config.consumerKey}:${config.consumerSecret}`).toString('base64');
  const response = await fetch(
    `${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    {
      method: 'GET',
      headers: {
        Authorization: `Basic ${credentials}`,
      },
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    throw new functions.https.HttpsError('internal', `MPESA auth failed: ${errorBody}`);
  }

  const data = await response.json();
  return data.access_token;
};

exports.mpesaStkPush = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const { phoneNumber, amount, accountReference, transactionDesc } = data || {};
  if (!phoneNumber || !amount || !accountReference || !transactionDesc) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing STK push parameters.');
  }

  const config = getMpesaConfig();
  if (!config.consumerKey || !config.consumerSecret || !config.shortCode || !config.passKey || !config.callbackUrl) {
    throw new functions.https.HttpsError('failed-precondition', 'MPESA configuration is incomplete.');
  }

  const token = await getAccessToken(config);
  const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const password = Buffer.from(`${config.shortCode}${config.passKey}${timestamp}`).toString('base64');
  const formattedPhone = normalizePhoneNumber(phoneNumber);

  const payload = {
    BusinessShortCode: config.shortCode,
    Password: password,
    Timestamp: timestamp,
    TransactionType: 'CustomerPayBillOnline',
    Amount: Math.round(Number(amount)),
    PartyA: formattedPhone,
    PartyB: config.shortCode,
    PhoneNumber: formattedPhone,
    CallBackURL: config.callbackUrl,
    AccountReference: accountReference,
    TransactionDesc: transactionDesc,
  };

  const response = await fetch(
    `${config.baseUrl}/mpesa/stkpush/v1/processrequest`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    },
  );

  const responseData = await response.json();

  if (!response.ok) {
    throw new functions.https.HttpsError('internal', responseData.errorMessage || 'STK push failed.');
  }

  return {
    success: true,
    checkoutRequestID: responseData.CheckoutRequestID,
    merchantRequestID: responseData.MerchantRequestID,
    responseDescription: responseData.ResponseDescription,
  };
});

/**
 * Handle M-PESA Callbacks (Cloud Function)
 * Deployed to: /payment/mpesa/callback (via rewrite or direct URL)
 */
exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
  try {
    const body = req.body;
    
    console.log('Received MPESA Callback:', JSON.stringify(body));

    if (!body.Body || !body.Body.stkCallback) {
       console.log('Invalid Callback format');
       return res.status(400).send('Invalid Format');
    }

    const callback = body.Body.stkCallback;
    const resultCode = callback.ResultCode;
    const checkoutRequestId = callback.CheckoutRequestID;

    // Find Order by CheckoutRequestID (Need to store this on order creation or update)
    // Assuming we query orders collection for matches
    const ordersRef = admin.firestore().collection('orders');
    const snapshot = await ordersRef
        .where('mpesaCheckoutRequestId', '==', checkoutRequestId)
        .limit(1)
        .get();

    if (snapshot.empty) {
      console.log('Order not found for CheckoutRequestID:', checkoutRequestId);
      return res.status(404).send('Order not found');
    }

    const orderDoc = snapshot.docs[0];
    const orderId = orderDoc.id;

    if (resultCode === 0) {
      // SUCCESS
      const meta = callback.CallbackMetadata.Item;
      const amount = meta.find(i => i.Name === 'Amount')?.Value;
      const receipt = meta.find(i => i.Name === 'MpesaReceiptNumber')?.Value;
      const transactionDate = meta.find(i => i.Name === 'TransactionDate')?.Value;
      const phone = meta.find(i => i.Name === 'PhoneNumber')?.Value;

      await orderDoc.ref.update({
        paymentStatus: 'completed',
        status: 'processing', // Move from Pending to Processing
        mpesaReceiptNumber: receipt,
        mpesaTransactionDate: transactionDate
          ? admin.firestore.Timestamp.fromDate(
              new Date(
                `${String(transactionDate).substring(0, 4)}-${String(transactionDate).substring(4, 6)}-${String(transactionDate).substring(6, 8)}T${String(transactionDate).substring(8, 10)}:${String(transactionDate).substring(10, 12)}:${String(transactionDate).substring(12, 14)}Z`,
              ),
            )
          : null,
        mpesaPhoneNumber: phone,
        paidAmount: amount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Order ${orderId} marked as PAID. Receipt: ${receipt}`);
    } else {
      // FAILED / CANCELLED
      const resultDesc = callback.ResultDesc;
      
      await orderDoc.ref.update({
        paymentStatus: 'failed',
        mpesaFailureReason: resultDesc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Order ${orderId} payment FAILED: ${resultDesc}`);
    }

    res.status(200).json({ result: 'processed' });
  } catch (error) {
    console.error('Error processing callback:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Note: To deploy this, run `firebase init functions` (javascript), replace index.js, and `firebase deploy --only functions`
