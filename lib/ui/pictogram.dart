import 'package:flutter/widgets.dart';

/// A pictogram from the bundled monochrome font, drawn in [color]: the same
/// shape on every phone, unlike the system's own emoji.
class Pictogram extends StatelessWidget {
  const Pictogram(this.glyph, {super.key, required this.size, this.color});

  /// The bundled font family, declared in `pubspec.yaml`.
  static const fontFamily = 'NotoEmoji';

  /// A single character of the font.
  final String glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    glyph,
    style: TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      color: color,
      height: 1.1,
      fontWeight: FontWeight.w500,
    ),
  );
}
