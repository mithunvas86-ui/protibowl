import 'package:flutter/material.dart';
import '../theme/bauhaus_theme.dart';

class BauhausInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isStriped;
  final TextStyle? valueStyle;

  const BauhausInfoBox({
    Key? key,
    required this.label,
    required this.value,
    this.isStriped = false,
    this.valueStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
        color: isStriped ? BauhausTheme.patternGrey : BauhausTheme.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BauhausTheme.mediumGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BauhausTheme.primaryBlack,
                ),
          ),
        ],
      ),
    );
  }
}

class BauhausBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsets padding;

  const BauhausBadge({
    Key? key,
    required this.label,
    this.backgroundColor = BauhausTheme.accentRed,
    this.textColor = BauhausTheme.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
