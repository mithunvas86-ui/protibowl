import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/floating_cart_bar.dart';
import 'order_tracking_page.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({super.key, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedTab;
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();

  static const Color _cobalt = Color(0xFF1B4FD8);

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
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        context.read<MenuProvider>().setSearchQuery('');
      }
    });
  }

  TextStyle _sg(double size, FontWeight weight, Color color,
          {double? spacing}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauhausTheme.white,
      appBar: AppBar(
        backgroundColor: BauhausTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: BauhausTheme.primaryBlack,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PROTI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BauhausTheme.primaryBlack,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 6),
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              'BOWL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BauhausTheme.accentRed,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: BauhausTheme.primaryBlack,
              size: 24,
            ),
            onPressed: _toggleSearch,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/order'),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            color: BauhausTheme.primaryBlack,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          color: BauhausTheme.accentRed,
                          alignment: Alignment.center,
                          child: Text(
                            '${cart.itemCount}',
                            style: GoogleFonts.spaceGrotesk(
                              color: BauhausTheme.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _selectedTab == 0
              ? _buildMenuTab(context)
              : _buildOrdersTab(context),
          Consumer<CartProvider>(
            builder: (context, cart, _) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingCartBar(
                itemCount: cart.itemCount,
                total: cart.total,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: BauhausTheme.primaryBlack, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'MENU',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'ORDERS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menu, _) {
        if (menu.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ── SEARCH BAR ───────────────────────────────────────
            if (_searchOpen)
              Container(
                color: BauhausTheme.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: _sg(14, FontWeight.w500, BauhausTheme.primaryBlack),
                  decoration: InputDecoration(
                    hintText: 'SEARCH ITEMS...',
                    hintStyle: _sg(13, FontWeight.w500, BauhausTheme.mediumGrey),
                    prefixIcon: const Icon(Icons.search,
                        color: BauhausTheme.primaryBlack, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: BauhausTheme.primaryBlack),
                            onPressed: () {
                              _searchCtrl.clear();
                              menu.setSearchQuery('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                          color: BauhausTheme.primaryBlack, width: 2),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                          color: BauhausTheme.primaryBlack, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(
                          color: BauhausTheme.accentRed, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    filled: false,
                  ),
                  onChanged: (v) {
                    menu.setSearchQuery(v);
                    setState(() {});
                  },
                ),
              ),

            // ── CATEGORY FILTER ──────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: BauhausTheme.lightGrey,
                border: Border(
                  bottom: BorderSide(
                      color: BauhausTheme.primaryBlack, width: 2),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: menu.categories.map((cat) {
                    final selected = menu.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => menu.selectCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? BauhausTheme.primaryBlack
                                : BauhausTheme.white,
                            border: Border.all(
                              color: BauhausTheme.primaryBlack,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: _sg(
                              11,
                              FontWeight.w700,
                              selected
                                  ? BauhausTheme.white
                                  : BauhausTheme.primaryBlack,
                              spacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── MENU GRID ────────────────────────────────────────
            Expanded(
              child: menu.filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            color: BauhausTheme.lightGrey,
                            child: const Icon(Icons.search_off,
                                size: 32,
                                color: BauhausTheme.mediumGrey),
                          ),
                          const SizedBox(height: 12),
                          Text('NO ITEMS FOUND',
                              style: _sg(14, FontWeight.w700,
                                  BauhausTheme.mediumGrey,
                                  spacing: 1)),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w < 500
                            ? 1
                            : w < 900
                                ? 2
                                : 3;
                        return RefreshIndicator(
                          onRefresh: () => menu.fetchAll(),
                          color: BauhausTheme.primaryBlack,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 100),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: cols > 1 ? 12 : 12,
                              crossAxisSpacing: cols > 1 ? 12 : 0,
                              mainAxisExtent: 380,
                            ),
                            itemCount: menu.filteredItems.length,
                            itemBuilder: (ctx, i) =>
                                _BauhausMenuCard(
                                    item: menu.filteredItems[i]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersTab(BuildContext context) =>
      const OrderTrackingPage();
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Card — Bauhaus Modernist
// ─────────────────────────────────────────────────────────────────────────────

class _BauhausMenuCard extends StatelessWidget {
  final dynamic item;
  static const Color _cobalt = Color(0xFF1B4FD8);
  static const Color _vegGreen = Color(0xFF1B7A34);

  const _BauhausMenuCard({required this.item});

  TextStyle _sg(double size, FontWeight weight, Color color,
          {double? spacing}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final cartIdx =
            cart.items.indexWhere((i) => i.item.id == item.id);
        final qty = cartIdx > -1 ? cart.items[cartIdx].quantity : 0;

        return Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(color: BauhausTheme.primaryBlack, width: 2),
            ),
            color: BauhausTheme.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── IMAGE ─────────────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: BauhausTheme.patternGrey,
                              child: const Icon(Icons.image,
                                  size: 56,
                                  color: BauhausTheme.mediumGrey),
                            ),
                          )
                        : Container(
                            color: BauhausTheme.patternGrey,
                            child: const Icon(Icons.image,
                                size: 56,
                                color: BauhausTheme.mediumGrey),
                          ),
                  ),
                  // Price block — bottom left
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      color: _cobalt,
                      child: Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: _sg(
                            15, FontWeight.w800, BauhausTheme.white),
                      ),
                    ),
                  ),
                  // Veg indicator — top right
                  if (item.badge != null && item.badge!.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: _vegGreen, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _vegGreen,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Bottom border between image and info
              Container(
                  height: 2, color: BauhausTheme.primaryBlack),

              // ── PRODUCT INFO ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _sg(14, FontWeight.w800,
                                BauhausTheme.primaryBlack,
                                spacing: 0.3),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _sg(12, FontWeight.w400,
                                      BauhausTheme.mediumGrey)
                                  .copyWith(height: 1.4),
                            ),
                          ],
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () =>
                                context.push('/product/${item.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DETAILS',
                                  style: _sg(
                                    10,
                                    FontWeight.w700,
                                    BauhausTheme.accentRed,
                                    spacing: 0.8,
                                  ).copyWith(
                                      decoration: TextDecoration
                                          .underline,
                                      decorationColor:
                                          BauhausTheme.accentRed),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right,
                                    size: 13,
                                    color: BauhausTheme.accentRed),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── CART CONTROL ────────────────────────
                      qty == 0
                          ? GestureDetector(
                              onTap: () => cart.addItem(item),
                              child: Container(
                                width: double.infinity,
                                height: 42,
                                color: BauhausTheme.primaryBlack,
                                alignment: Alignment.center,
                                child: Text(
                                  'ADD TO CART',
                                  style: _sg(12, FontWeight.w800,
                                      BauhausTheme.white,
                                      spacing: 0.8),
                                ),
                              ),
                            )
                          : Container(
                              height: 42,
                              decoration: const BoxDecoration(
                                color: BauhausTheme.primaryBlack,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cart
                                        .updateQuantity(
                                            item.id, qty - 1),
                                    child: const SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Icon(Icons.remove,
                                          color: BauhausTheme.white,
                                          size: 18),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$qty',
                                      textAlign: TextAlign.center,
                                      style: _sg(
                                          16,
                                          FontWeight.w800,
                                          BauhausTheme.white),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        cart.addItem(item),
                                    child: const SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Icon(Icons.add,
                                          color: BauhausTheme.white,
                                          size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
