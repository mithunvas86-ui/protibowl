import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/bauhaus_theme.dart';
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
  final _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        context.read<MenuProvider>().setSearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 60,
          width: 200,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        backgroundColor: BauhausTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: BauhausTheme.primaryBlack,
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
                          child: Icon(
                            Icons.shopping_cart,
                            color: BauhausTheme.primaryBlack,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: BauhausTheme.accentRed,
                          ),
                          child: Text(
                            '${cart.items.length}',
                            style: GoogleFonts.chivo(
                              color: BauhausTheme.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
      body:
          _selectedTab == 0 ? _buildMenuTab(context) : _buildOrdersTab(context),
      floatingActionButton: null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'MENU',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'ORDERS',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, _) {
        if (menuProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search bar
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              menuProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) {
                    menuProvider.setSearchQuery(v);
                    setState(() {});
                  },
                ),
              ),
            // Space between AppBar and categories
            if (!_searchOpen) const SizedBox(height: 10),
            // Category Filter
            Container(
              color: BauhausTheme.lightGrey,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: menuProvider.categories.map((category) {
                    final isSelected =
                        menuProvider.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => menuProvider.selectCategory(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BauhausTheme.primaryBlack
                                : BauhausTheme.white,
                            border: Border.all(
                              color: BauhausTheme.primaryBlack,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: GoogleFonts.chivo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? BauhausTheme.white
                                  : BauhausTheme.primaryBlack,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Responsive Grid
            Expanded(
              child: menuProvider.filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'NO ITEMS',
                        style: GoogleFonts.chivo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.primaryBlack,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final cols = width < 500
                            ? 1
                            : width < 900
                                ? 2
                                : 3;
                        final crossSpacing = cols > 1 ? 12.0 : 0.0;
                        return RefreshIndicator(
                          onRefresh: () => menuProvider.fetchAll(),
                          color: BauhausTheme.primaryBlack,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: crossSpacing,
                              mainAxisExtent: 400,
                            ),
                            itemCount: menuProvider.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = menuProvider.filteredItems[index];
                              return _BauhausMenuCard(item: item);
                            },
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

  Widget _buildOrdersTab(BuildContext context) {
    return const OrderTrackingPage();
  }
}

class _BauhausMenuCard extends StatelessWidget {
  final dynamic item;

  const _BauhausMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: BauhausTheme.primaryBlack, width: 2),
            color: BauhausTheme.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image with Badge
              Stack(
                children: [
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFF0F0F0),
                              child: Icon(Icons.image,
                                  size: 60, color: Colors.black26),
                            ),
                          )
                        : const ColoredBox(
                            color: Color(0xFFF0F0F0),
                            child: Icon(Icons.image,
                                size: 60, color: Colors.black26),
                          ),
                  ),
                  // Price badge on image (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber[300],
                      ),
                      child: Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.primaryBlack,
                        ),
                      ),
                    ),
                  ),
                  if (item.badge != null && item.badge!.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.badge == 'VEG'
                              ? Colors.green[600]
                              : BauhausTheme.accentRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.badge!,
                          style: GoogleFonts.chivo(
                            color: BauhausTheme.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Product Info
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
                            item.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.chivo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BauhausTheme.primaryBlack,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.chivo(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => context.push('/product/${item.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VIEW MORE',
                                  style: GoogleFonts.chivo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: BauhausTheme.accentRed,
                                    letterSpacing: 0.5,
                                    decoration: TextDecoration.underline,
                                    decorationColor: BauhausTheme.accentRed,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.chevron_right,
                                    size: 14, color: BauhausTheme.accentRed),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // ADD TO CART / Qty control
                      Builder(builder: (context) {
                            final cartIndex = cart.items
                                .indexWhere((i) => i.item.id == item.id);
                            final qty = cartIndex > -1
                                ? cart.items[cartIndex].quantity
                                : 0;
                            if (qty == 0) {
                              return GestureDetector(
                                onTap: () => cart.addItem(item),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: BauhausTheme.primaryBlack,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    'ADD TO CART',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.chivo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: BauhausTheme.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: BauhausTheme.primaryBlack,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cart.updateQuantity(
                                        item.id, qty - 1),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 38,
                                      child: Icon(Icons.remove,
                                          color: BauhausTheme.white,
                                          size: 18),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$qty',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.chivo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: BauhausTheme.white,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => cart.addItem(item),
                                    child: const SizedBox(
                                      width: 40,
                                      height: 38,
                                      child: Icon(Icons.add,
                                          color: BauhausTheme.white,
                                          size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
