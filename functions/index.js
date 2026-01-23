const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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
        mpesaTransactionDate: transactionDate,
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
