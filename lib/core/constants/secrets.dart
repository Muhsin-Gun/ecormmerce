class MpesaSecrets {
  static const String env = 'sandbox'; // 'sandbox' or 'production'
  static const String consumerKey = 'tqRnGX8FUN1qHYyIoC4VBpH7AOl855kTltvtUARby0tKKwe1';
  static const String consumerSecret = 'nkesbMKa7USM0GVUBSqjDd0SO2mCv5Gp4XyGAzFnzSjfL9acJjGCNIouBkfUn8tv';
  static const String shortCode = '174379';
  static const String passKey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const String callbackUrl = 'https://unimpertinently-plastered-liliana.ngrok-free.dev/payment/mpesa/callback';
  
  static const String sandboxBaseUrl = 'https://sandbox.safaricom.co.ke';
  static const String productionBaseUrl = 'https://api.safaricom.co.ke';
  
  static String get baseUrl => env == 'sandbox' ? sandboxBaseUrl : productionBaseUrl;
}
