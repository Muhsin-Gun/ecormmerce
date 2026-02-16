import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    Timer(const Duration(milliseconds: 2600), _finish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted || _finished) return;
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
            colors: [Color(0xFF051326), Color(0xFF0B2B4D), Color(0xFF136C86)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final pulse = 0.95 + (math.sin(t * math.pi * 2) * 0.06);
              final orbitAngle = t * math.pi * 2;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: orbitAngle,
                          child: Container(
                            width: 176,
                            height: 176,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: -orbitAngle * 0.6,
                          child: Container(
                            width: 138,
                            height: 138,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 110 + math.cos(orbitAngle) * 84,
                          top: 110 + math.sin(orbitAngle) * 84,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF93C5FD),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 110 + math.cos(orbitAngle + math.pi) * 84,
                          top: 110 + math.sin(orbitAngle + math.pi) * 84,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ProMarket',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preparing your storefront...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
