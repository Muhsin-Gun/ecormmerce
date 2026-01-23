import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'ddwfkeess';
  static const String _uploadPreset = 'ecommerce';
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image file to Cloudinary
  static Future<String?> uploadImage(XFile file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      request.fields['upload_preset'] = _uploadPreset;
      
      // Add file
      // For web, we might need bytes, for mobile read from path
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['secure_url'] as String;
      } else {
        debugPrint('Cloudinary Upload Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Error: $e');
      return null;
    }
  }
}
