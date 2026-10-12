import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_images.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/faded_image.dart';
import '../widgets/motion/entrance.dart';
import '../widgets/motion/rising_embers.dart';

/// Splash: Maa Durga artwork and the app's name while the pandal list loads,
/// or a retry if it can't be read.
///
/// On arrival the artwork fades in while slowly settling from a slight zoom,
/// embers rise from the lamps, the marigolds lift into place and the name
/// appears line by line.
class StartupScreen extends StatefulWidget {
  const StartupScreen.loading({super.key}) : onRetry = null;

  const StartupScreen.error({super.key, required VoidCallback this.onRetry});

  final VoidCallback? onRetry;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  // Pixel sizes of the splash crops.
  static const _artAspect = 1040 / 1900;
  static const _marigoldAspect = 1040 / 248;

  late final _intro = AnimationController(
    vsync: this,
    duration: AppMotion.splashIntro,
  );

  /// The artwork's reveal: a quick fade, and a slow settle from 6% larger.
  late final _artFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.3, curve: Curves.easeOut),
  );
  late final _artScale = _intro.drive(
    Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.isCompleted) return;
    _precacheLaunchImages();
    if (AppMotion.reduced(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  /// Uses the splash's idle time to decode the images the app opens on.
  void _precacheLaunchImages() {
    for (final asset in AppImages.shownAtLaunch) {
      // Decorative: on failure the image simply loads when shown.
      precacheImage(AssetImage(asset), context, onError: (_, _) {});
    }
  }

  @override
  void dispose() {
    // The splash art is the app's largest image (about 8 MB decoded) and
    // isn't shown again, so don't keep it cached for the whole session.
    for (final asset in AppImages.splashOnly) {
      AssetImage(asset).evict();
    }
    _artFade.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            // Portrait phones show the artwork edge to edge; wider screens
            // show it as a centred panel that fades into the background.
            final artWidth = math.min(width, height * 0.8 * _artAspect);
            final artHeight = math.min(artWidth / _artAspect, height * 0.82);
            final panel = artWidth < width - 1;
            final marigoldWidth = math.min(width, 640.0);
            final marigoldHeight = marigoldWidth / _marigoldAspect;

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: (width - artWidth) / 2,
                  width: artWidth,
                  height: artHeight,
                  child: FadeTransition(
                    opacity: _artFade,
                    child: ScaleTransition(
                      scale: _artScale,
                      alignment: Alignment.topCenter,
                      child: FadedImage(
                        asset: AppImages.splashArt,
                        alignment: Alignment.topCenter,
                        fadeBottom: 0.4,
                        fadeLeft: panel ? 0.18 : 0,
                        fadeRight: panel ? 0.18 : 0,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: RisingEmbers(progress: _intro)),
                Positioned(
                  bottom: 0,
                  left: (width - marigoldWidth) / 2,
                  width: marigoldWidth,
                  height: marigoldHeight,
                  child: Entrance(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 700),
                    offset: const Offset(0, 28),
                    child: FadedImage(
                      asset: AppImages.splashMarigolds,
                      alignment: Alignment.bottomCenter,
                      fadeTop: 0.5,
                      fadeLeft: marigoldWidth < width ? 0.15 : 0,
                      fadeRight: marigoldWidth < width ? 0.15 : 0,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: height * 0.38,
                  bottom: marigoldHeight * 0.5,
                  child: SafeArea(
                    top: false,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomCenter,
                      child: _Branding(
                        titleSize: (width * 0.135).clamp(40.0, 64.0),
                        onRetry: widget.onRetry,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding({required this.titleSize, required this.onRetry});

  final double titleSize;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onRetry = this.onRetry;

    // Each line rises into place a beat after the one before.
    Widget reveal(int step, Widget child, {double beginScale = 1}) => Entrance(
      delay: Duration(milliseconds: 350 + step * 130),
      duration: const Duration(milliseconds: 650),
      offset: const Offset(0, 14),
      beginScale: beginScale,
      child: child,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        reveal(
          0,
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: AppColors.goldGradient.createShader,
            child: Text(
              'Durga\nDarshan',
              semanticsLabel: 'Durga Darshan',
              textAlign: TextAlign.center,
              style: AppTypography.serif(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.02,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        reveal(
          1,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Rule(),
              Text(
                ' AHMEDABAD ',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 6,
                ),
              ),
              const _Rule(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        reveal(
          2,
          const Icon(Icons.spa_rounded, color: AppColors.goldBright, size: 28),
          beginScale: 0.4,
        ),
        const SizedBox(height: 12),
        reveal(
          3,
          Text(
            'শুভ শারদীয়া',
            semanticsLabel: 'Shubho Sharodiya',
            style: AppTypography.bengali(
              fontSize: 30,
              color: AppColors.goldLight,
              height: 1.3,
            ),
          ),
        ),
        reveal(
          4,
          ExcludeSemantics(
            child: Text(
              'Shubho Sharodiya',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.onMaroon,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 22),
          Semantics(
            liveRegion: true,
            child: Text(
              'The pandal list couldn’t be loaded.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.onMaroon),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldBright,
              foregroundColor: AppColors.maroonDeep,
            ),
            child: const Text('Try again'),
          ),
        ],
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(width: 14, height: 1.2, color: AppColors.goldLight);
  }
}
