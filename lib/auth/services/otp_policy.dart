class OtpPolicy {
  OtpPolicy._();

  static const int timeoutSeconds = 12;
  static const int maxResendsPerSession = 3;
  static const List<int> cooldowns = [30, 60, 120];

  static int cooldownForResendCount(int resendCount) {
    final clamped = resendCount.clamp(0, cooldowns.length - 1);
    return cooldowns[clamped];
  }

  static int remainingResends(int resendCount) {
    final value = maxResendsPerSession - resendCount;
    return value < 0 ? 0 : value;
  }

  static String formatCountdownLabel(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final secs = safe % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return 'Resend code in $mm:$ss';
  }
}

