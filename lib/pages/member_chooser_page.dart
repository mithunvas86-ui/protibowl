import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/app_bottom_nav.dart';

/// Thin entry point for the Premium tab — Gold (gym model) or Elite
/// (subscription model). Each stays strictly scoped to its own model.
class MemberChooserPage extends StatelessWidget {
  const MemberChooserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Choose your membership', style: BauhausTheme.heading(size: 22)),
          const SizedBox(height: 4),
          Text('Two ways to get more out of Proti Bowls.',
              style: BauhausTheme.body(size: 14, color: BauhausTheme.mediumGrey)),
          const SizedBox(height: 20),
          _ChoiceCard(
            title: 'Gold',
            subtitle: 'Discount + free delivery on every gym order',
            icon: Icons.workspace_premium,
            gradient: const [Color(0xFFF9D423), Color(0xFFD4A017)],
            onTap: () => context.go('/member/gold'),
          ),
          const SizedBox(height: 16),
          _ChoiceCard(
            title: 'Elite',
            subtitle: 'Daily fresh meal subscription, delivered to your door',
            icon: Icons.card_membership,
            gradient: const [BauhausTheme.primaryBlack, Color(0xFF1B3A2D)],
            onTap: () => context.go('/member/elite'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppTab.premium),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(BauhausTheme.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(BauhausTheme.radiusLg),
          boxShadow: BauhausTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: BauhausTheme.heading(
                          size: 22, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: BauhausTheme.body(size: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
