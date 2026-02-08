
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ecormmerce/shared/services/mpesa_service.dart';
import 'package:ecormmerce/core/constants/secrets.dart';

void main() {
  test('M-Pesa Integration Test', () async {
    print('--------------- MANUAL TEST START ---------------');
    
    // 1. Test STK Push (Real API)
    print('\n[1] Testing STK Push Initiation...');
    try {
      final response = await MpesaService.instance.initiateStkPush(
        phoneNumber: '254793027220', // User provided number
        amount: 1.0,
        accountReference: 'TEST_REF',
        transactionDesc: 'Terminal Test',
      );
      
      print('STK Push Response: $response');
      if (response['success'] == true) {
        print('✅ STK Push Initiated!');
      } else {
        print('❌ STK Push Failed: ${response['error']}');
        print('   (Likely invalid Consumer Key/Secret in secrets.dart)');
      }
    } catch (e) {
      print('❌ STK Push Exception: $e');
    }

    // 2. Test Callback URL (Ngrok Connectivity)
    print('\n[2] Testing Ngrok Forwarding (Callback Simulation)...');
    print('Target: ${MpesaSecrets.callbackUrl}');
    
    final dummyPayload = {
      "Body": {
        "stkCallback": {
          "MerchantRequestID": "TEST-MERCHANT-ID",
          "CheckoutRequestID": "TEST-CHECKOUT-ID",
          "ResultCode": 0,
          "ResultDesc": "Success",
          "CallbackMetadata": {
            "Item": []
          }
        }
      }
    };

    try {
      final callbackResponse = await http.post(
        Uri.parse(MpesaSecrets.callbackUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dummyPayload),
      );
      
      print('Callback HTTP Status: ${callbackResponse.statusCode}');
      // print('Callback Response Body: ${callbackResponse.body}'); // Commented to reduce noise
      
      if (callbackResponse.statusCode >= 200 && callbackResponse.statusCode < 300) {
        print('✅ Callback URL is reachable! Forwarding works.');
      } else {
        print('⚠️ Callback URL reachable but returned error status.');
        print('   Ensure your localhost:3000 server is running and handling POST requests.');
      }
    } catch (e) {
      print('❌ Callback Connectivity Failed: $e');
      print('   Check if Ngrok is running and URL is correct.');
    }
    
    print('--------------- MANUAL TEST END -----------------');
  });
}
