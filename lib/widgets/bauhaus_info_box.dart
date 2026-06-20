import 'package:flutter/material.dart';
import '../theme/bauhaus_theme.dart';

/// Labelled value block — used for order meta (table, totals, etc.).
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStriped ? BauhausTheme.lightGrey : BauhausTheme.white,
        borderRadius: BorderRadius.circular(BauhausTheme.radiusSm),
        border: Border.all(color: BauhausTheme.patternGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: BauhausTheme.body(
              size: 10,
              weight: FontWeight.w700,
              color: BauhausTheme.mediumGrey,
              spacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: valueStyle ??
                BauhausTheme.heading(size: 16, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Small pill tag — dietary labels, status badges.
class BauhausBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets padding;

  const BauhausBadge({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? BauhausTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(BauhausTheme.radiusPill),
      ),
      child: Text(
        label.toUpperCase(),
        style: BauhausTheme.body(
          size: 10,
          weight: FontWeight.w700,
          color: textColor ?? BauhausTheme.mediumGrey,
          spacing: 0.6,
        ),
      ),
    );
  }
}
