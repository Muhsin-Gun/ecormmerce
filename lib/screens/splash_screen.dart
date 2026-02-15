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

    Timer(const Duration(milliseconds: 2800), () {
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080E1C), Color(0xFF172750), Color(0xFF3A1D82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                child: Lottie.asset(
                  'assets/animations/pro_market_splash.json',
                  controller: _controller,
                  repeat: false,
                  onLoaded: (composition) {
                    _loaded = true;
                    _controller
                      ..duration = Duration(
                        milliseconds: composition.duration.inMilliseconds.clamp(1600, 2200),
                      )
                      ..forward().whenComplete(_finish);
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/splash_static.png',
                    width: 200,
                    height: 200,
                  ),
                  width: 220,
                  height: 220,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ProMarket',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _loaded ? 'Everything you love, delivered fast.' : 'Loading your store…',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
