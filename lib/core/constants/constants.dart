/// ProMarket App Constants
/// Central location for all app-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== APP INFO ====================
  
  static const String appName = 'ProMarket';
  static const String appTagline = 'Buy. Sell. Manage. Anywhere.';
  static const String appVersion = '1.0.0';

  // ==================== FIRESTORE COLLECTIONS ====================
  
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String cartsCollection = 'carts';
  static const String wishlistsCollection = 'wishlists';
  static const String messagesCollection = 'messages';
  static const String conversationsCollection = 'conversations';
  static const String reviewsCollection = 'reviews';
  static const String categoriesCollection = 'categories';
  static const String couponsCollection = 'coupons';
  static const String transactionsCollection = 'transactions';
  static const String notificationsCollection = 'notifications';
  static const String auditLogsCollection = 'audit_logs';

  // ==================== STORAGE PATHS ====================
  
  static const String productImagesPath = 'products';
  static const String userProfileImagesPath = 'users/profiles';
  static const String chatImagesPath = 'chat/images';
  static const String productReviewImagesPath = 'reviews';

  // ==================== USER ROLES ====================
  
  static const String roleClient = 'client';
  static const String roleEmployee = 'employee';
  static const String roleAdmin = 'admin';

  // ==================== ROLE STATUS ====================
  
  static const String roleStatusPending = 'pending';
  static const String roleStatusApproved = 'approved';
  static const String roleStatusSuspended = 'suspended';
  static const String roleStatusRejected = 'rejected';

  // ==================== ORDER STATUS ====================
  
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusPacked = 'packed';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';
  static const String orderStatusRefunded = 'refunded';

  // ==================== PAYMENT STATUS ====================
  
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusProcessing = 'processing';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // ==================== PAYMENT METHODS ====================
  
  static const String paymentMethodMpesa = 'mpesa';
  static const String paymentMethodCard = 'card';
  static const String paymentMethodCash = 'cash';

  // ==================== MESSAGE TYPES ====================
  
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeOrder = 'order';
  static const String messageTypeSystem = 'system';

  // ==================== PAGINATION ====================
  
  static const int productsPerPage = 20;
  static const int ordersPerPage = 10;
  static const int messagesPerPage = 50;
  static const int usersPerPage = 20;
  static const int reviewsPerPage = 10;

  // ==================== VALIDATION ====================
  
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int minProductNameLength = 3;
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 2000;
  static const int maxReviewLength = 500;
  static const int maxMessageLength = 1000;

  // ==================== IMAGE CONSTRAINTS ====================
  
  static const int maxImageSizeMB = 5;
  static const int maxImagesPerProduct = 5;
  static const int maxImagesPerReview = 3;
  static const int imageQuality = 85; // JPEG quality 0-100

  // ==================== MPESA CONFIGURATION ====================
  
  // NOTE: In production, these should come from environment variables
  // For development, we'll use sandbox values
  static const String mpesaConsumerKey = String.fromEnvironment(
    'MPESA_CONSUMER_KEY',
    defaultValue: '', // Add sandbox key here
  );
  static const String mpesaConsumerSecret = String.fromEnvironment(
    'MPESA_CONSUMER_SECRET',
    defaultValue: '', // Add sandbox secret here
  );
  static const String mpesaShortCode = String.fromEnvironment(
    'MPESA_SHORT_CODE',
    defaultValue: '', // Add sandbox shortcode
  );
  static const String mpesaPasskey = String.fromEnvironment(
    'MPESA_PASSKEY',
    defaultValue: '', // Add sandbox passkey
  );
  static const String mpesaCallbackUrl = String.fromEnvironment(
    'MPESA_CALLBACK_URL',
    defaultValue: '', // Add your Cloud Function URL
  );

  // ==================== API ENDPOINTS ====================
  
  static const String mpesaSandboxUrl = 'https://sandbox.safaricom.co.ke';
  static const String mpesaProductionUrl = 'https://api.safaricom.co.ke';
  
  // Use sandbox by default
  static const String mpesaBaseUrl = mpesaSandboxUrl;

  // ==================== CACHE ====================
  
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration productCacheExpiry = Duration(hours: 6);
  static const Duration userCacheExpiry = Duration(hours: 12);

  // ==================== TIMEOUTS ====================
  
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 2);
  static const Duration mpesaTimeout = Duration(seconds: 60);

  // ==================== PREFERENCES KEYS ====================
  
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefFirstLaunch = 'first_launch';
  static const String prefLastSync = 'last_sync';

  // ==================== NOTIFICATION CHANNELS ====================
  
  static const String notificationChannelOrders = 'orders';
  static const String notificationChannelMessages = 'messages';
  static const String notificationChannelPromotions = 'promotions';
  static const String notificationChannelGeneral = 'general';

  // ==================== ERROR MESSAGES ====================
  
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorPermission = 'You don\'t have permission for this action.';
  static const String errorNotFound = 'Resource not found.';
  static const String errorValidation = 'Please check your input and try again.';

  // ==================== SUCCESS MESSAGES ====================
  
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successPaymentComplete = 'Payment completed successfully!';
  static const String successProductAdded = 'Product added successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successPasswordChanged = 'Password changed successfully!';

  // ==================== REGEX PATTERNS ====================
  
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp phoneRegex = RegExp(
    r'^(?:254|\+254|0)([71](?:(?:[0-9][0-9])|(?:0[0-8])|(4[0-1]))[0-9]{6})$',
  );
  
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // ==================== CATEGORIES ====================
  
  static const List<String> defaultCategories = [
    'Electronics',
    'Fashion',
    'Home & Living',
    'Beauty & Health',
    'Sports & Outdoors',
    'Books & Media',
    'Toys & Games',
    'Food & Beverages',
    'Automotive',
    'Office Supplies',
  ];
  
  static const List<String> productCategories = defaultCategories;

  // ==================== RATING ====================
  
  static const double minRating = 0.0;
  static const double maxRating = 5.0;
  static const double ratingStep = 0.5;

  // ==================== CURRENCY ====================
  
  static const String currencyCode = 'KES';
  static const String currencySymbol = 'KSh';

  // ==================== DATE FORMATS ====================
  
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatLong = 'MMMM dd, yyyy';
  static const String dateFormatFull = 'EEEE, MMMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // ==================== ANIMATIONS ====================
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
}
