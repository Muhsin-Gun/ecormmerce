import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Email verification service with OTP
/// Handles sending and verifying OTP codes through backend APIs.
class EmailVerificationService {
  static const String _defaultBaseUrl = 'http://localhost:3000';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'OTP_API_BASE_URL',
    defaultValue: '',
  );

  /// Send OTP to user's email.
  Future<bool> sendOTPtoEmail({
    required String email,
    required String userName,
  }) async {
    final response = await sendOTPtoEmailDetailed(email: email, userName: userName);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to send verification code');
    }
    return true;
  }

  Future<Map<String, dynamic>> sendOTPtoEmailDetailed({
    required String email,
    required String userName,
  }) async {
    return _postJson(
      path: '/auth/send-otp',
      body: {
        'email': email.trim(),
        'userName': userName.trim(),
      },
    );
  }

  /// Verify OTP code.
  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final response = await verifyOTPDetailed(email: email, otp: otp);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Invalid verification code');
    }
    return true;
  }

  Future<Map<String, dynamic>> verifyOTPDetailed({
    required String email,
    required String otp,
  }) async {
    return _postJson(
      path: '/auth/verify-otp',
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );
  }

  /// Resend OTP.
  Future<bool> resendOTP({
    required String email,
    required String userName,
  }) async {
    final response = await resendOTPDetailed(email: email, userName: userName);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to resend code');
    }
    return true;
  }

  Future<Map<String, dynamic>> resendOTPDetailed({
    required String email,
    required String userName,
  }) async {
    return _postJson(
      path: '/auth/send-otp',
      body: {
        'email': email.trim(),
        'userName': userName.trim(),
        'resend': true,
      },
    );
  }

  /// Check if email is verified.
  Future<bool> isEmailVerified(String email) async {
    final response = await _postJson(
      path: '/auth/verification-status',
      body: {'email': email.trim()},
    );
    return response['verified'] == true;
  }

  /// Get verification status.
  Future<Map<String, dynamic>> getVerificationStatus(String email) async {
    try {
      return await _postJson(
        path: '/auth/verification-status',
        body: {'email': email.trim()},
      );
    } catch (e) {
      return {'verified': false, 'status': 'error', 'error': e.toString()};
    }
  }

  Future<void> logClientEvent({
    required String eventName,
    required String email,
    Map<String, dynamic>? meta,
  }) async {
    await _postJson(
      path: '/auth/client-event',
      body: {
        'eventName': eventName,
        'email': email.trim(),
        'meta': meta ?? <String, dynamic>{},
      },
    );
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${_resolveBaseUrl()}$path');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      throw Exception(decoded['message'] ?? 'Request failed');
    } catch (e) {
      debugPrint('OTP API error on $path: $e');
      final raw = e.toString().toLowerCase();
      if (raw.contains('timed out')) {
        throw Exception(
          'Request timed out. Retry, or sign in with another account.',
        );
      }
      if (raw.contains('connection refused') ||
          raw.contains('failed host lookup') ||
          raw.contains('socketexception') ||
          raw.contains('clientexception')) {
        throw Exception(
          'Verification service is unreachable. Start the backend OTP server and try again.',
        );
      }
      rethrow;
    }
  }

  String _resolveBaseUrl() {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (kIsWeb) {
      final origin = Uri.base;
      final host = origin.host.isEmpty ? 'localhost' : origin.host;
      return '${origin.scheme}://$host:3000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return _defaultBaseUrl;
    }
  }
}
