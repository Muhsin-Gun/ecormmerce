const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

if (!admin.apps.length) {
  admin.initializeApp();
}

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'eshop-be005';
const REGION = 'us-central1';
const CALLBACK_FUNCTION_NAME = 'mpesaCallback';
const CALLBACK_URL = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${CALLBACK_FUNCTION_NAME}`;
const SUPER_ADMIN_EMAIL = 'muhsin57891@gmail.com';

// NOTE: keep secrets in Firebase environment config in production.
const MPESA_CONFIG = {
  consumerKey: 'QycTPzIwPxkNsSWihn5Yv476JKjrsXzppgC97OQjxbJ129zg',
  consumerSecret: 'FoWdxEGkTjgGe1p2yQwhGfWEFjYPQwOqiRmudqGa7eb1qsTrgGmeOLqIbCTFFj9M',
  shortCode: '174379',
  passKey: 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919',
  callbackUrl: CALLBACK_URL,
  baseUrl: 'https://sandbox.safaricom.co.ke',
};

const getAccessToken = async () => {
  const credentials = Buffer.from(
    `${MPESA_CONFIG.consumerKey}:${MPESA_CONFIG.consumerSecret}`
  ).toString('base64');

  const response = await axios.get(
    `${MPESA_CONFIG.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
    {
      headers: {
        Authorization: `Basic ${credentials}`,
      },
    }
  );
  return response.data.access_token;
};

const normalizePhoneNumber = (phoneNumber) => {
  let formattedPhone = String(phoneNumber || '').replace(/\s+/g, '').replace('+', '');
  if (formattedPhone.startsWith('0')) {
    formattedPhone = `254${formattedPhone.substring(1)}`;
  }
  return formattedPhone;
};

const mpesaTimestamp = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hour = String(now.getHours()).padStart(2, '0');
  const minute = String(now.getMinutes()).padStart(2, '0');
  const second = String(now.getSeconds()).padStart(2, '0');
  return `${year}${month}${day}${hour}${minute}${second}`;
};

const callbackMetadataToMap = (callbackMetadata) => {
  const map = {};
  const items = callbackMetadata && Array.isArray(callbackMetadata.Item)
    ? callbackMetadata.Item
    : [];
  for (const item of items) {
    if (!item || !item.Name) continue;
    map[item.Name] = item.Value;
  }
  return map;
};

const updateTransactionsForOrder = async (orderId, updates) => {
  const txSnap = await admin
    .firestore()
    .collection('transactions')
    .where('orderId', '==', orderId)
    .limit(20)
    .get();

  if (txSnap.empty) return;

  const batch = admin.firestore().batch();
  txSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
};

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();

const isCallerAdmin = async (auth) => {
  if (!auth?.uid) return false;

  const callerEmail = normalizeEmail(auth.token?.email);
  if (callerEmail === SUPER_ADMIN_EMAIL) {
    return true;
  }

  const callerDoc = await admin
    .firestore()
    .collection('users')
    .doc(auth.uid)
    .get();

  if (!callerDoc.exists) {
    return false;
  }

  const callerData = callerDoc.data() || {};
  const callerRole = normalizeEmail(callerData.role);
  return callerData.isRoot === true || callerRole === 'admin';
};

const deleteUserFirestoreData = async (userId) => {
  const db = admin.firestore();
  const userDocRef = db.collection('users').doc(userId);
  const notificationsSnap = await userDocRef.collection('notifications').get();

  const batch = db.batch();
  notificationsSnap.docs.forEach((doc) => batch.delete(doc.ref));
  batch.delete(userDocRef);
  batch.delete(db.collection('wishlists').doc(userId));
  batch.delete(db.collection('carts').doc(userId));
  await batch.commit();
};

