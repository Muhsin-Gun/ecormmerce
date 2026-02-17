const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const admin = require('firebase-admin');
const crypto = require('crypto');
let nodemailer = null;

try {
    nodemailer = require('nodemailer');
} catch (error) {
    console.warn('Nodemailer is not installed. OTP email endpoints will be unavailable until dependencies are installed.');
}

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

const OTP_CONFIG = {
    ttlMs: 5 * 60 * 1000,
    resendCooldownsMs: [30 * 1000, 60 * 1000, 120 * 1000],
    maxResendsPerSession: 3,
    maxAttempts: 5,
    collection: 'email_verifications',
    analyticsCollection: 'verification_analytics',
};

const EMAIL_CONFIG = {
    host: process.env.SMTP_HOST || '',
    port: Number(process.env.SMTP_PORT || 587),
    secure: String(process.env.SMTP_SECURE || 'false').toLowerCase() === 'true',
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    from: process.env.MAIL_FROM || process.env.SMTP_USER || '',
    connectionTimeoutMs: Number(process.env.SMTP_CONNECTION_TIMEOUT_MS || 8000),
    greetingTimeoutMs: Number(process.env.SMTP_GREETING_TIMEOUT_MS || 8000),
    socketTimeoutMs: Number(process.env.SMTP_SOCKET_TIMEOUT_MS || 10000),
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

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();
const emailLooksValid = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const nowMs = () => Date.now();
const generateOtp = () => String(crypto.randomInt(0, 1000000)).padStart(6, '0');
const generateSalt = () => crypto.randomBytes(16).toString('hex');
const hashOtp = (otp, salt) =>
    crypto.createHash('sha256').update(`${otp}:${salt}`).digest('hex');
const compareHash = (a, b) => {
    const bufferA = Buffer.from(a);
    const bufferB = Buffer.from(b);
    return bufferA.length === bufferB.length && crypto.timingSafeEqual(bufferA, bufferB);
};

const otpCollection = () => admin.firestore().collection(OTP_CONFIG.collection);
const otpAnalyticsCollection = () => admin.firestore().collection(OTP_CONFIG.analyticsCollection);
const isAdminReady = () => admin.apps.length > 0;
const getCooldownMs = (resendCount) => {
    const idx = Math.min(Math.max(resendCount, 0), OTP_CONFIG.resendCooldownsMs.length - 1);
    return OTP_CONFIG.resendCooldownsMs[idx];
};
const remainingResends = (resendCount) =>
    Math.max(0, OTP_CONFIG.maxResendsPerSession - resendCount);

const logOtpEvent = async (eventName, email, meta = {}) => {
    if (!isAdminReady()) return;
    try {
        await otpAnalyticsCollection().add({
            eventName,
            email,
            meta,
            createdAtMs: nowMs(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (error) {
        console.warn('otp analytics log failed:', error.message);
    }
};

const ensureEmailConfig = () => {
    if (!nodemailer) {
        throw new Error('Nodemailer dependency is missing. Run npm install in /server.');
    }
    if (!EMAIL_CONFIG.host || !EMAIL_CONFIG.user || !EMAIL_CONFIG.pass || !EMAIL_CONFIG.from) {
        throw new Error('Email service is not configured (SMTP_HOST, SMTP_USER, SMTP_PASS, MAIL_FROM).');
    }
};

const mailTransporter = () => {
    ensureEmailConfig();
    return nodemailer.createTransport({
        host: EMAIL_CONFIG.host,
        port: EMAIL_CONFIG.port,
        secure: EMAIL_CONFIG.secure,
        connectionTimeout: EMAIL_CONFIG.connectionTimeoutMs,
        greetingTimeout: EMAIL_CONFIG.greetingTimeoutMs,
        socketTimeout: EMAIL_CONFIG.socketTimeoutMs,
        auth: {
            user: EMAIL_CONFIG.user,
            pass: EMAIL_CONFIG.pass,
        },
    });
};

const mapOtpSendError = (error) => {
    const raw = String(error?.message || '').trim();
    const lower = raw.toLowerCase();

    if (lower.includes('email service is not configured') || lower.includes('nodemailer dependency is missing')) {
        return {
            status: 503,
            message: 'OTP email is not configured on the server. Set SMTP_HOST, SMTP_USER, SMTP_PASS, and MAIL_FROM, then restart the backend.',
        };
    }

    if (lower.includes('timed out') || lower.includes('etimedout') || lower.includes('econnrefused') || lower.includes('enotfound')) {
        return {
            status: 504,
            message: 'OTP email provider timed out. Check SMTP settings and try again.',
        };
    }

    return {
        status: 500,
        message: 'Failed to send verification code. Please try again.',
    };
};

const sendOtpEmail = async ({ email, userName, otp }) => {
    const transporter = mailTransporter();
    const safeName = (userName || 'there').trim();
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #111827;">
        <h2 style="margin-bottom: 8px;">Verify your email</h2>
        <p style="margin: 0 0 16px;">Hi ${safeName},</p>
        <p style="margin: 0 0 16px;">Use the code below to verify your ProMarket account:</p>
        <div style="font-size: 28px; letter-spacing: 6px; font-weight: 700; padding: 12px 16px; background:#f3f4f6; border-radius:8px; display:inline-block;">${otp}</div>
        <p style="margin: 16px 0 0;">This code expires in 5 minutes.</p>
        <p style="margin: 8px 0 0; color:#6b7280; font-size: 12px;">If you did not request this, you can safely ignore this email.</p>
      </div>
    `;
    await transporter.sendMail({
        from: EMAIL_CONFIG.from,
        to: email,
        subject: 'Your ProMarket verification code',
        text: `Your ProMarket verification code is ${otp}. It expires in 5 minutes.`,
        html,
    });
};

// --- ENDPOINTS ---

app.post('/auth/send-otp', async (req, res) => {
    const email = normalizeEmail(req.body?.email);
    const userName = String(req.body?.userName || '').trim();
    const isResend = req.body?.resend === true;

    if (!emailLooksValid(email)) {
        return res.status(400).json({ success: false, message: 'A valid email is required.' });
    }

    if (!isAdminReady()) {
        return res.status(500).json({ success: false, message: 'Verification service unavailable. Admin SDK is not initialized.' });
    }

    try {
        ensureEmailConfig();
        const docRef = otpCollection().doc(email);
        const snapshot = await docRef.get();
        const existing = snapshot.exists ? snapshot.data() : null;
        const now = nowMs();
        const resendCount = Number(existing?.resendCount || 0);
        const nextAllowedAtMs = Number(existing?.nextResendAtMs || 0);

        if (isResend && resendCount >= OTP_CONFIG.maxResendsPerSession) {
            await logOtpEvent('resend_cap_reached', email, { resendCount });
            return res.status(429).json({
                success: false,
                resendCapReached: true,
                remainingResends: 0,
                cooldownSeconds: 0,
                message: 'Resend limit reached. Please contact support or use alternate verification.',
            });
        }

        if (nextAllowedAtMs && now < nextAllowedAtMs) {
            const waitSec = Math.ceil((nextAllowedAtMs - now) / 1000);
            await logOtpEvent('resend_rate_limited', email, { waitSec, resendCount });
            return res.status(429).json({
                success: false,
                resendCapReached: resendCount >= OTP_CONFIG.maxResendsPerSession,
                remainingResends: remainingResends(resendCount),
                cooldownSeconds: waitSec,
                message: `Please wait ${waitSec}s before requesting another code.`,
            });
        }

        const otp = generateOtp();
        const salt = generateSalt();
        const otpHash = hashOtp(otp, salt);
        const expiresAtMs = now + OTP_CONFIG.ttlMs;
        const nextResendCount = isResend ? resendCount + 1 : 0;
        const cooldownMs = getCooldownMs(nextResendCount);
        const nextResendAtMs = now + cooldownMs;
        const remResends = remainingResends(nextResendCount);

        await docRef.set({
            email,
            userName,
            otpHash,
            salt,
            attempts: 0,
            verified: false,
            expiresAtMs,
            resendCount: nextResendCount,
            nextResendAtMs,
            lastSentAtMs: now,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: existing?.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await sendOtpEmail({ email, userName, otp });
        await logOtpEvent(isResend ? 'otp_resent' : 'otp_sent', email, {
            resendCount: nextResendCount,
            cooldownSeconds: Math.floor(cooldownMs / 1000),
        });

        return res.json({
            success: true,
            message: 'Verification code sent.',
            expiresInSeconds: Math.floor(OTP_CONFIG.ttlMs / 1000),
            cooldownSeconds: Math.floor(cooldownMs / 1000),
            remainingResends: remResends,
            resendCapReached: remResends <= 0,
        });
    } catch (error) {
        console.error('send-otp error:', error.message);
        await logOtpEvent('send_otp_error', email, { message: error.message });
        const mapped = mapOtpSendError(error);
        return res.status(mapped.status).json({
            success: false,
            message: mapped.message,
        });
    }
});

app.post('/auth/verify-otp', async (req, res) => {
    const email = normalizeEmail(req.body?.email);
    const otp = String(req.body?.otp || '').trim();

    if (!emailLooksValid(email) || otp.length !== 6) {
        return res.status(400).json({ success: false, message: 'Invalid verification request.' });
    }

    if (!isAdminReady()) {
        return res.status(500).json({ success: false, message: 'Verification service unavailable. Admin SDK is not initialized.' });
    }

    try {
        const docRef = otpCollection().doc(email);
        const snapshot = await docRef.get();
        if (!snapshot.exists) {
            await logOtpEvent('verify_missing_session', email);
            return res.status(404).json({ success: false, message: 'No OTP request found for this email.' });
        }

        const data = snapshot.data() || {};
        const attempts = Number(data.attempts || 0);
        const expiresAtMs = Number(data.expiresAtMs || 0);
        const salt = String(data.salt || '');
        const expectedHash = String(data.otpHash || '');
        const now = nowMs();

        if (attempts >= OTP_CONFIG.maxAttempts) {
            await logOtpEvent('verify_locked', email, { attempts });
            return res.status(429).json({ success: false, message: 'Too many failed attempts. Request a new code.' });
        }

        if (!expiresAtMs || now > expiresAtMs) {
            await docRef.update({
                verified: false,
                expiredAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await logOtpEvent('verify_expired', email);
            return res.status(410).json({
                success: false,
                status: 'expired',
                message: 'Code expired — resend?',
            });
        }

        const incomingHash = hashOtp(otp, salt);
        if (!compareHash(expectedHash, incomingHash)) {
            const nextAttempts = attempts + 1;
            await docRef.update({ attempts: nextAttempts });
            await logOtpEvent('verify_failed', email, { attempts: nextAttempts });
            return res.status(401).json({
                success: false,
                message: `Invalid code. ${Math.max(0, OTP_CONFIG.maxAttempts - nextAttempts)} attempts remaining.`,
            });
        }

        const users = await admin.firestore()
            .collection('users')
            .where('email', '==', email)
            .limit(1)
            .get();

        if (users.empty) {
            return res.status(404).json({ success: false, message: 'User account not found for this email.' });
        }

        const userDoc = users.docs[0];
        await userDoc.ref.update({
            emailVerified: true,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await docRef.update({
            verified: true,
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await logOtpEvent('verify_success', email);

        return res.json({ success: true, message: 'Email verified successfully.' });
    } catch (error) {
        console.error('verify-otp error:', error.message);
        await logOtpEvent('verify_error', email, { message: error.message });
        return res.status(500).json({
            success: false,
            message: 'Could not verify code right now. Please try again.',
        });
    }
});

app.post('/auth/verification-status', async (req, res) => {
    const email = normalizeEmail(req.body?.email);

    if (!emailLooksValid(email)) {
        return res.status(400).json({ verified: false, status: 'invalid', message: 'Invalid email.' });
    }

    if (!isAdminReady()) {
        return res.status(500).json({ verified: false, status: 'error', message: 'Verification service unavailable.' });
    }

    try {
        const snapshot = await otpCollection().doc(email).get();
        if (!snapshot.exists) {
            return res.json({ verified: false, status: 'pending' });
        }

        const data = snapshot.data() || {};
        const verified = data.verified === true;
        const expiresAtMs = Number(data.expiresAtMs || 0);
        const expired = expiresAtMs > 0 && nowMs() > expiresAtMs;
        const resendCount = Number(data.resendCount || 0);
        const nextResendAtMs = Number(data.nextResendAtMs || 0);
        const cooldownSeconds = Math.max(0, Math.ceil((nextResendAtMs - nowMs()) / 1000));

        return res.json({
            verified,
            status: verified ? 'verified' : (expired ? 'expired' : 'pending'),
            attempts: Number(data.attempts || 0),
            expiresAtMs,
            cooldownSeconds,
            remainingResends: remainingResends(resendCount),
            resendCapReached: resendCount >= OTP_CONFIG.maxResendsPerSession,
        });
    } catch (error) {
        console.error('verification-status error:', error.message);
        return res.status(500).json({
            verified: false,
            status: 'error',
            message: 'Unable to fetch verification status.',
        });
    }
});

app.post('/auth/client-event', async (req, res) => {
    const email = normalizeEmail(req.body?.email);
    const eventName = String(req.body?.eventName || '').trim();
    const meta = req.body?.meta && typeof req.body.meta === 'object' ? req.body.meta : {};

    if (!isAdminReady()) {
        return res.status(500).json({ success: false, message: 'Analytics service unavailable.' });
    }
    if (!eventName || !emailLooksValid(email)) {
        return res.status(400).json({ success: false, message: 'Invalid analytics payload.' });
    }

    await logOtpEvent(eventName, email, meta);
    return res.json({ success: true });
});

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
