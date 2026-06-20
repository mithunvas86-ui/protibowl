import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme/bauhaus_theme.dart';

class ProductDetailPage extends StatefulWidget {
  final String itemId;
  final String tableId;
  const ProductDetailPage(
      {super.key, required this.itemId, required this.tableId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  int _spiceLevel = 1; // 0=Mild, 1=Medium, 2=Hot
  String _paymentMethod = 'cod';
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  // Unified to the terracotta accent (was cobalt blue, off-palette).
  static const Color _cobalt = BauhausTheme.accentRed;
  static const Color _vegGreen = Color(0xFF1B7A34);
  static const Color _proteinOrange = Color(0xFFCC6200);

  final Map<String, bool> _addons = {
    'Extra Avocado': false,
    'Quinoa Base': false,
    'Extra Protein': false,
  };
  final Map<String, double> _addonPrices = {
    'Extra Avocado': 20,
    'Quinoa Base': 50,
    'Extra Protein': 30,
  };
  final List<String> _includes = [
    'Mixed Greens',
    'Cherry Tomatoes',
    'Cucumber',
    'Red Onion',
    'Chickpea Base',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  double get _addonTotal => _addons.entries
      .where((e) => e.value)
      .fold(0.0, (s, e) => s + (_addonPrices[e.key] ?? 0));

  double _total(double base) => (base + _addonTotal) * _quantity;

  TextStyle _sg(double size, FontWeight weight, Color color,
          {double? spacing}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  void _showOrderDialog(BuildContext context, dynamic item) {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    String? orderType;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: BauhausTheme.primaryBlack,
            child: Text('CUSTOMER DETAILS',
                style: _sg(15, FontWeight.w800, BauhausTheme.white,
                    spacing: 1)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('NAME'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  style: _sg(14, FontWeight.w500, BauhausTheme.primaryBlack),
                  decoration:
                      const InputDecoration(hintText: 'Your full name'),
                ),
                const SizedBox(height: 14),
                _label('PHONE'),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: _sg(14, FontWeight.w500, BauhausTheme.primaryBlack),
                  decoration:
                      const InputDecoration(hintText: '10-digit number'),
                ),
                const SizedBox(height: 14),
                _label('ORDER TYPE'),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: BauhausTheme.patternGrey, width: 1),
                  ),
                  child: Column(children: [
                    RadioListTile<String>(
                      title: Text('DINE-IN',
                          style: _sg(13, FontWeight.w700,
                              BauhausTheme.primaryBlack)),
                      value: 'dine_in',
                      groupValue: orderType,
                      activeColor: _cobalt,
                      dense: true,
                      onChanged: (v) => setS(() => orderType = v),
                    ),
                    const Divider(
                        height: 0,
                        thickness: 1,
                        color: BauhausTheme.primaryBlack),
                    RadioListTile<String>(
                      title: Text('TAKEAWAY',
                          style: _sg(13, FontWeight.w700,
                              BauhausTheme.primaryBlack)),
                      value: 'takeaway',
                      groupValue: orderType,
                      activeColor: _cobalt,
                      dense: true,
                      onChanged: (v) => setS(() => orderType = v),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('CANCEL',
                  style: _sg(
                      13, FontWeight.w700, BauhausTheme.mediumGrey)),
            ),
            GestureDetector(
              onTap: () async {
                if (_nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter your name')));
                  return;
                }
                if (_phoneCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter phone number')));
                  return;
                }
                if (orderType == null) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select order type')));
                  return;
                }
                try {
                  // Server computes price from item id + quantity (DB price).
                  // NOTE: add-on/spice pricing is not yet applied server-side —
                  // see SECURITY_HARDENING.md (server-side add-on pricing TODO).
                  final serverItems = [
                    {'menu_item_id': item.id, 'quantity': _quantity}
                  ];
                  final orderProvider = this.context.read<OrderProvider>();
                  final String orderId;
                  if (_paymentMethod == 'online') {
                    final result = await orderProvider.placeOnlineOrder(
                      customerName: _nameCtrl.text,
                      customerPhone: _phoneCtrl.text,
                      orderType: orderType!,
                      items: serverItems,
                    );
                    if (!result.success) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                            content: Text(result.message),
                            backgroundColor: Colors.red));
                      }
                      return;
                    }
                    orderId = result.orderNumber ?? '';
                  } else {
                    orderId = await orderProvider.placeCodOrder(
                      customerName: _nameCtrl.text,
                      customerPhone: _phoneCtrl.text,
                      orderType: orderType!,
                      items: serverItems,
                    );
                  }
                  if (mounted) {
                    if (dCtx.mounted) Navigator.pop(dCtx);
                    this.context.go('/confirmation?orderId=$orderId');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                color: BauhausTheme.accentRed,
                child: Text('PLACE ORDER',
                    style: _sg(13, FontWeight.w800, BauhausTheme.white,
                        spacing: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BauhausTheme.background,
      appBar: AppBar(
        backgroundColor: BauhausTheme.background,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: BauhausTheme.primaryBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
              height: 2, color: BauhausTheme.primaryBlack),
        ),
        actions: [
          Consumer<CartProvider>(builder: (context, cart, _) {
            final count =
                cart.items.fold(0, (s, i) => s + i.quantity);
            if (count == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => context.go('/order'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: BauhausTheme.primaryBlack,
                        size: 26),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        color: BauhausTheme.accentRed,
                        alignment: Alignment.center,
                        child: Text('$count',
                            style: _sg(8, FontWeight.w800,
                                BauhausTheme.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, _) {
          final idx = menuProvider.items
              .indexWhere((i) => i.id == widget.itemId);
          if (idx == -1) {
            return Center(
                child: Text('Product not found',
                    style: _sg(16, FontWeight.w500,
                        BauhausTheme.mediumGrey)));
          }
          final item = menuProvider.items[idx];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HERO IMAGE ──────────────────────────────
                SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.imageUrl != null
                          ? Image.network(item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder())
                          : _imagePlaceholder(),
                      // bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Veg indicator — top left
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: _vegGreen, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _vegGreen,
                            ),
                          ),
                        ),
                      ),
                      // PLANT BASED badge — top right
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BauhausTheme.accentRed,
                            borderRadius: BorderRadius.circular(
                                BauhausTheme.radiusPill),
                          ),
                          child: Text('PLANT BASED',
                              style: _sg(11, FontWeight.w700,
                                  BauhausTheme.white,
                                  spacing: 0.8)),
                        ),
                      ),
                      // Category label — bottom left
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BauhausTheme.surfaceBlack,
                            borderRadius: BorderRadius.circular(
                                BauhausTheme.radiusPill),
                          ),
                          child: Text(
                              item.category.toUpperCase(),
                              style: _sg(11, FontWeight.w700,
                                  BauhausTheme.white,
                                  spacing: 1.2)),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── TITLE + PRICE ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: BauhausTheme.heading(
                              size: 26, weight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: BauhausTheme.body(
                              size: 24,
                              weight: FontWeight.w600,
                              color: BauhausTheme.accentRed,
                              spacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── DIETARY TAGS ─────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _solidTag('VEGAN', _vegGreen),
                      _solidTag('GLUTEN FREE', _cobalt),
                      _solidTag('HIGH PROTEIN', _proteinOrange),
                      if (item.kcal > 0)
                        _solidTag('${item.kcal} KCAL',
                            BauhausTheme.surfaceBlack),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── DESCRIPTION ──────────────────────────────
                if (item.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Text(
                      item.description,
                      style: _sg(13, FontWeight.w400,
                              BauhausTheme.mediumGrey)
                          .copyWith(height: 1.65),
                    ),
                  ),
                const SizedBox(height: 20),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── NUTRITION GRID ───────────────────────────
                _sectionHeader('NUTRITION / SERVING'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(children: [
                    _nutCell('CALORIES', '280'),
                    _nutCell('PROTEIN', '12.5g'),
                    _nutCell('CARBS', '32g'),
                    _nutCell('FAT', '8g'),
                  ]),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── SPICE LEVEL ──────────────────────────────
                _sectionHeader('SPICE LEVEL'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: BauhausTheme.patternGrey, width: 1),
                    ),
                    child: Row(
                      children: List.generate(3, (i) {
                        final labels = ['MILD', 'MEDIUM', 'HOT'];
                        final sel = _spiceLevel == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _spiceLevel = i),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: sel
                                    ? BauhausTheme.accentRed
                                    : BauhausTheme.white,
                                border: i < 2
                                    ? const Border(
                                        right: BorderSide(
                                            color: BauhausTheme
                                                .primaryBlack,
                                            width: 1))
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                labels[i],
                                style: _sg(
                                    12,
                                    FontWeight.w800,
                                    sel
                                        ? BauhausTheme.white
                                        : BauhausTheme.primaryBlack,
                                    spacing: 0.5),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── STANDARD INCLUDES ────────────────────────
                _sectionHeader('STANDARD INCLUDES'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: BauhausTheme.patternGrey, width: 1),
                    ),
                    child: Column(
                      children: _includes
                          .asMap()
                          .entries
                          .map((entry) {
                        final last =
                            entry.key == _includes.length - 1;
                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Container(
                                width: 18,
                                height: 18,
                                color: _vegGreen,
                                child: const Icon(Icons.check,
                                    size: 12,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.value,
                                  style: _sg(
                                      13,
                                      FontWeight.w500,
                                      BauhausTheme
                                          .primaryBlack)),
                            ]),
                          ),
                          if (!last)
                            Container(
                                height: 1,
                                color: BauhausTheme.patternGrey),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── ADD-ONS ──────────────────────────────────
                _sectionHeader('ADD-ONS (OPTIONAL)'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: BauhausTheme.patternGrey, width: 1),
                    ),
                    child: Column(
                      children: _addons.keys
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final key = entry.value;
                        final last =
                            entry.key == _addons.length - 1;
                        final sel = _addons[key]!;
                        return Column(children: [
                          GestureDetector(
                            onTap: () => setState(
                                () => _addons[key] = !sel),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              color: sel
                                  ? _cobalt.withOpacity(0.06)
                                  : BauhausTheme.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12),
                              child: Row(children: [
                                // Custom checkbox
                                AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: sel
                                            ? _cobalt
                                            : BauhausTheme
                                                .primaryBlack,
                                        width: 1),
                                    color: sel
                                        ? _cobalt
                                        : BauhausTheme.white,
                                  ),
                                  child: sel
                                      ? const Icon(Icons.check,
                                          size: 14,
                                          color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      key.toUpperCase(),
                                      style: _sg(
                                          13,
                                          FontWeight.w700,
                                          BauhausTheme
                                              .primaryBlack,
                                          spacing: 0.3)),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                  color: _cobalt,
                                  child: Text(
                                      '+₹${_addonPrices[key]?.toStringAsFixed(0)}',
                                      style: _sg(
                                          12,
                                          FontWeight.w800,
                                          BauhausTheme.white)),
                                ),
                              ]),
                            ),
                          ),
                          if (!last)
                            Container(
                                height: 1,
                                color: BauhausTheme.primaryBlack),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── QUANTITY ─────────────────────────────────
                _sectionHeader('QUANTITY'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: BauhausTheme.lightGrey,
                          borderRadius: BorderRadius.circular(
                              BauhausTheme.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _qtyBtn(Icons.remove, () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            }),
                            SizedBox(
                              width: 40,
                              child: Text('$_quantity',
                                  textAlign: TextAlign.center,
                                  style: _sg(18, FontWeight.w700,
                                      BauhausTheme.primaryBlack)),
                            ),
                            _qtyBtn(Icons.add,
                                () => setState(() => _quantity++)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TOTAL',
                              style: _sg(10, FontWeight.w700,
                                  BauhausTheme.mediumGrey,
                                  spacing: 0.5)),
                          Text(
                            '₹${_total(item.price).toStringAsFixed(0)}',
                            style: BauhausTheme.body(
                                size: 24,
                                weight: FontWeight.w600,
                                color: BauhausTheme.accentRed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── PAYMENT METHOD ───────────────────────────
                _sectionHeader('PAYMENT METHOD'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: BauhausTheme.patternGrey, width: 1),
                    ),
                    child: Row(children: [
                      _payToggle('PAY ONLINE', 'online',
                          Icons.credit_card_outlined),
                      Container(
                          width: 1,
                          height: 56,
                          color: BauhausTheme.primaryBlack),
                      _payToggle('CASH ON DELIVERY', 'cod',
                          Icons.payments_outlined),
                    ]),
                  ),
                ),

                // ── ADD TO CART ──────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      final inCart = cart.items
                              .indexWhere(
                                  (i) => i.item.id == item.id) >
                          -1;
                      return GestureDetector(
                        onTap: () => inCart
                            ? context.go('/order')
                            : cart.addItem(item),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: BauhausTheme.primaryBlack, width: 1.5),
                            borderRadius: BorderRadius.circular(
                                BauhausTheme.radiusMd),
                            color: inCart
                                ? BauhausTheme.lightGrey
                                : BauhausTheme.white,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                inCart
                                    ? Icons.shopping_cart
                                    : Icons.add_shopping_cart,
                                size: 18,
                                color: BauhausTheme.primaryBlack,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                inCart
                                    ? 'VIEW CART'
                                    : 'ADD TO CART',
                                style: _sg(
                                    14,
                                    FontWeight.w800,
                                    BauhausTheme.primaryBlack,
                                    spacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── PLACE ORDER ──────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GestureDetector(
                    onTap: () => _showOrderDialog(context, item),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: BauhausTheme.accentRed,
                        borderRadius:
                            BorderRadius.circular(BauhausTheme.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text('ADD TO ORDER',
                              style: _sg(
                                  15,
                                  FontWeight.w600,
                                  BauhausTheme.white,
                                  spacing: 0.5)),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  BauhausTheme.radiusSm),
                            ),
                            child: Text(
                              '₹${_total(item.price).toStringAsFixed(0)}',
                              style: _sg(14, FontWeight.w800,
                                  BauhausTheme.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: BauhausTheme.patternGrey),

                // ── RECOMMENDED ──────────────────────────────
                _sectionHeader('YOU MAY ALSO LIKE'),
                SizedBox(
                  height: 158,
                  child: Consumer<MenuProvider>(
                    builder: (_, mp, __) {
                      final recs = mp.items
                          .where((i) =>
                              i.category == item.category &&
                              i.id != item.id)
                          .take(5)
                          .toList();
                      if (recs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                              'No recommendations available',
                              style: _sg(12, FontWeight.w500,
                                  BauhausTheme.mediumGrey)),
                        );
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 16),
                        itemCount: recs.length,
                        itemBuilder: (ctx, i) {
                          final rec = recs[i];
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => context
                                  .push('/product/${rec.id}'),
                              child: Container(
                                width: 115,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: BauhausTheme
                                          .primaryBlack,
                                      width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: rec.imageUrl != null
                                          ? Image.network(
                                              rec.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_,
                                                      __,
                                                      ___) =>
                                                  _imagePlaceholder())
                                          : _imagePlaceholder(),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            rec.name,
                                            maxLines: 1,
                                            overflow: TextOverflow
                                                .ellipsis,
                                            style: _sg(
                                                10,
                                                FontWeight.w700,
                                                BauhausTheme
                                                    .primaryBlack),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6,
                                                vertical: 3),
                                            color: _cobalt,
                                            child: Text(
                                              '₹${rec.price.toStringAsFixed(0)}',
                                              style: _sg(
                                                  9,
                                                  FontWeight.w800,
                                                  BauhausTheme
                                                      .white),
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
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────

  Widget _label(String t) => Text(t,
      style: _sg(11, FontWeight.w700, BauhausTheme.primaryBlack,
          spacing: 0.5));

  Widget _sectionHeader(String title) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: const BoxDecoration(
          border:
              Border(left: BorderSide(color: BauhausTheme.accentRed, width: 4)),
        ),
        child: Text(title,
            style: _sg(12, FontWeight.w800, BauhausTheme.primaryBlack,
                spacing: 1.0)),
      );

  Widget _solidTag(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(BauhausTheme.radiusPill),
        ),
        child: Text(label,
            style: _sg(10, FontWeight.w700, color, spacing: 0.5)),
      );

  Widget _nutCell(String label, String value) => Expanded(
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: BauhausTheme.lightGrey,
            borderRadius: BorderRadius.circular(BauhausTheme.radiusSm),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: _sg(8, FontWeight.w700, BauhausTheme.mediumGrey,
                      spacing: 0.3)),
              const SizedBox(height: 2),
              Text(value,
                  style: _sg(
                      14, FontWeight.w800, BauhausTheme.primaryBlack)),
            ],
          ),
        ),
      );

  Widget _payToggle(String label, String value, IconData icon) =>
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _paymentMethod = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            color: _paymentMethod == value
                ? BauhausTheme.primaryBlack
                : BauhausTheme.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: _paymentMethod == value
                        ? BauhausTheme.white
                        : BauhausTheme.primaryBlack),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: _sg(
                          11,
                          FontWeight.w700,
                          _paymentMethod == value
                              ? BauhausTheme.white
                              : BauhausTheme.primaryBlack)),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BauhausTheme.radiusPill),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(icon, size: 18, color: BauhausTheme.primaryBlack),
          ),
        ),
      );

  Widget _imagePlaceholder() => Container(
        color: BauhausTheme.patternGrey,
        child: const Center(
          child: Icon(Icons.image, size: 60, color: BauhausTheme.mediumGrey),
        ),
      );
}
