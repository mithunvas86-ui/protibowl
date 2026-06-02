import 'package:flutter/material.dart';
import '../theme/bauhaus_theme.dart';

class BauhausCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double? width;

  const BauhausCategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: width,
        decoration: BoxDecoration(
          color: isSelected ? BauhausTheme.accentRed : BauhausTheme.white,
          border: Border.all(
            color: BauhausTheme.primaryBlack,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? BauhausTheme.white : BauhausTheme.primaryBlack,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
