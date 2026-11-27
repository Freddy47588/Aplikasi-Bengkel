import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SessionSplash extends StatelessWidget {
  const SessionSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'BengkelKu. Aplikasi Manajemen Bengkel. Memuat akun.',
      child: Scaffold(
        backgroundColor: AppColors.splashBg,
        body: SizedBox.expand(
          child: const ExcludeSemantics(child: SplashArtwork()),
        ),
      ),
    );
  }
}

class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 640;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.splashBg),
        Positioned(
          top: -size.height * 0.14,
          left: -size.width * 0.12,
          right: -size.width * 0.12,
          height: size.height * 0.56,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.24),
                    AppColors.secondary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: (size.height * 0.34).clamp(110.0, 260.0),
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.34,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xB8000000), Colors.black],
                  stops: [0.0, 0.42, 1.0],
                ).createShader(rect),
                child: Image.asset(
                  'assets/illustrations/splash_everyday.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: compact ? 16 : 28,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: compact ? 74 : 88,
                  height: compact ? 74 : 88,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.carbonElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.42),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.22),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/branding/logo_v2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 14 : 20),
                const Text(
                  'BengkelKu',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Workshop Management',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFB4BCC8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.15,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: 148,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          children: [
                            Container(
                              height: 5,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.62,
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.accentLight,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Memuat sesi bengkel...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8F9AA9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
