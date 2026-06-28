import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/floating_cart_bar.dart';
import 'order_tracking_page.dart';

/// Digital menu — "Modern Bistro" / Epicurean Minimalist design.
class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedTab;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    Future.microtask(() {
      if (mounted) context.read<MenuProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauhausTheme.background,
      appBar: AppBar(
        backgroundColor: BauhausTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            Text(
              'Proti Bowls',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BauhausTheme.surfaceBlack,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _selectedTab == 0
              ? _buildMenuTab(context)
              : const OrderTrackingPage(),
          Consumer<CartProvider>(
            builder: (context, cart, _) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingCartBar(
                  itemCount: cart.itemCount, total: cart.total),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── MENU TAB ─────────────────────────────────────────────────────────────
  Widget _buildMenuTab(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menu, _) {
        if (menu.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final searching = _searchCtrl.text.isNotEmpty;
        final featured = _featuredItem(menu);

        return RefreshIndicator(
          onRefresh: () => menu.fetchAll(),
          color: BauhausTheme.accentRed,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  // ── HERO ───────────────────────────────────────────
                  if (featured != null && !searching)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _HeroCard(item: featured),
                    ),

                  // ── SEARCH ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: BauhausTheme.primaryBlack),
                      onChanged: (v) {
                        menu.setSearchQuery(v);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search our menu...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: BauhausTheme.onSurfaceVariant),
                        prefixIcon: const Icon(Icons.search,
                            color: BauhausTheme.onSurfaceVariant, size: 22),
                        suffixIcon: searching
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: BauhausTheme.onSurfaceVariant,
                                    size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  menu.setSearchQuery('');
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: BauhausTheme.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(BauhausTheme.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(BauhausTheme.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(BauhausTheme.radiusMd),
                          borderSide: const BorderSide(
                              color: BauhausTheme.accentRed, width: 1.5),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  // ── CATEGORY PILLS ─────────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      children: [
                        for (final cat in menu.categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _categoryPill(
                              cat,
                              menu.selectedCategory == cat,
                              () => menu.selectCategory(cat),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── SECTIONS ───────────────────────────────────────
                  if (menu.filteredItems.isEmpty)
                    _emptyState()
                  else
                    ..._buildSections(menu, w),
                ],
              );
            },
          ),
        );
      },
    );
  }

  MenuItem? _featuredItem(MenuProvider menu) {
    // Only show the hero when the admin has explicitly starred an item as the
    // Featured Creation. If none is featured, returns null and the hero hides.
    for (final i in menu.items) {
      if (i.featured) return i;
    }
    return null;
  }

  List<Widget> _buildSections(MenuProvider menu, double width) {
    // Group filtered items by category, preserving the provider's order.
    final items = menu.filteredItems;
    final order = menu.categories.where((c) => c != 'All').toList();
    final grouped = <String, List<MenuItem>>{};
    for (final it in items) {
      grouped.putIfAbsent(it.category, () => []).add(it);
    }
    final cats = [
      ...order.where(grouped.containsKey),
      ...grouped.keys.where((c) => !order.contains(c)),
    ];

    final cols = width < 600 ? 1 : (width < 1000 ? 2 : 3);
    const gutter = 16.0;
    final cardW =
        (width - 40 - (gutter * (cols - 1))) / cols; // 20px side padding

    return [
      for (final cat in cats) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: _sectionHeader(cat),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: gutter,
            runSpacing: gutter,
            children: [
              for (final item in grouped[cat]!)
                SizedBox(
                  width: cols == 1 ? double.infinity : cardW,
                  child: _MenuCard(item: item),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  Widget _sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: BauhausTheme.outline, width: 1),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: BauhausTheme.primaryBlack,
            height: 1.3,
          ),
        ),
      );

  Widget _categoryPill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: selected
              ? BauhausTheme.surfaceBlack // primary #0a0a0a
              : BauhausTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(BauhausTheme.radiusPill),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: selected
                ? BauhausTheme.onAccent
                : BauhausTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Icon(Icons.search_off,
                size: 48, color: BauhausTheme.outline),
            const SizedBox(height: 12),
            Text('No items found',
                style: BauhausTheme.body(
                    size: 15, color: BauhausTheme.mediumGrey)),
          ],
        ),
      );

  // ── BOTTOM NAV (Menu / Search / Orders) ────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: BauhausTheme.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.menu_book, 'Menu',
                  active: _selectedTab == 0,
                  filled: true,
                  onTap: () => setState(() => _selectedTab = 0)),
              _navItem(Icons.search, 'Search', active: false, onTap: () {
                setState(() => _selectedTab = 0);
                Future.delayed(const Duration(milliseconds: 50),
                    () => _searchFocus.requestFocus());
              }),
              _navItem(Icons.receipt_long, 'Orders',
                  active: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {required bool active, bool filled = false, required VoidCallback onTap}) {
    final color =
        active ? BauhausTheme.accentRed : BauhausTheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — featured creation
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final MenuItem item;
  const _HeroCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${item.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: BauhausTheme.lightGrey),
                  errorWidget: (_, __, ___) => Container(
                    color: BauhausTheme.lightGrey,
                    child: const Icon(Icons.restaurant_menu,
                        color: BauhausTheme.mediumGrey, size: 48),
                  ),
                )
              else
                Container(color: BauhausTheme.surfaceContainerHigh),
              // gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURED CREATION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu card — exact Epicurean card
// ─────────────────────────────────────────────────────────────────────────────
class _MenuCard extends StatefulWidget {
  final MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _added = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onAdd(CartProvider cart) {
    cart.addItem(widget.item);
    setState(() => _added = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      decoration: BoxDecoration(
        color: BauhausTheme.white,
        borderRadius: BorderRadius.circular(BauhausTheme.radiusMd),
        boxShadow: BauhausTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () => context.push('/product/${item.id}'),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: BauhausTheme.lightGrey),
                      errorWidget: (_, __, ___) => Container(
                        color: BauhausTheme.lightGrey,
                        child: const Icon(Icons.restaurant_menu,
                            color: BauhausTheme.mediumGrey),
                      ),
                    )
                  else
                    Container(
                      color: BauhausTheme.lightGrey,
                      child: const Icon(Icons.restaurant_menu,
                          color: BauhausTheme.mediumGrey),
                    ),
                  if (item.isSoldOut)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      alignment: Alignment.center,
                      child: Text('SOLD OUT',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/product/${item.id}'),
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BauhausTheme.primaryBlack,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: BauhausTheme.accentRed,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: BauhausTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in item.tags.take(3)) _dietTag(tag),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _addButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dietTag(String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: BauhausTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tag.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: BauhausTheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      );

  Widget _addButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (widget.item.isSoldOut) {
          return SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BauhausTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(BauhausTheme.radiusSm),
              ),
              child: Center(
                child: Text('Sold Out',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BauhausTheme.mediumGrey)),
              ),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => _onAdd(cart),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _added ? const Color(0xFF474746) : BauhausTheme.accentRed,
              foregroundColor: BauhausTheme.onAccent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BauhausTheme.radiusSm),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_added ? Icons.check : Icons.add_shopping_cart,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  _added ? 'Added' : 'Add to Cart',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
