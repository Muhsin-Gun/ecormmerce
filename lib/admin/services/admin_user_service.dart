import 'package:cloud_functions/cloud_functions.dart';

class AdminUserService {
  AdminUserService._();
  static final AdminUserService instance = AdminUserService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> deleteUserCompletely(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) {
      throw Exception('Invalid user id.');
    }

    try {
      final callable = _functions.httpsCallable(
        'adminDeleteUser',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 25),
        ),
      );

      final result = await callable.call(<String, dynamic>{
        'userId': trimmedUserId,
      });

      final response = _asMap(result.data);
      if (response['success'] != true) {
        final message = response['message']?.toString();
        throw Exception(message ?? 'Could not delete user.');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not delete user right now.');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
