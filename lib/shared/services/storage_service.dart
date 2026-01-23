import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/constants.dart';

/// Storage service for handling file uploads to Firebase Storage
/// Includes image compression and optimization
class StorageService {
  // Singleton pattern
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== IMAGE UPLOAD ====================

  /// Upload image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required File imageFile,
    required String path,
    String? fileName,
    bool compress = true,
  }) async {
    try {
      // Compress image if enabled
      File fileToUpload = imageFile;
      if (compress) {
        fileToUpload = await _compressImage(imageFile);
      }

      // Generate file name if not provided
      final String uploadFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}.jpg';

      // Create reference
      final Reference ref = _storage.ref().child(path).child(uploadFileName);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up compressed file if it was created
      if (compress && fileToUpload.path != imageFile.path) {
        await fileToUpload.delete();
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
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

  // ==================== DELETE ====================

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> downloadUrls) async {
    for (final url in downloadUrls) {
      try {
        await deleteFile(url);
      } catch (e) {
        debugPrint('Error deleting file: $e');
        // Continue even if one fails
      }
    }
  }

  /// Delete folder (all files in a path)
  Future<void> deleteFolder(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      final ListResult result = await ref.listAll();

      // Delete all files
      for (final Reference fileRef in result.items) {
        await fileRef.delete();
      }

      // Recursively delete subfolders
      for (final Reference folderRef in result.prefixes) {
        await deleteFolder(folderRef.fullPath);
      }
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      rethrow;
    }
  }

  // ==================== HELPERS ====================

  /// Generate random string for file names
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length],
    ).join();
  }

  /// Get file size in bytes
  Future<int> getFileSize(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all files in a path
  Future<List<Reference>> listFiles(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      final ListResult result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  /// Get upload progress stream
  Stream<TaskSnapshot> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents;
  }

  /// Calculate upload progress percentage
  double calculateProgress(TaskSnapshot snapshot) {
    if (snapshot.totalBytes == 0) return 0.0;
    return (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
  }
}
