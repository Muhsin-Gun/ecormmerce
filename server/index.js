const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Note: This requires GOOGLE_APPLICATION_CREDENTIALS env var or gcloud login
// If it fails, the callback won't update Firestore, but STK push will still work.
try {
    admin.initializeApp();
} catch (e) {
    console.warn('Firebase Admin Init Warning:', e.message);
    console.warn('Callbacks will not update Firestore unless authenticated.');
}

const app = express();
app.use(cors());
app.use(bodyParser.json());

// --- CONFIGURATION ---
const PORT = 3000;
const MPESA_CONFIG = {
    consumerKey: 'QycTPzIwPxkNsSWihn5Yv476JKjrsXzppgC97OQjxbJ129zg',
    consumerSecret: 'FoWdxEGkTjgGe1p2yQwhGfWEFjYPQwOqiRmudqGa7eb1qsTrgGmeOLqIbCTFFj9M',
    shortCode: '174379',
    passKey: 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
    callbackUrl: 'https://jessia-unmischievous-anglea.ngrok-free.dev/payment/mpesa/callback', // MUST match Ngrok
    baseUrl: 'https://sandbox.safaricom.co.ke'
};

// --- HELPERS ---
const getAccessToken = async () => {
    const credentials = Buffer.from(`${MPESA_CONFIG.consumerKey}:${MPESA_CONFIG.consumerSecret}`).toString('base64');
    try {
        const response = await axios.get(
            `${MPESA_CONFIG.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
            { headers: { Authorization: `Basic ${credentials}` } }
        );
        return response.data.access_token;
    } catch (error) {
        console.error('Auth Error:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get Access Token');
    }
};

const normalizePhoneNumber = (phoneNumber) => {
    let formattedPhone = String(phoneNumber || '').replace(/\s+/g, '').replace('+', '');
    if (formattedPhone.startsWith('0')) {
        formattedPhone = `254${formattedPhone.substring(1)}`;
    }
    return formattedPhone;
};

// --- ENDPOINTS ---

/**
 * 1. STK Push Endpoint
 * Called by Flutter App
 */
app.post('/mpesaStkPush', async (req, res) => {
    console.log('Received STK Push Request:', req.body);

    const { phoneNumber, amount, accountReference, transactionDesc } = req.body;

    if (!phoneNumber || !amount || !accountReference || !transactionDesc) {
        return res.status(400).json({ error: 'Missing parameters' });
    }

    try {
        const token = await getAccessToken();
        const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
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

        console.log('STK Push Success:', response.data);
        res.json(response.data);

    } catch (error) {
        console.error('STK Push Failed:', error.response ? error.response.data : error.message);
        res.status(500).json({ error: error.message });
    }
});

/**
 * 2. Callback Endpoint
 * Called by Safaricom (via Ngrok)
 */
app.post('/payment/mpesa/callback', async (req, res) => { // Updated path to match Ngrok URL
    console.log('Received M-Pesa Callback:', JSON.stringify(req.body, null, 2));

    try {
        const body = req.body;
        if (!body.Body || !body.Body.stkCallback) {
            console.log('Invalid Callback format');
            return res.status(400).send('Invalid Format');
        }

        const callback = body.Body.stkCallback;
        const resultCode = callback.ResultCode;
        const checkoutRequestId = callback.CheckoutRequestID;

        // Only attempt Firestore update if Admin SDK initialized
        if (admin.apps.length > 0) {
            const ordersRef = admin.firestore().collection('orders');
            const snapshot = await ordersRef
                .where('mpesaCheckoutRequestId', '==', checkoutRequestId)
                .limit(1)
                .get();

            if (!snapshot.empty) {
                const orderDoc = snapshot.docs[0];

                if (resultCode === 0) {
                    // SUCCESS
                    const meta = callback.CallbackMetadata.Item;
                    const amount = meta.find(i => i.Name === 'Amount')?.Value;
                    const receipt = meta.find(i => i.Name === 'MpesaReceiptNumber')?.Value;
                    const transactionDate = meta.find(i => i.Name === 'TransactionDate')?.Value;
                    const phone = meta.find(i => i.Name === 'PhoneNumber')?.Value;

                    await orderDoc.ref.update({
                        paymentStatus: 'completed',
                        status: 'processing',
                        mpesaReceiptNumber: receipt,
                        mpesaPhoneNumber: phone,
                        paidAmount: amount,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`Order ${orderDoc.id} UPDATED: PAID`);
                } else {
                    // FAILED
                    await orderDoc.ref.update({
                        paymentStatus: 'failed',
                        mpesaFailureReason: callback.ResultDesc,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`Order ${orderDoc.id} UPDATED: FAILED`);
                }
            } else {
                console.log('No matching order found for CheckoutRequestID:', checkoutRequestId);
            }
        } else {
            console.log('Skipping Firestore update (Admin SDK not initialized).');
        }

        res.json({ result: 'processed' });
    } catch (error) {
        console.error('Callback Logic Error:', error);
        res.status(500).send('Internal Error');
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`\n🚀 Local M-Pesa Backend running at http://localhost:${PORT}`);
    console.log(`👉 Ngrok should point to port ${PORT}`);
    console.log(`Callback URL: ${MPESA_CONFIG.callbackUrl}\n`);
});
