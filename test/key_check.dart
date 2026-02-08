
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// User provided keys
const consumerKey = 'QycTPzIwPxkNsSWihn5Yv476JKjrsXzppgC97OQjxbJ129zg';
const consumerSecret = 'FoWdxEGkTjgGe1p2yQwhGfWEFjYPQwOqiRmudqGa7eb1qsTrgGmeOLqIbCTFFj9M';

void main() {
  test('M-Pesa Env Check', () async {
    print('Checking Keys against SANDBOX...');
    await checkAuth('https://sandbox.safaricom.co.ke');

    print('\nChecking Keys against PRODUCTION...');
    await checkAuth('https://api.safaricom.co.ke');
  });
}

Future<void> checkAuth(String baseUrl) async {
  final credentials = '$consumerKey:$consumerSecret';
  final bytes = utf8.encode(credentials);
  final base64Credentials = base64.encode(bytes);

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {
        'Authorization': 'Basic $base64Credentials',
      },
    );

    print('URL: $baseUrl');
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESS! Keys are for this environment.');
    } else {
      print('❌ FAILED: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
