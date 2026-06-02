import 'package:flutter/material.dart';
import '../theme/bauhaus_theme.dart';

class BauhausDivider extends StatelessWidget {
  final double thickness;
  final double height;
  final bool isStriped;
  final Color color;

  const BauhausDivider({
    Key? key,
    this.thickness = 2,
    this.height = 16,
    this.isStriped = false,
    this.color = BauhausTheme.primaryBlack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isStriped) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: thickness),
            bottom: BorderSide(color: color, width: thickness),
          ),
        ),
        child: Row(
          children: List.generate(
            20,
            (index) => Expanded(
              child: Container(
                color: index.isEven ? color : BauhausTheme.white,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: thickness,
          color: color,
        ),
      ),
    );
  }
}
