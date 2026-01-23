import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/constants.dart';
import 'cloudinary_service.dart';

/// Storage service for handling file uploads to Cloudinary
/// Includes image compression and optimization
class StorageService {
  // Singleton pattern
  StorageService._();
  static final StorageService instance = StorageService._();

  // ==================== IMAGE UPLOAD ====================

  /// Upload image to Cloudinary (replacing Firebase Storage for cost efficiency)
  /// Returns the Cloudinary secure URL
  Future<String> uploadImage({
    required File imageFile,
    required String path,
    String? fileName,
    bool compress = true,
  }) async {
    try {
      // Compress image locally first to save bandwidth
      File fileToUpload = imageFile;
      if (compress) {
        fileToUpload = await _compressImage(imageFile);
      }

      // Upload to Cloudinary instead of Firebase
      final String? downloadUrl = await CloudinaryService.uploadImageFile(fileToUpload);

      if (downloadUrl == null) {
        throw Exception('Cloudinary upload returned null');
      }

      // Clean up compressed file if it was created
      if (compress && fileToUpload.path != imageFile.path) {
        try {
          await fileToUpload.delete();
        } catch (e) {
          debugPrint('Silent error deleting temp file: $e');
        }
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String path,
    bool compress = true,
  }) async {
    final List<String> urls = [];

    for (final file in imageFiles) {
      try {
        final url = await uploadImage(
          imageFile: file,
          path: path,
          compress: compress,
        );
        urls.add(url);
      } catch (e) {
        debugPrint('Error uploading image: $e');
        // Continue with other images even if one fails
      }
    }

    return urls;
  }

  // ==================== IMAGE COMPRESSION ====================

  /// Compress image to reduce file size
  Future<File> _compressImage(File imageFile) async {
    try {
      // Read image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return imageFile; // Return original if decoding fails
      }

      // Resize if image is too large (max 1920px on longest side)
      const int maxDimension = 1920;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // Compress as JPEG with quality setting
      final compressedBytes = img.encodeJpg(
        image,
        quality: AppConstants.imageQuality,
      );

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  // ==================== SPECIFIC UPLOAD HELPERS ====================

  /// Upload product image
  Future<String> uploadProductImage(File imageFile, String productId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: '${AppConstants.productImagesPath}/$productId',
      compress: true,
    );
  }

  /// Upload multiple product images
  Future<List<String>> uploadProductImages(
    List<File> imageFiles,
    String productId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      path: '${AppConstants.productImagesPath}/$productId',
      compress: true,
    );
  }

  /// Upload user profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: '${AppConstants.userProfileImagesPath}/$userId',
      fileName: 'profile.jpg',
      compress: true,
    );
  }

  /// Upload chat image
  Future<String> uploadChatImage(File imageFile, String conversationId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: '${AppConstants.chatImagesPath}/$conversationId',
      compress: true,
    );
  }

  /// Upload review image
  Future<String> uploadReviewImage(File imageFile, String reviewId) async {
    return await uploadImage(
      imageFile: imageFile,
      path: '${AppConstants.productReviewImagesPath}/$reviewId',
      compress: true,
    );
  }

  /// Upload multiple review images
  Future<List<String>> uploadReviewImages(
    List<File> imageFiles,
    String reviewId,
  ) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      path: '${AppConstants.productReviewImagesPath}/$reviewId',
      compress: true,
    );
  }

  // ==================== DELETE (Cloudinary Stubs) ====================

  /// Delete file (Cloudinary limited on client side)
  Future<void> deleteFile(String downloadUrl) async {
    debugPrint('Cloudinary Delete requested (limited on client): $downloadUrl');
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> downloadUrls) async {
    for (final url in downloadUrls) {
      await deleteFile(url);
    }
  }

  /// Delete folder
  Future<void> deleteFolder(String path) async {
    debugPrint('Cloudinary Folder Delete requested: $path');
  }

  // ==================== HELPERS (Stubs) ====================

  /// Get file size
  Future<int> getFileSize(String downloadUrl) async {
    return 0;
  }

  /// Check if file exists
  Future<bool> fileExists(String downloadUrl) async {
    return true;
  }

  /// List all files
  Future<List<dynamic>> listFiles(String path) async {
    return [];
  }

  /// Get upload progress (Not supported for standard multipart)
  Stream<dynamic>? getUploadProgress(dynamic task) {
    return null;
  }

  /// Calculate upload progress
  double calculateProgress(dynamic snapshot) {
    return 100.0;
  }
}
