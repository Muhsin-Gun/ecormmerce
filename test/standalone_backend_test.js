
const axios = require('../functions/node_modules/axios');

// Same config as in functions/index.js
const MPESA_CONFIG = {
    consumerKey: 'QycTPzIwPxkNsSWihn5Yv476JKjrsXzppgC97OQjxbJ129zg',
    consumerSecret: 'FoWdxEGkTjgGe1p2yQwhGfWEFjYPQwOqiRmudqGa7eb1qsTrgGmeOLqIbCTFFj9M',
    shortCode: '174379',
    passKey: 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
    callbackUrl: 'https://jessia-unmischievous-anglea.ngrok-free.dev/payment/mpesa/callback',
    baseUrl: 'https://sandbox.safaricom.co.ke'
};

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
        throw error;
    }
};

const runTest = async () => {
    console.log('--- Testing Backend Logic Standalone ---');
    try {
        console.log('1. Authenticating...');
        const token = await getAccessToken();
        console.log('   Token received!');

        const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
        const password = Buffer.from(`${MPESA_CONFIG.shortCode}${MPESA_CONFIG.passKey}${timestamp}`).toString('base64');

        // User provided number
        const phoneNumber = '254793027220';

        const payload = {
            BusinessShortCode: MPESA_CONFIG.shortCode,
            Password: password,
            Timestamp: timestamp,
            TransactionType: 'CustomerPayBillOnline',
            Amount: 1,
            PartyA: phoneNumber,
            PartyB: MPESA_CONFIG.shortCode,
            PhoneNumber: phoneNumber,
            CallBackURL: MPESA_CONFIG.callbackUrl,
            AccountReference: 'BACKEND_TEST',
            TransactionDesc: 'Standalone Test',
        };

        console.log('2. Sending STK Push...');
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

        console.log('✅ SUCCESS! Response:', response.data);
    } catch (error) {
        console.error('❌ FAILED:', error.response ? error.response.data : error.message);
    }
    console.log('----------------------------------------');
};

runTest();
