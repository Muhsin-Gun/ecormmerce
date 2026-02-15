import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _loaded = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    Future.delayed(const Duration(seconds: 2), () {
      if (!_loaded && mounted) _finish();
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _finish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Semantics(
                label: 'ProMarket opening animation',
                child: Lottie.asset(
                  'assets/animations/pro_market_splash.json',
                  controller: _controller,
                  repeat: false,
                  onLoaded: (composition) {
                    _loaded = true;
                    final ms = composition.duration.inMilliseconds;
                    _controller
                      ..duration = Duration(milliseconds: ms.clamp(2500, 3500))
                      ..forward().whenComplete(_finish);
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/splash_static.png',
                    width: 220,
                    height: 220,
                    semanticLabel: 'ProMarket Splash',
                  ),
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Semantics(
                button: true,
                label: 'Skip splash',
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
