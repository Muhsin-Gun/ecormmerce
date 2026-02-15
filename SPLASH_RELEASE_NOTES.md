# ProMarket splash and release notes

The app now uses a native static splash (`assets/images/splash_static.png`) for instant cold-start paint, then transitions to a Flutter Lottie splash (`assets/animations/pro_market_splash.json`). The animation is one-shot with a clamped 2.5s–3.5s duration, includes Skip, auto-fallback after 2s if Lottie fails to load, and force-completes at 6s to avoid blocking app startup.

Replace `assets/animations/pro_market_splash.json` with your final brand-exported Lottie if needed (same filename/path). Keep visual assets under `assets/icons/` and `assets/images/` so native splash and launcher generation commands continue to work.

## Signed release build steps

```bash
python3 tools/generate_brand_assets.py
keytool -genkey -v -keystore ~/pro_market_keystore.jks -alias promarket_key -keyalg RSA -keysize 2048 -validity 10000
cp android/key.properties.example android/key.properties
# fill real passwords/path in android/key.properties
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons:main
flutter build apk --release
```

Output APK: `build/app/outputs/flutter-apk/app-release.apk`.

Note: PNG assets are generated from `tools/generate_brand_assets.py` to keep pull requests text-only (no binary-file PR blocking).
