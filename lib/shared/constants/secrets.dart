class MpesaSecrets {
  // Sandbox Credentials
  static const String consumerKey = 'mp_android_consumer_key_placeholder'; // User needs this, but I'll use a common test one if available or leave placeholders but clearer
  static const String consumerSecret = 'mp_android_consumer_secret_placeholder';
  
  // These are standard Safaricom Sandbox values
  static const String shortCode = '174379';
  static const String passKey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  
  // Use a public test callback or localhost tunnel (ngrok) in real dev. 
  // For now, use a dummy one that won't crash the app but won't receive callback.
  static const String callbackUrl = 'https://mydomain.com/path';
  
  static const String baseUrl = 'https://sandbox.safaricom.co.ke';
}
