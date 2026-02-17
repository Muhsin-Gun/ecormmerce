import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';

/// Theme Provider for managing dark/light mode
/// Syncs theme preference to SharedPreferences and Firestore
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false; // Light mode by default
  final bool _isLoading = false;
  String? _userId;
  bool _isInitialized = false;
  int _themeRevision = 0;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== INITIALIZATION ====================

  /// Initialize theme from SharedPreferences
  Future<void> init({String? userId}) async {
    if (_isInitialized) {
      if (userId != null) {
        setUserId(userId);
      }
      return;
    }

    _isInitialized = true;
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
      _isDarkMode = prefs.getBool(AppConstants.prefThemeMode) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme from local: $e');
    }
  }

  /// Load theme preference from Firestore (for logged-in users)
  Future<void> _loadThemeFromFirestore() async {
    if (_userId == null) return;
    final requestRevision = _themeRevision;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .get();

      // Local theme changed while this read was in flight.
      if (requestRevision != _themeRevision) {
        return;
      }

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('darkMode')) {
          final remoteDarkMode = data['darkMode'] as bool? ?? false;
          final shouldNotify = remoteDarkMode != _isDarkMode;
          _isDarkMode = remoteDarkMode;

          // Save to local as well
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.prefThemeMode, _isDarkMode);

          if (shouldNotify) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading theme from Firestore: $e');
    }
  }

  // ==================== TOGGLE THEME ====================

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    await setThemeMode(!_isDarkMode);
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _themeRevision++;
    _isDarkMode = isDark;
    notifyListeners();

    unawaited(_persistThemePreference(expectedRevision: _themeRevision));
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

  Future<void> _persistThemePreference({required int expectedRevision}) async {
    await _saveThemeToLocal(expectedRevision: expectedRevision);

    if (_userId != null) {
      await _saveThemeToFirestore(expectedRevision: expectedRevision);
    }
  }

  /// Save theme to SharedPreferences
  Future<void> _saveThemeToLocal({required int expectedRevision}) async {
    if (expectedRevision != _themeRevision) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (expectedRevision != _themeRevision) return;
      await prefs.setBool(AppConstants.prefThemeMode, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme to local: $e');
    }
  }

  /// Save theme to Firestore
  Future<void> _saveThemeToFirestore({required int expectedRevision}) async {
    if (_userId == null) return;
    if (expectedRevision != _themeRevision) return;

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
    if (_userId == userId) return;
    _userId = userId;

    if (_userId != null) {
      // Load theme from Firestore for the logged-in user
      unawaited(_loadThemeFromFirestore());
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
