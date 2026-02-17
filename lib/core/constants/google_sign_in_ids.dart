class GoogleSignInIds {
  const GoogleSignInIds._();

  // Android package configured in Firebase for this Flutter app.
  static const String androidPackageName = 'com.example.ecormmerce';

  // Web OAuth client ID (client_type 3 in google-services.json).
  // This must be used as serverClientId on Android for Firebase Google sign-in.
  static const String webClientId =
      '419781318218-7qbse535lcfm5fmum578hvh3e86bljlg.apps.googleusercontent.com';

  static const String iosClientId =
      '419781318218-mpdpcpg5805cnsgii0soeql25chhrs7l.apps.googleusercontent.com';
}
