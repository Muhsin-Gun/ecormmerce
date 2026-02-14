import 'package:flutter_test/flutter_test.dart';

import 'package:ecormmerce/auth/services/otp_policy.dart';

void main() {
  group('OtpPolicy', () {
    test('applies progressive cooldown', () {
      expect(OtpPolicy.cooldownForResendCount(0), 30);
      expect(OtpPolicy.cooldownForResendCount(1), 60);
      expect(OtpPolicy.cooldownForResendCount(2), 120);
      expect(OtpPolicy.cooldownForResendCount(20), 120);
    });

    test('caps resends per session', () {
      expect(OtpPolicy.remainingResends(0), 3);
      expect(OtpPolicy.remainingResends(1), 2);
      expect(OtpPolicy.remainingResends(2), 1);
      expect(OtpPolicy.remainingResends(3), 0);
      expect(OtpPolicy.remainingResends(99), 0);
    });

    test('formats accessible countdown label', () {
      expect(OtpPolicy.formatCountdownLabel(29), 'Resend code in 00:29');
      expect(OtpPolicy.formatCountdownLabel(90), 'Resend code in 01:30');
      expect(OtpPolicy.formatCountdownLabel(-1), 'Resend code in 00:00');
    });

    test('uses 12 second timeout policy', () {
      expect(OtpPolicy.timeoutSeconds, 12);
    });
  });
}

