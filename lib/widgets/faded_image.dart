import 'package:flutter/material.dart';

/// A decorative image whose given edges fade to transparent, so a crop from
/// the redesign blends into the gradient behind it.
class FadedImage extends StatelessWidget {
  const FadedImage({
    super.key,
    required this.asset,
    this.fadeLeft = 0,
    this.fadeRight = 0,
    this.fadeTop = 0,
    this.fadeBottom = 0,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String asset;

  /// Fraction of the width or height over which each edge fades out.
  final double fadeLeft;
  final double fadeRight;
  final double fadeTop;
  final double fadeBottom;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    image = _fade(
      image,
      Alignment.centerLeft,
      Alignment.centerRight,
      fadeLeft,
      fadeRight,
    );
    image = _fade(
      image,
      Alignment.topCenter,
      Alignment.bottomCenter,
      fadeTop,
      fadeBottom,
    );
    return ExcludeSemantics(child: image);
  }

  static Widget _fade(
    Widget child,
    Alignment begin,
    Alignment end,
    double start,
    double finish,
  ) {
    if (start <= 0 && finish <= 0) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: begin,
        end: end,
        colors: const [
          Color(0x00FFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: [0, start, 1 - finish, 1],
      ).createShader(bounds),
      child: child,
    );
  }
}
