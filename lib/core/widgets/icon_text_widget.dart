import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'icon_paths.dart';

class IconTextWidget extends StatelessWidget {
  final IconPaths? svgIcon;
  final IconPaths? imageIcon;
  final String text;
  final Color? iconColor;
  final Color textColor;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final double spacing;

  const IconTextWidget({
    super.key,
    this.svgIcon,
    this.imageIcon,
    required this.text,
    this.iconColor,
    this.textColor = Colors.white,
    this.iconSize = 120,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.spacing = 16,
  }) : assert(
         svgIcon != null || imageIcon != null,
         'Either svgIcon or imageIcon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(),
        SizedBox(height: spacing),
        _buildText(),
      ],
    );
  }

  Widget _buildIcon() {
    if (svgIcon != null) {
      return SvgPicture.asset(
        svgIcon!.path,
        width: iconSize,
        height: iconSize,
        colorFilter: iconColor != null
            ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
            : null,
      );
    } else if (imageIcon != null) {
      return Image.asset(imageIcon!.path, width: iconSize, height: iconSize);
    }
    return const SizedBox.shrink();
  }

  Widget _buildText() {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
        letterSpacing: 1.2,
      ),
    );
  }
}
