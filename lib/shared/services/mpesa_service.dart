import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/secrets.dart';

class MpesaService {
  static final MpesaService instance = MpesaService._();
  
  MpesaService._();

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Generate Access Token (OAuth 2.0)
  Future<String?> getAccessToken() async {
    try {
      if (_accessToken != null && 
          _tokenExpiry != null && 
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken;
      }

      final credentials = '${MpesaSecrets.consumerKey}:${MpesaSecrets.consumerSecret}';
      final bytes = utf8.encode(credentials);
      final base64Credentials = base64.encode(bytes);

      final response = await http.get(
        Uri.parse('${MpesaSecrets.baseUrl}/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $base64Credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as String; // Usually seconds as string or int
        _tokenExpiry = DateTime.now().add(Duration(seconds: int.parse(expiresIn)));
        return _accessToken;
      } else {
        debugPrint('MPESA Auth Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('MPESA Auth Error: $e');
      return null;
    }
  }

  /// Initiate STK Push (Lipa Na M-PESA Online)
  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference, // e.g. Order ID
    required String transactionDesc,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Failed to get access token');
    }

    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final password = 
        base64.encode(utf8.encode('${MpesaSecrets.shortCode}${MpesaSecrets.passKey}$timestamp'));

    // Format phone number: 07... to 2547...
    String formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254${formattedPhone.substring(1)}';
    }

    final body = {
      "BusinessShortCode": MpesaSecrets.shortCode,
      "Password": password,
      "Timestamp": timestamp,
      "TransactionType": "CustomerPayBillOnline",
      "Amount": amount.toInt(), // STK Push requires int commonly
      "PartyA": formattedPhone,
      "PartyB": MpesaSecrets.shortCode,
      "PhoneNumber": formattedPhone,
      "CallBackURL": MpesaSecrets.callbackUrl,
      "AccountReference": accountReference,
      "TransactionDesc": transactionDesc,
    };

    try {
      final response = await http.post(
        Uri.parse('${MpesaSecrets.baseUrl}/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Success: ResponseCode "0"
        return {
          'success': true,
          'checkoutRequestID': responseData['CheckoutRequestID'],
          'merchantRequestID': responseData['MerchantRequestID'],
          'responseDescription': responseData['ResponseDescription'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['errorMessage'] ?? 'Request failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Query Transaction Status
  Future<Map<String, dynamic>> queryTransactionStatus(String checkoutRequestId) async {
     final token = await getAccessToken();
    if (token == null) {
      throw Exception('Failed to get access token');
    }

    final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final password = 
        base64.encode(utf8.encode('${MpesaSecrets.shortCode}${MpesaSecrets.passKey}$timestamp'));

    final body = {
      "BusinessShortCode": MpesaSecrets.shortCode,
      "Password": password,
      "Timestamp": timestamp,
      "CheckoutRequestID": checkoutRequestId
    };

    try {
      final response = await http.post(
        Uri.parse('${MpesaSecrets.baseUrl}/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
