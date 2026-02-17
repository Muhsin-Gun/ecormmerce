import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MpesaService {
  static final MpesaService instance = MpesaService._();
  static const String _localMpesaBaseUrl =
      String.fromEnvironment('MPESA_LOCAL_BASE_URL');

  MpesaService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Initiate STK Push through Firebase Cloud Functions.
  /// Falls back to local backend only in debug mode.
  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    final payload = <String, dynamic>{
      'phoneNumber': _normalizePhone(phoneNumber),
      'amount': amount,
      'accountReference': accountReference,
      'transactionDesc': transactionDesc,
    };

    try {
      final callable = _functions.httpsCallable(
        'mpesaStkPush',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 35),
        ),
      );
      final result = await callable.call(payload);
      final data = _asMap(result.data);
      return _normalizeInitiateResponse(data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        final fallback = await _initiateStkPushViaLocalServer(payload);
        if (fallback['success'] == true) {
          return fallback;
        }
      }
      return {
        'success': false,
        'error': e.message ?? 'M-Pesa backend unavailable (${e.code}).',
      };
    } catch (e) {
      if (kDebugMode) {
        final fallback = await _initiateStkPushViaLocalServer(payload);
        if (fallback['success'] == true) {
          return fallback;
        }
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Optional status query endpoint if implemented in Cloud Functions.
  Future<Map<String, dynamic>> queryTransactionStatus(
    String checkoutRequestId,
  ) async {
    try {
      final callable = _functions.httpsCallable(
        'mpesaQueryTransactionStatus',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 20),
        ),
      );
      final result = await callable.call({
        'checkoutRequestID': checkoutRequestId,
      });
      return _asMap(result.data);
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Unable to query transaction status.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  String _normalizePhone(String rawPhone) {
    var phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    phone = phone.replaceAll('+', '');
    if (phone.startsWith('0')) {
      phone = '254${phone.substring(1)}';
    }
    if (phone.startsWith('7') && phone.length == 9) {
      phone = '254$phone';
    }
    return phone;
  }

  Map<String, dynamic> _normalizeInitiateResponse(Map<String, dynamic> data) {
    final checkoutRequestId = data['checkoutRequestID']?.toString() ??
        data['CheckoutRequestID']?.toString();
    final merchantRequestId = data['merchantRequestID']?.toString() ??
        data['MerchantRequestID']?.toString();
    final responseDescription = data['responseDescription']?.toString() ??
        data['ResponseDescription']?.toString() ??
        data['CustomerMessage']?.toString();
    final responseCode =
        data['responseCode']?.toString() ?? data['ResponseCode']?.toString();
    final errorMessage = data['error']?.toString() ??
        data['message']?.toString() ??
        data['errorMessage']?.toString();

    final success = data['success'] == true ||
        responseCode == '0' ||
        (checkoutRequestId != null && checkoutRequestId.isNotEmpty);

    return {
      'success': success,
      'checkoutRequestID': checkoutRequestId,
      'merchantRequestID': merchantRequestId,
      'responseDescription': responseDescription,
      if (!success) 'error': errorMessage ?? 'M-Pesa request failed.',
    };
  }

  Future<Map<String, dynamic>> _initiateStkPushViaLocalServer(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_localServerUrl()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _asMap(json.decode(response.body));
        return _normalizeInitiateResponse(data);
      }

      final decoded =
          response.body.isNotEmpty ? _asMap(json.decode(response.body)) : {};
      return {
        'success': false,
        'error': decoded['error']?.toString() ??
            'Local M-Pesa backend error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  String _localServerUrl() {
    if (_localMpesaBaseUrl.trim().isNotEmpty) {
      final base = _localMpesaBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
      return '$base/mpesaStkPush';
    }
    if (kIsWeb) {
      final origin = Uri.base;
      final host = origin.host.isEmpty ? 'localhost' : origin.host;
      return '${origin.scheme}://$host:3000/mpesaStkPush';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/mpesaStkPush';
    }
    return 'http://localhost:3000/mpesaStkPush';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
