import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/bauhaus_theme.dart';

class FloatingCartBar extends StatelessWidget {
  final int itemCount;
  final double total;

  const FloatingCartBar({
    super.key,
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: itemCount > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: itemCount > 0 ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        child: Visibility(
          visible: itemCount > 0,
          child: GestureDetector(
            onTap: () => context.go('/order'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Item count badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: BauhausTheme.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$itemCount',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // CENTER: View Order label
                  Expanded(
                    child: Text(
                      'VIEW ORDER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chivo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BauhausTheme.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Total price on right
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: GoogleFonts.chivo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BauhausTheme.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
