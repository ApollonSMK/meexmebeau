import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingOverlay extends StatefulWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = 'A analisar o rapport...'});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  final List<String> _loadingMessages = [
    'A ler o rapport facial...',
    'A analisar a condição da pele...',
    'A identificar preocupações...',
    'A consultar o catálogo...',
    'A gerar recomendações...',
    'Quase pronto...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Cycle through messages
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated AI icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: const [
                              AppTheme.primaryPurple,
                              AppTheme.accentPink,
                              AppTheme.primaryPurple,
                            ],
                            transform: GradientRotation(
                              _rotateController.value * 6.28,
                            ),
                          ).createShader(bounds);
                        },
                        child: const Icon(
                          Icons.face_retouching_natural,
                          size: 80,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Animated dots
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.primaryPurple.withValues(
                    alpha: 0.1,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple,
                  ),
                  minHeight: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _loadingMessages[_currentMessageIndex],
                key: ValueKey(_currentMessageIndex),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Inteligência Artificial a trabalhar...',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