const updateOrderAndTransactionsForMpesaResult = async ({
  checkoutRequestID,
  resultCode,
  resultDesc,
  metadata = {},
}) => {
  const ordersRef = admin.firestore().collection('orders');
  const orderSnap = await ordersRef
    .where('mpesaCheckoutRequestId', '==', checkoutRequestID)
    .limit(1)
    .get();

  if (orderSnap.empty) {
    functions.logger.warn('No order matched CheckoutRequestID', {
      checkoutRequestID,
    });
    return false;
  }

  const normalizedResultCode = Number(resultCode || 1);
  const receiptNumber = metadata.MpesaReceiptNumber || null;
  const transactionId = metadata.MpesaReceiptNumber || null;
  const phoneNumber = metadata.PhoneNumber ? String(metadata.PhoneNumber) : null;
  const transactionDate = metadata.TransactionDate
    ? String(metadata.TransactionDate)
    : null;
  const paidAmount = metadata.Amount != null ? Number(metadata.Amount) : null;

  const orderDoc = orderSnap.docs[0];
  if (normalizedResultCode === 0) {
    const successOrderUpdates = {
      paymentStatus: 'completed',
      status: 'processing',
      mpesaReceiptNumber: receiptNumber,
      mpesaTransactionId: transactionId,
      mpesaPhoneNumber: phoneNumber,
      paidAmount,
      mpesaTransactionDate: transactionDate,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await orderDoc.ref.update(successOrderUpdates);
    await updateTransactionsForOrder(orderDoc.id, {
      status: 'completed',
      method: 'mpesa',
      mpesaCheckoutRequestId: checkoutRequestID,
      mpesaReceiptNumber: receiptNumber,
      mpesaTransactionId: transactionId,
      mpesaPhoneNumber: phoneNumber,
      mpesaResultCode: String(normalizedResultCode),
      mpesaResultDescription: String(resultDesc || 'Completed'),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      failureReason: null,
    });
    return true;
  }

  const failedOrderUpdates = {
    paymentStatus: 'failed',
    mpesaFailureReason: String(resultDesc || 'Failed'),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await orderDoc.ref.update(failedOrderUpdates);
  await updateTransactionsForOrder(orderDoc.id, {
    status: 'failed',
    method: 'mpesa',
    mpesaCheckoutRequestId: checkoutRequestID,
    mpesaResultCode: String(normalizedResultCode),
    mpesaResultDescription: String(resultDesc || 'Failed'),
    failureReason: String(resultDesc || 'Failed'),
    failedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return true;
};

exports.mpesaStkPush = functions.https.onCall(async (data) => {
  const phoneNumber = data?.phoneNumber;
  const amount = Number(data?.amount || 0);
  const accountReference = String(data?.accountReference || '').trim();
  const transactionDesc = String(data?.transactionDesc || '').trim();

  if (!phoneNumber || !amount || !accountReference || !transactionDesc) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required M-Pesa parameters.'
    );
  }

  try {
    const token = await getAccessToken();
    const timestamp = mpesaTimestamp();
    const password = Buffer.from(
      `${MPESA_CONFIG.shortCode}${MPESA_CONFIG.passKey}${timestamp}`
    ).toString('base64');

    const formattedPhone = normalizePhoneNumber(phoneNumber);
    const payload = {
      BusinessShortCode: MPESA_CONFIG.shortCode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Math.max(1, Math.round(amount)),
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

    return {
      success: true,
      checkoutRequestID: response.data.CheckoutRequestID,
      merchantRequestID: response.data.MerchantRequestID,
      responseDescription: response.data.ResponseDescription,
    };
  } catch (error) {
    const mpesaError = error.response?.data || {};
    const message =
      mpesaError.errorMessage ||
      mpesaError.errorCode ||
      error.message ||
      'Failed to initiate STK push.';

    functions.logger.error('mpesaStkPush failed', {
      error: message,
      details: mpesaError,
    });

    return {
      success: false,
      error: message,
    };
  }
});

exports.mpesaQueryTransactionStatus = functions.https.onCall(async (data) => {
  const checkoutRequestID = String(
    data?.checkoutRequestID || data?.checkoutRequestId || ''
  ).trim();

  if (!checkoutRequestID) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'checkoutRequestID is required.'
    );
  }

  try {
    const token = await getAccessToken();
    const timestamp = mpesaTimestamp();
    const password = Buffer.from(
      `${MPESA_CONFIG.shortCode}${MPESA_CONFIG.passKey}${timestamp}`
    ).toString('base64');

    const response = await axios.post(
      `${MPESA_CONFIG.baseUrl}/mpesa/stkpushquery/v1/query`,
      {
        BusinessShortCode: MPESA_CONFIG.shortCode,
        Password: password,
        Timestamp: timestamp,
        CheckoutRequestID: checkoutRequestID,
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      }
    );

    const responseCode = String(response.data.ResponseCode || '');
    const rawResultCode = response.data.ResultCode;
    const parsedResultCode =
      rawResultCode == null ? null : Number(rawResultCode);
    const resultCode = Number.isFinite(parsedResultCode)
      ? parsedResultCode
      : null;
    const resultDesc = String(
      response.data.ResultDesc || response.data.ResponseDescription || 'Unknown'
    );

    let status = 'processing';
    if (responseCode === '0' && resultCode === 0) {
      status = 'completed';
    } else if (responseCode === '0' && resultCode != null && resultCode !== 0) {
      status = 'failed';
    }

    if (status === 'completed' || status === 'failed') {
      await updateOrderAndTransactionsForMpesaResult({
        checkoutRequestID,
        resultCode: resultCode ?? 1,
        resultDesc,
        metadata: {},
      });
    }

    return {
      success: responseCode === '0',
      checkoutRequestID,
      responseCode,
      resultCode,
      resultDesc,
      status,
    };
  } catch (error) {
    const mpesaError = error.response?.data || {};
    const message =
      mpesaError.errorMessage ||
      mpesaError.errorCode ||
      error.message ||
      'Failed to query STK status.';

    functions.logger.error('mpesaQueryTransactionStatus failed', {
      checkoutRequestID,
      error: message,
      details: mpesaError,
    });

    return {
      success: false,
      checkoutRequestID,
      error: message,
      status: 'processing',
    };
  }
});

exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method Not Allowed');
  }

  try {
    const callback = req.body?.Body?.stkCallback;
    if (!callback) {
      return res.status(400).json({ result: 'invalid_payload' });
    }

    const checkoutRequestID = callback.CheckoutRequestID;
    const resultCode = Number(callback.ResultCode || 1);
    const resultDesc = String(callback.ResultDesc || 'Unknown');
    const metadata = callbackMetadataToMap(callback.CallbackMetadata);

    await updateOrderAndTransactionsForMpesaResult({
      checkoutRequestID,
      resultCode,
      resultDesc,
      metadata,
    });

    return res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (error) {
    functions.logger.error('mpesaCallback failed', error);
    return res.status(500).json({ result: 'error' });
  }
});

