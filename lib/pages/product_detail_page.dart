import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/bauhaus_button.dart';

class ProductDetailPage extends StatefulWidget {
  final String itemId;
  final String tableId;
  const ProductDetailPage({super.key, required this.itemId, required this.tableId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  // Customization options
  final Map<String, bool> _selectedCustomizations = {
    'Extra Avocado': false,
    'Quinoa Base': false,
    'Extra Protein': false,
  };

  final Map<String, double> _customizationPrices = {
    'Extra Avocado': 20,
    'Quinoa Base': 50,
    'Extra Protein': 30,
  };

  // Standard includes
  final List<String> _standardIncludes = [
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

  double _calculateCustomizationCost() {
    return _selectedCustomizations.entries
        .where((e) => e.value)
        .fold(0, (sum, e) => sum + (_customizationPrices[e.key] ?? 0));
  }

  double _calculateTotalPrice(double basePrice) {
    return (basePrice + _calculateCustomizationCost()) * _quantity;
  }


  void _showBuyNowDialog(BuildContext context, dynamic item) {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    String? selectedOrderType;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'CUSTOMER INFORMATION',
            style: GoogleFonts.chivo(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAME',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.primaryBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Enter your name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PHONE NUMBER',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.primaryBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Enter your phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ORDER TYPE',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.primaryBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: BauhausTheme.primaryBlack, width: 2),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('DINE-IN'),
                        value: 'dine_in',
                        groupValue: selectedOrderType,
                        onChanged: (value) => setState(() => selectedOrderType = value),
                      ),
                      const Divider(height: 0, thickness: 1, color: BauhausTheme.primaryBlack),
                      RadioListTile<String>(
                        title: const Text('TAKEAWAY'),
                        value: 'takeaway',
                        groupValue: selectedOrderType,
                        onChanged: (value) => setState(() => selectedOrderType = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: BauhausTheme.accentRed, width: 2),
                    color: BauhausTheme.accentRed.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PAYMENT',
                        style: GoogleFonts.chivo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.primaryBlack,
                        ),
                      ),
                      Text(
                        '💵 CASH ON DELIVERY',
                        style: GoogleFonts.chivo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: GoogleFonts.chivo(
                  fontWeight: FontWeight.w700,
                  color: BauhausTheme.mediumGrey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Please enter your name')),
                    );
                  }
                  return;
                }
                if (_phoneCtrl.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Please enter your phone number')),
                    );
                  }
                  return;
                }
                if (selectedOrderType == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Please select order type')),
                    );
                  }
                  return;
                }
                final name = _nameCtrl.text;
                final phone = _phoneCtrl.text;
                final orderType = selectedOrderType!;
                const paymentMethod = 'cod';

                try {
                  final customizationCost = _calculateCustomizationCost();
                  final itemTotalPrice = (item.price + customizationCost) * _quantity;

                  final orderId = await this.context.read<OrderProvider>().createOrder(
                        customerName: name,
                        customerPhone: phone,
                        orderType: orderType,
                        paymentMethod: paymentMethod,
                        items: [
                          {
                            'menu_item_id': item.id,
                            'name': item.name,
                            'quantity': _quantity,
                            'price': item.price + customizationCost,
                            'customizations': _selectedCustomizations.entries
                                .where((e) => e.value)
                                .map((e) => '${e.key} (+₹${_customizationPrices[e.key]})')
                                .toList()
                                .join(', '),
                          }
                        ],
                        totalPrice: itemTotalPrice,
                      );

                  if (mounted) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    this.context.go('/confirmation?orderId=$orderId');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('PLACE ORDER'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: BauhausTheme.white,
        elevation: 0,
        automaticallyImplyLeading: true,
      ),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, _) {
          final itemIndex = menuProvider.items.indexWhere(
            (i) => i.id == widget.itemId,
          );

          if (itemIndex == -1) {
            return const Center(child: Text('Product not found'));
          }

          final item = menuProvider.items[itemIndex];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Header with left border
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: BauhausTheme.accentRed,
                        width: 8,
                      ),
                    ),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: GoogleFonts.chivo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BauhausTheme.primaryBlack,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Divider(
                  color: BauhausTheme.primaryBlack,
                  thickness: 2,
                  height: 0,
                ),
                // Product Image
                Container(
                  height: 280,
                  color: BauhausTheme.patternGrey,
                  child: Stack(
                    children: [
                      item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 80),
                            )
                          : const Icon(Icons.image, size: 80),
                      // VEG badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: BauhausTheme.accentRed,
                          child: Text(
                            'VEG',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Product Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        item.name.toUpperCase(),
                        style: GoogleFonts.chivo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      if (item.description.isNotEmpty) ...[
                        Text(
                          item.description,
                          style: GoogleFonts.chivo(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Price and Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: Colors.amber[300],
                            child: Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.chivo(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: BauhausTheme.primaryBlack,
                              ),
                            ),
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, _) {
                              final cartItems = cartProvider.items;
                              final idx = cartItems.indexWhere((ci) => ci.item.id == item.id);
                              final count = idx > -1 ? cartItems[idx].quantity : 0;

                              if (count == 0) {
                                return GestureDetector(
                                  onTap: () => cartProvider.addItem(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    color: BauhausTheme.primaryBlack,
                                    child: Text(
                                      'ADD TO CART',
                                      style: GoogleFonts.chivo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: BauhausTheme.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: BauhausTheme.primaryBlack, width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (count > 1) {
                                          cartProvider.updateQuantity(item.id, count - 1);
                                        } else {
                                          cartProvider.removeItem(item.id);
                                        }
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        color: BauhausTheme.primaryBlack,
                                        child: const Icon(Icons.remove, color: BauhausTheme.white, size: 18),
                                      ),
                                    ),
                                    Container(
                                      width: 50,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(color: BauhausTheme.primaryBlack, width: 1),
                                          right: BorderSide(color: BauhausTheme.primaryBlack, width: 1),
                                        ),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: GoogleFonts.chivo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: BauhausTheme.primaryBlack,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => cartProvider.addItem(item),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        color: BauhausTheme.primaryBlack,
                                        child: const Icon(Icons.add, color: BauhausTheme.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Nutrition Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: BauhausTheme.accentRed, width: 2),
                              color: BauhausTheme.accentRed.withOpacity(0.1),
                            ),
                            child: Text(
                              'PLANT BASED',
                              style: GoogleFonts.chivo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: BauhausTheme.accentRed,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 2),
                              color: Colors.green.withOpacity(0.1),
                            ),
                            child: Text(
                              'HIGH PROTEIN',
                              style: GoogleFonts.chivo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Nutrition Info Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
                          color: BauhausTheme.lightGrey,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUTRITION (per serving)',
                              style: GoogleFonts.chivo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BauhausTheme.primaryBlack,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.5,
                              children: const [
                                _NutritionCell('CALORIES', '280'),
                                _NutritionCell('PROTEIN', '12.5g'),
                                _NutritionCell('CARBS', '32g'),
                                _NutritionCell('FAT', '8g'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Standard Includes Section
                      Text(
                        'STANDARD INCLUDES',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
                          color: BauhausTheme.lightGrey,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _standardIncludes.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    item,
                                    style: GoogleFonts.chivo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: BauhausTheme.primaryBlack,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add-ons/Customization Section
                      Text(
                        'ADD-ONS (Optional)',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
                        ),
                        child: Column(
                          children: _selectedCustomizations.keys.map((customization) {
                            final isLast = _selectedCustomizations.keys.last == customization;
                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: Text(
                                    customization.toUpperCase(),
                                    style: GoogleFonts.chivo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: BauhausTheme.primaryBlack,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '+₹${_customizationPrices[customization]?.toStringAsFixed(0)}',
                                    style: GoogleFonts.chivo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: BauhausTheme.accentRed,
                                    ),
                                  ),
                                  value: _selectedCustomizations[customization]!,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCustomizations[customization] = value ?? false;
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  dense: true,
                                  activeColor: BauhausTheme.accentRed,
                                ),
                                if (!isLast)
                                  const Divider(
                                    color: BauhausTheme.primaryBlack,
                                    thickness: 1,
                                    height: 0,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BauhausButton(
                        label: 'BUY NOW',
                        onPressed: () => _showBuyNowDialog(context, item),
                        height: 44,
                      ),
                      const SizedBox(height: 20),
                      // Recommended Products
                      Text(
                        'RECOMMENDED',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: Consumer<MenuProvider>(
                          builder: (context, menuProvider, _) {
                            final recommended = menuProvider.items
                                .where((i) => i.category == item.category && i.id != item.id)
                                .take(3)
                                .toList();

                            if (recommended.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: BauhausTheme.primaryBlack,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'No recommendations available',
                                    style: GoogleFonts.chivo(
                                      fontSize: 12,
                                      color: BauhausTheme.mediumGrey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommended.length,
                              itemBuilder: (context, index) {
                                final rec = recommended[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailPage(
                                            itemId: rec.id,
                                            tableId: widget.tableId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: BauhausTheme.primaryBlack,
                                          width: 1,
                                        ),
                                        color: BauhausTheme.white,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              color: BauhausTheme.patternGrey,
                                              child: rec.imageUrl != null
                                                  ? Image.network(
                                                      rec.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    )
                                                  : const Icon(Icons.image, size: 40),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rec.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.chivo(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${rec.price.toStringAsFixed(0)}',
                                                  style: GoogleFonts.chivo(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: BauhausTheme.accentRed,
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NutritionCell extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: BauhausTheme.primaryBlack, width: 1),
        color: BauhausTheme.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.chivo(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: BauhausTheme.mediumGrey,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.chivo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BauhausTheme.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}
