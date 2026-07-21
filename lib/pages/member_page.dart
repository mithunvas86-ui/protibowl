import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/app_bottom_nav.dart';

/// The member area: login gate → premium membership card + meal calendar.
///
/// UX psychology: the premium card leads the screen (ownership & status —
/// people keep what makes them feel valued), the single most important daily
/// action (confirm tomorrow's meal) sits directly under it as one big
/// yes / no choice, and everything else stays quiet.
class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SubscriptionProvider>();
      if (p.isMemberLoggedIn) p.loadMemberData();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _busy = true);
    final error = await context
        .read<SubscriptionProvider>()
        .memberLogin(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: BauhausTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (provider.isMemberLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: provider.memberLogout,
            ),
        ],
      ),
      body: provider.isMemberLoggedIn ? _memberView(provider) : _loginView(),
      bottomNavigationBar: const AppBottomNav(active: AppTab.premium),
    );
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Widget _loginView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.card_membership,
                  size: 56, color: BauhausTheme.accentRed),
              const SizedBox(height: 16),
              Text('Member login',
                  textAlign: TextAlign.center,
                  style: BauhausTheme.heading(size: 24)),
              const SizedBox(height: 6),
              Text(
                'Use the login sent to you on WhatsApp when your membership '
                'was approved.',
                textAlign: TextAlign.center,
                style: BauhausTheme.body(
                    size: 13.5, color: BauhausTheme.mediumGrey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _login,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Log In'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/subscribe'),
                child: const Text('Not a member yet? See plans'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Member home ──────────────────────────────────────────────────────────
  Widget _memberView(SubscriptionProvider provider) {
    if (provider.loadingMember && provider.mySubscription == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final sub = provider.mySubscription;
    if (sub == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 56, color: BauhausTheme.mediumGrey),
              const SizedBox(height: 12),
              Text('No active membership on this account',
                  textAlign: TextAlign.center,
                  style: BauhausTheme.heading(size: 20)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/subscribe'),
                child: const Text('Explore Plans'),
              ),
            ],
          ),
        ),
      );
    }

    final plan =
        (sub['subscription_plans'] as Map?)?.cast<String, dynamic>() ?? {};
    return RefreshIndicator(
      onRefresh: provider.loadMemberData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _premiumCard(sub, plan),
          const SizedBox(height: 24),
          _tomorrowSection(provider),
          const SizedBox(height: 24),
          _calendar(provider),
        ],
      ),
    );
  }

  /// The PREMIUM CARD — brushed-gold gradient, "keep-worthy" membership pass.
  Widget _premiumCard(Map<String, dynamic> sub, Map<String, dynamic> plan) {
    final totalDays = (plan['duration_days'] as num?)?.toInt() ?? 0;
    final mealsPerDay = (plan['meals_per_day'] as num?)?.toInt() ?? 1;
    final totalMeals = totalDays * mealsPerDay;
    // meal_confirmations rows from today onward are already loaded — the
    // count of those still-scheduled days tells us what's left.
    final remainingMeals = (_daysRemaining(sub) * mealsPerDay)
        .clamp(0, totalMeals)
        .toInt();
    final consumedMeals = totalMeals - remainingMeals;
    final progress = totalMeals == 0 ? 0.0 : consumedMeals / totalMeals;

    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final compareAt = (plan['compare_at_price'] as num?)?.toDouble() ?? 0;
    final savings = compareAt > price ? compareAt - price : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9D423), Color(0xFFD4A017), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(BauhausTheme.radiusLg),
        boxShadow: BauhausTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(BauhausTheme.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('PREMIUM MEMBER',
                        style: BauhausTheme.body(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            spacing: 1.2)),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(BauhausTheme.radiusSm),
                onTap: () => _showManageSheet(sub, plan),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(BauhausTheme.radiusSm),
                  ),
                  child: const Icon(Icons.qr_code_2,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Meals Remaining',
              style: BauhausTheme.body(
                  size: 14, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$remainingMeals',
                  style: BauhausTheme.heading(
                      size: 44, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              Text('Meals Left',
                  style: BauhausTheme.heading(
                      size: 18,
                      weight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85))),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(BauhausTheme.radiusPill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$consumedMeals Consumed',
                  style: BauhausTheme.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                      spacing: 0.5)),
              Text('$totalMeals Total',
                  style: BauhausTheme.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.85),
                      spacing: 0.5)),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Savings',
                        style: BauhausTheme.body(
                            size: 11,
                            weight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.85))),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: '₹${savings.round()} ',
                        style: BauhausTheme.heading(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.white),
                        children: [
                          TextSpan(
                            text: 'saved',
                            style: BauhausTheme.body(
                                size: 14,
                                color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showManageSheet(sub, plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BauhausTheme.surfaceBlack,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Manage Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Days from today (inclusive) still scheduled in [provider.mealDays] —
  /// used as a stand-in for "meals remaining" without a separate count query.
  int _daysRemaining(Map<String, dynamic> sub) =>
      context.read<SubscriptionProvider>().mealDays.length;

  /// Membership details that don't fit on the gradient card — name, member
  /// code, goal, validity — surfaced from the "Manage Plan" / QR tap.
  void _showManageSheet(Map<String, dynamic> sub, Map<String, dynamic> plan) {
    final name = (sub['customer_name'] ?? '') as String;
    final code = (sub['member_code'] ?? '') as String;
    final end = (sub['end_date'] ?? '') as String;
    final goal = ((sub['health_goal'] ?? '') as String)
        .replaceAll('_', ' ')
        .toUpperCase();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(BauhausTheme.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isEmpty ? 'Your membership' : name,
                style: BauhausTheme.heading(size: 20)),
            const SizedBox(height: 4),
            if (code.isNotEmpty)
              Text(code,
                  style:
                      BauhausTheme.body(size: 13, color: BauhausTheme.mediumGrey)),
            const SizedBox(height: 20),
            _sheetRow('Plan', (plan['name'] ?? '—').toString()),
            if (goal.isNotEmpty) _sheetRow('Goal', goal),
            _sheetRow('Valid till', end.isEmpty ? '—' : end),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    BauhausTheme.body(size: 14, color: BauhausTheme.mediumGrey)),
            Text(value,
                style: BauhausTheme.body(size: 14, weight: FontWeight.w600)),
          ],
        ),
      );

  /// Tomorrow's meal — one glance, one tap.
  Widget _tomorrowSection(SubscriptionProvider provider) {
    final tomorrow = provider.tomorrowMeal;
    final status = tomorrow?.status ?? 'awaiting';
    final locked = !['awaiting', 'confirmed', 'skipped'].contains(status);

    final (label, color) = switch (status) {
      'confirmed' => ('Confirmed — we\'re cooking for you', const Color(0xFF2E7D32)),
      'skipped' => ('Skipped — enjoy your day', BauhausTheme.mediumGrey),
      'preparing' || 'prepared' => ('In the kitchen', const Color(0xFFE65100)),
      'out_for_delivery' => ('On its way to you', const Color(0xFF1565C0)),
      'delivered' => ('Delivered', const Color(0xFF2E7D32)),
      _ => ('Awaiting your confirmation', BauhausTheme.accentRed),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BauhausTheme.white,
        borderRadius: BorderRadius.circular(BauhausTheme.radiusLg),
        boxShadow: BauhausTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tomorrow\'s meal', style: BauhausTheme.heading(size: 20)),
          // The actual dish the kitchen has planned for the member's
          // preference — seeing the food makes confirming much easier.
          if (provider.tomorrowDish != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if ((provider.tomorrowDish!['image_url'] ?? '')
                    .toString()
                    .isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(BauhausTheme.radiusMd),
                    child: Image.network(
                      provider.tomorrowDish!['image_url'] as String,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (provider.tomorrowDish!['name'] ?? '') as String,
                        style: BauhausTheme.heading(size: 16),
                      ),
                      if (((provider.tomorrowDish!['kcal'] ?? 0) as num) > 0)
                        Text(
                          '${provider.tomorrowDish!['kcal']} kcal',
                          style: BauhausTheme.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: BauhausTheme.accentRed),
                        ),
                      if ((provider.tomorrowDish!['description'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          provider.tomorrowDish!['description'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BauhausTheme.body(
                              size: 12.5,
                              color: BauhausTheme.mediumGrey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: BauhausTheme.body(
                        size: 14, weight: FontWeight.w600, color: color)),
              ),
            ],
          ),
          if (!locked) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: status == 'confirmed'
                        ? null
                        : () => _confirm(provider, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Yes, I\'ll eat'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: status == 'skipped'
                        ? null
                        : () => _confirm(provider, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Skip tomorrow'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'You can also reply YES / NO to our evening WhatsApp message.',
              style: BauhausTheme.body(
                  size: 12, color: BauhausTheme.mediumGrey),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirm(SubscriptionProvider provider, bool yes) async {
    final error = await provider.confirmTomorrow(yes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          (yes
              ? 'Confirmed! Your meal will be fresh tomorrow.'
              : 'Skipped — see you the day after.')),
      backgroundColor:
          error == null ? const Color(0xFF2E7D32) : BauhausTheme.error,
    ));
  }

  /// Simple history/upcoming list — reinforces the habit streak.
  Widget _calendar(SubscriptionProvider provider) {
    if (provider.mealDays.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your meals', style: BauhausTheme.heading(size: 20)),
        const SizedBox(height: 12),
        ...provider.mealDays.map((d) {
          final (icon, color) = switch (d.status) {
            'confirmed' => (Icons.check_circle, const Color(0xFF2E7D32)),
            'skipped' => (Icons.remove_circle_outline, BauhausTheme.mediumGrey),
            'preparing' ||
            'prepared' =>
              (Icons.soup_kitchen_outlined, const Color(0xFFE65100)),
            'out_for_delivery' =>
              (Icons.delivery_dining, const Color(0xFF1565C0)),
            'delivered' => (Icons.done_all, const Color(0xFF2E7D32)),
            'missed' => (Icons.cancel_outlined, BauhausTheme.error),
            _ => (Icons.schedule, BauhausTheme.outline),
          };
          final label = d.status.replaceAll('_', ' ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Text(
                  '${d.date.day}/${d.date.month}/${d.date.year}',
                  style: BauhausTheme.body(size: 14, weight: FontWeight.w600),
                ),
                const Spacer(),
                Text(label[0].toUpperCase() + label.substring(1),
                    style: BauhausTheme.body(size: 13, color: color)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
