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
          child: Container(height: 3, color: BauhausTheme.primaryBlack),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PROTI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BauhausTheme.primaryBlack,
                  letterSpacing: 1.5,
                )),
            const SizedBox(width: 6),
            Image.asset('assets/images/logo.png',
                height: 32, width: 32, fit: BoxFit.contain),
            const SizedBox(width: 6),
            Text('BOWL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BauhausTheme.accentRed,
                  letterSpacing: 1.5,
                )),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                          child: Icon(Icons.shopping_cart_outlined,
                              color: BauhausTheme.primaryBlack, size: 26),
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
                          child: Text('${cart.itemCount}',
                              style: GoogleFonts.spaceGrotesk(
                                color: BauhausTheme.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              )),
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
          // ── GRID BACKGROUND ──────────────────────────────────────
          CustomPaint(
            painter: _GridPainter(),
            child: const SizedBox.expand(),
          ),
          _selectedTab == 0
              ? _buildMenuTab(context)
              : _buildOrdersTab(context),
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
                icon: Icon(Icons.grid_view_rounded), label: 'MENU'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined), label: 'ORDERS'),
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
            // ── SEARCH BAR ─────────────────────────────────────────
            if (_searchOpen)
              Container(
                color: BauhausTheme.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style:
                      _sg(14, FontWeight.w500, BauhausTheme.primaryBlack),
                  decoration: InputDecoration(
                    hintText: 'SEARCH ITEMS...',
                    hintStyle:
                        _sg(13, FontWeight.w500, BauhausTheme.mediumGrey),
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
                      borderSide:
                          BorderSide(color: BauhausTheme.accentRed, width: 2),
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

            // ── CATEGORY FILTER ────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: BauhausTheme.lightGrey,
                border: Border(
                  bottom:
                      BorderSide(color: BauhausTheme.primaryBlack, width: 2),
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
                                color: BauhausTheme.primaryBlack, width: 2),
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

            // ── MENU GRID ──────────────────────────────────────────
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
                                size: 32, color: BauhausTheme.mediumGrey),
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
                        final cols = w < 500 ? 1 : w < 900 ? 2 : 3;
                        return RefreshIndicator(
                          onRefresh: () => menu.fetchAll(),
                          color: BauhausTheme.primaryBlack,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 100),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 12,
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

  Widget _buildOrdersTab(BuildContext context) => const OrderTrackingPage();
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid background painter
// ─────────────────────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..strokeWidth = 0.8;

    const step = 28.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Card — Bauhaus Modernist with hover effects
// ─────────────────────────────────────────────────────────────────────────────

class _BauhausMenuCard extends StatefulWidget {
  final dynamic item;
  const _BauhausMenuCard({required this.item});

  @override
  State<_BauhausMenuCard> createState() => _BauhausMenuCardState();
}

class _BauhausMenuCardState extends State<_BauhausMenuCard> {
  bool _cardHovered = false;
  bool _btnHovered = false;

  static const Color _yellow = Color(0xFFFFCC00);
  static const Color _vegGreen = Color(0xFF1B7A34);

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
            cart.items.indexWhere((i) => i.item.id == widget.item.id);
        final qty = cartIdx > -1 ? cart.items[cartIdx].quantity : 0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _cardHovered = true),
          onExit: (_) => setState(() => _cardHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: _cardHovered
                    ? BauhausTheme.accentRed
                    : BauhausTheme.primaryBlack,
                width: _cardHovered ? 2.5 : 2,
              ),
              color: BauhausTheme.white,
              boxShadow: _cardHovered
                  ? [
                      const BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── IMAGE with zoom on hover ─────────────────────
                ClipRect(
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          scale: _cardHovered ? 1.07 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: widget.item.imageUrl != null
                              ? Image.network(
                                  widget.item.imageUrl!,
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
                        // Sold-out overlay
                        if (widget.item.isSoldOut)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.58),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications_off,
                                      color: Colors.white, size: 34),
                                  const SizedBox(height: 4),
                                  Text(
                                    'SOLD OUT',
                                    style: _sg(13, FontWeight.w800,
                                        Colors.white,
                                        spacing: 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Price block — bottom left (yellow)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            color: _yellow,
                            child: Text(
                              '₹${widget.item.price.toStringAsFixed(0)}',
                              style: _sg(15, FontWeight.w800,
                                  BauhausTheme.primaryBlack),
                            ),
                          ),
                        ),
                        // Veg indicator — top right
                        if (widget.item.badge != null &&
                            widget.item.badge!.isNotEmpty)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _vegGreen, width: 2),
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
                  ),
                ),

                Container(height: 2, color: BauhausTheme.primaryBlack),

                // ── PRODUCT INFO ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _sg(14, FontWeight.w800,
                                  BauhausTheme.primaryBlack,
                                  spacing: 0.3),
                            ),
                            if (widget.item.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _sg(12, FontWeight.w400,
                                        BauhausTheme.mediumGrey)
                                    .copyWith(height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => context
                                  .push('/product/${widget.item.id}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'DETAILS',
                                    style: _sg(10, FontWeight.w700,
                                            BauhausTheme.accentRed,
                                            spacing: 0.8)
                                        .copyWith(
                                            decoration:
                                                TextDecoration.underline,
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

                        // ── CART CONTROL ──────────────────────────
                        widget.item.isSoldOut
                            ? Container(
                                width: double.infinity,
                                height: 42,
                                color: Colors.grey.shade400,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.notifications_off,
                                        color: Colors.white, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NOT AVAILABLE',
                                      style: _sg(11, FontWeight.w800,
                                          Colors.white,
                                          spacing: 0.8),
                                    ),
                                  ],
                                ),
                              )
                            : qty == 0
                            ? MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) =>
                                    setState(() => _btnHovered = true),
                                onExit: (_) =>
                                    setState(() => _btnHovered = false),
                                child: GestureDetector(
                                  onTap: () => cart.addItem(widget.item),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    width: double.infinity,
                                    height: 42,
                                    color: _btnHovered
                                        ? BauhausTheme.accentRed
                                        : BauhausTheme.primaryBlack,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _btnHovered
                                              ? Icons.add_shopping_cart
                                              : Icons.shopping_cart_outlined,
                                          color: BauhausTheme.white,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ADD TO CART',
                                          style: _sg(12, FontWeight.w800,
                                              BauhausTheme.white,
                                              spacing: 0.8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                height: 42,
                                color: BauhausTheme.primaryBlack,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => cart.updateQuantity(
                                          widget.item.id, qty - 1),
                                      child: const SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: Icon(Icons.remove,
                                            color: BauhausTheme.white,
                                            size: 18),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text('$qty',
                                          textAlign: TextAlign.center,
                                          style: _sg(16, FontWeight.w800,
                                              BauhausTheme.white)),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          cart.addItem(widget.item),
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
          ),
        );
      },
    );
  }
}
