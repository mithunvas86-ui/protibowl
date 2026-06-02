import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/bauhaus_theme.dart';

class BauhausCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final String price;
  final String category;
  final VoidCallback? onTap;
  final Widget? actionButton;

  const BauhausCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    required this.price,
    required this.category,
    this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: BauhausTheme.primaryBlack, width: 2),
          color: BauhausTheme.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: BauhausTheme.primaryBlack, width: 2),
                  ),
                  color: BauhausTheme.lightGrey,
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            // Category badge (positioned over image)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BauhausTheme.accentRed,
                  border:
                      Border.all(color: BauhausTheme.primaryBlack, width: 1),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.white,
                  ),
                ),
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BauhausTheme.primaryBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: BauhausTheme.mediumGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BauhausTheme.accentRed,
                          border: Border.all(
                              color: BauhausTheme.primaryBlack, width: 1),
                        ),
                        child: Text(
                          price,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BauhausTheme.white,
                          ),
                        ),
                      ),
                      if (actionButton != null) actionButton!,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
