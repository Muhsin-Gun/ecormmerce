import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';

/// Theme Provider for managing dark/light mode
/// Syncs theme preference to SharedPreferences and Firestore
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Dark mode first
  bool _isLoading = false;
  String? _userId;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== INITIALIZATION ====================

  /// Initialize theme from SharedPreferences
  Future<void> init({String? userId}) async {
    _userId = userId;
    await _loadThemeFromLocal();
    
    // If user is logged in, sync from Firestore
    if (_userId != null) {
      await _loadThemeFromFirestore();
    }
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemeFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(AppConstants.prefThemeMode) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme from local: $e');
    }
  }

  /// Load theme preference from Firestore (for logged-in users)
  Future<void> _loadThemeFromFirestore() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('darkMode')) {
          _isDarkMode = data['darkMode'] as bool? ?? true;
          
          // Save to local as well
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.prefThemeMode, _isDarkMode);
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading theme from Firestore: $e');
    }
  }

  // ==================== TOGGLE THEME ====================

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Save to local storage
    await _saveThemeToLocal();

    // Save to Firestore if user is logged in
    if (_userId != null) {
      await _saveThemeToFirestore();
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;
    notifyListeners();

    await _saveThemeToLocal();

    if (_userId != null) {
      await _saveThemeToFirestore();
    }
  }

  /// Set dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(true);
  }

  /// Set light mode
  Future<void> setLightMode() async {
    await setThemeMode(false);
  }

  // ==================== PERSISTENCE ====================

  /// Save theme to SharedPreferences
  Future<void> _saveThemeToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefThemeMode, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme to local: $e');
    }
  }

  /// Save theme to Firestore
  Future<void> _saveThemeToFirestore() async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .update({
        'darkMode': _isDarkMode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving theme to Firestore: $e');
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Update user ID when user logs in
  void setUserId(String? userId) {
    _userId = userId;
    
    if (_userId != null) {
      // Load theme from Firestore for the logged-in user
      _loadThemeFromFirestore();
    }
  }

  /// Clear user data on logout
  void clearUser() {
    _userId = null;
  }

  // ==================== SYSTEM THEME ====================

  /// Get system brightness
  static Brightness getSystemBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }

  /// Check if system is in dark mode
  static bool isSystemDarkMode(BuildContext context) {
    return getSystemBrightness(context) == Brightness.dark;
  }

  /// Use system theme
  Future<void> useSystemTheme(BuildContext context) async {
    final isSystemDark = isSystemDarkMode(context);
    await setThemeMode(isSystemDark);
  }
}
