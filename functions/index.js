const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios'); // Use axios for HTTP requests

admin.initializeApp();

// Hardcoded secrets as requested for immediate fix
// In production, use functions.config() environment variables
const MPESA_CONFIG = {
  consumerKey: 'QycTPzIwPxkNsSWihn5Yv476JKjrsXzppgC97OQjxbJ129zg',
  consumerSecret: 'FoWdxEGkTjgGe1p2yQwhGfWEFjYPQwOqiRmudqGa7eb1qsTrgGmeOLqIbCTFFj9M',
  shortCode: '174379',
  passKey: 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
  callbackUrl: 'https://jessia-unmischievous-anglea.ngrok-free.dev/payment/mpesa/callback', // Current Ngrok or Cloud Funtion URL
  baseUrl: 'https://sandbox.safaricom.co.ke'
};

const getAccessToken = async () => {
  const credentials = Buffer.from(`${MPESA_CONFIG.consumerKey}:${MPESA_CONFIG.consumerSecret}`).toString('base64');
  try {
    const response = await axios.get(
      `${MPESA_CONFIG.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      {
        headers: {
          Authorization: `Basic ${credentials}`,
        },
      }
    );
    return response.data.access_token;
  } catch (error) {
    console.error('MPESA Auth Error:', error.response ? error.response.data : error.message);
    throw new functions.https.HttpsError('internal', 'Failed to authenticate with MPESA.');
  }
};

const normalizePhoneNumber = (phoneNumber) => {
  let formattedPhone = String(phoneNumber || '').replace(/\s+/g, '').replace('+', '');
  if (formattedPhone.startsWith('0')) {
    formattedPhone = `254${formattedPhone.substring(1)}`;
  }
  return formattedPhone;
};

exports.mpesaStkPush = functions.https.onCall(async (data, context) => {
  // Optional: Check auth
  // if (!context.auth) {
  //   throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  // }

  const { phoneNumber, amount, accountReference, transactionDesc } = data || {};
  
  if (!phoneNumber || !amount || !accountReference || !transactionDesc) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters.');
  }

  try {
    const token = await getAccessToken();
    
    // Generate Timestamp YYYYMMDDHHmmss
    const now = new Date();
    // Use manual formatting to match Safaricom requirement exactly
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hour = String(now.getHours()).padStart(2, '0');
    const minute = String(now.getMinutes()).padStart(2, '0');
    const second = String(now.getSeconds()).padStart(2, '0');
    const timestamp = `${year}${month}${day}${hour}${minute}${second}`;
    
    const password = Buffer.from(`${MPESA_CONFIG.shortCode}${MPESA_CONFIG.passKey}${timestamp}`).toString('base64');
    const formattedPhone = normalizePhoneNumber(phoneNumber);

    const payload = {
      BusinessShortCode: MPESA_CONFIG.shortCode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Math.round(Number(amount)),
      PartyA: formattedPhone,
      PartyB: MPESA_CONFIG.shortCode,
      PhoneNumber: formattedPhone,
      CallBackURL: MPESA_CONFIG.callbackUrl,
      AccountReference: accountReference,
      TransactionDesc: transactionDesc,
    };

    console.log('Sending STK Push Payload:', JSON.stringify(payload));

    const response = await axios.post(
      `${MPESA_CONFIG.baseUrl}/mpesa/stkpush/v1/processrequest`,
      payload,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log('STK Push Response:', response.data);

    return {
      success: true,
      checkoutRequestID: response.data.CheckoutRequestID,
      merchantRequestID: response.data.MerchantRequestID,
      responseDescription: response.data.ResponseDescription,
    };

  } catch (error) {
    console.error('STK Push System Error:', error);
    const mpesaError = error.response ? error.response.data : {};
    
    // Return structured error to client
    return {
        success: false,
        error: mpesaError.errorMessage || error.message || 'Unknown error occurred'
    };
  }
});