exports.adminDeleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'You must be signed in to delete users.'
    );
  }

  const authorized = await isCallerAdmin(context.auth);
  if (!authorized) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can delete users.'
    );
  }

  const targetUserId = String(data?.userId || '').trim();
  if (!targetUserId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId is required.'
    );
  }

  if (targetUserId === context.auth.uid) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'You cannot delete your own account from this action.'
    );
  }

  const targetUserDoc = await admin
    .firestore()
    .collection('users')
    .doc(targetUserId)
    .get();

  const targetData = targetUserDoc.data() || {};
  const targetEmailFromDoc = normalizeEmail(targetData.email);
  if (targetData.isRoot === true || targetEmailFromDoc === SUPER_ADMIN_EMAIL) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'The super admin account cannot be deleted.'
    );
  }

  try {
    const targetAuthUser = await admin.auth().getUser(targetUserId);
    const targetEmailFromAuth = normalizeEmail(targetAuthUser.email);
    if (targetEmailFromAuth === SUPER_ADMIN_EMAIL) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'The super admin account cannot be deleted.'
      );
    }
    await admin.auth().deleteUser(targetUserId);
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    if (error?.code !== 'auth/user-not-found') {
      functions.logger.error('adminDeleteUser auth delete failed', {
        targetUserId,
        message: error?.message || String(error),
      });
      throw new functions.https.HttpsError(
        'internal',
        'Failed to delete user from Authentication.'
      );
    }
  }

  try {
    await deleteUserFirestoreData(targetUserId);
  } catch (error) {
    functions.logger.error('adminDeleteUser firestore cleanup failed', {
      targetUserId,
      message: error?.message || String(error),
    });
    throw new functions.https.HttpsError(
      'internal',
      'Authentication user deleted, but Firestore cleanup failed.'
    );
  }

  return { success: true };
});
