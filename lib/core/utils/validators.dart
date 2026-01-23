import '../constants/constants.dart';

/// Input validation utilities for ProMarket
class Validators {
  // Prevent instantiation
  Validators._();

  // ==================== EMAIL VALIDATION ====================
  
  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    if (!AppConstants.emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // ==================== PASSWORD VALIDATION ====================
  
  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!value.contains(RegExp(r'[@$!%*?&]'))) {
      return 'Password must contain at least one special character (@\$!%*?&)';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // ==================== PHONE VALIDATION ====================
  
  /// Validates Kenyan phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and dashes
    final cleanedValue = value.replaceAll(RegExp(r'[\s-]'), '');
    
    if (!AppConstants.phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid Kenyan phone number';
    }
    
    return null;
  }

  /// Formats phone number to standard format
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Convert to 254 format
    if (digits.startsWith('0')) {
      return '254${digits.substring(1)}';
    } else if (digits.startsWith('254')) {
      return digits;
    } else if (digits.startsWith('+254')) {
      return digits.substring(1);
    }
    
    return digits;
  }

  // ==================== NAME VALIDATION ====================
  
  /// Validates name (first name, last name, etc.)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and spaces';
    }
    
    return null;
  }

  // ==================== PRODUCT VALIDATION ====================
  
  /// Validates product name
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    
    if (value.length < AppConstants.minProductNameLength) {
      return 'Product name must be at least ${AppConstants.minProductNameLength} characters';
    }
    
    if (value.length > AppConstants.maxProductNameLength) {
      return 'Product name must be less than ${AppConstants.maxProductNameLength} characters';
    }
    
    return null;
  }

  /// Validates product description
  static String? validateProductDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product description is required';
    }
    
    if (value.length < 10) {
      return 'Product description must be at least 10 characters';
    }
    
    if (value.length > AppConstants.maxProductDescriptionLength) {
      return 'Product description must be less than ${AppConstants.maxProductDescriptionLength} characters';
    }
    
    return null;
  }

  /// Validates product price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final price = double.tryParse(value);
    
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    
    if (price > 10000000) {
      return 'Price seems too high';
    }
    
    return null;
  }

  /// Validates product stock
  static String? validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }
    
    final stock = int.tryParse(value);
    
    if (stock == null) {
      return 'Please enter a valid stock number';
    }
    
    if (stock < 0) {
      return 'Stock cannot be negative';
    }
    
    if (stock > 1000000) {
      return 'Stock value seems too high';
    }
    
    return null;
  }

  // ==================== REVIEW VALIDATION ====================
  
  /// Validates review text
  static String? validateReview(String? value) {    if (value == null || value.isEmpty) {
      return 'Review is required';
    }
    
    if (value.length < 10) {
      return 'Review must be at least 10 characters';
    }
    
    if (value.length > AppConstants.maxReviewLength) {
      return 'Review must be less than ${AppConstants.maxReviewLength} characters';
    }
    
    return null;
  }

  // ==================== MESSAGE VALIDATION ====================
  
  /// Validates chat message
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (value.length > AppConstants.maxMessageLength) {
      return 'Message is too long';
    }
    
    return null;
  }

  // ==================== ADDRESS VALIDATION ====================
  
  /// Validates street address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    
    if (value.length > 200) {
      return 'Address is too long';
    }
    
    return null;
  }

  /// Validates city
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    
    if (value.length < 2) {
      return 'City name is too short';
    }
    
    if (value.length > 50) {
      return 'City name is too long';
    }
    
    return null;
  }

  /// Validates postal code
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postal code is required';
    }
    
    // Kenyan postal codes are 5 digits
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Please enter a valid 5-digit postal code';
    }
    
    return null;
  }

  // ==================== RATING VALIDATION ====================
  
  /// Validates rating value
  static String? validateRating(double? value) {
    if (value == null) {
      return 'Please provide a rating';
    }
    
    if (value < AppConstants.minRating || value > AppConstants.maxRating) {
      return 'Rating must be between ${AppConstants.minRating} and ${AppConstants.maxRating}';
    }
    
    return null;
  }

  // ==================== COUPON VALIDATION ====================
  
  /// Validates coupon code
  static String? validateCouponCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Coupon code is required';
    }
    
    // Coupon codes should be alphanumeric, 4-20 characters
    if (!RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(value.toUpperCase())) {
      return 'Invalid coupon code format';
    }
    
    return null;
  }

  // ==================== GENERAL VALIDATION ====================
  
  /// Validates required field
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validates maximum length
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'This field'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  /// Validates URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    
    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Validates number range
  static String? validateNumberRange(
    String? value,
    double min,
    double max, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }

  /// Validates amount (for price, etc)
  static String? validateAmount(String? value) {
    return validatePrice(value);
  }
}
