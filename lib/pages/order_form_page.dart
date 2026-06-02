import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/bauhaus_button.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ORDER SUMMARY',
          style: GoogleFonts.chivo(
              fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        backgroundColor: BauhausTheme.white,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Cart is empty', style: GoogleFonts.chivo(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Browse Menu'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items Section
                Text(
                  'ORDER ITEMS',
                  style: GoogleFonts.chivo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.primaryBlack,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 1),
                  ),
                  child: Column(
                    children: cart.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cartItem = entry.value;
                      final isLast = index == cart.items.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.item.name.toUpperCase(),
                                        style: GoogleFonts.chivo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: BauhausTheme.primaryBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'x${cartItem.quantity} @ ₹${cartItem.item.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.chivo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: BauhausTheme.mediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${cartItem.subtotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.chivo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BauhausTheme.accentRed,
                                  ),
                                ),
                              ],
                            ),
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

                // Total Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: BauhausTheme.accentRed, width: 2),
                    color: BauhausTheme.accentRed.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.chivo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '₹${cart.total.toStringAsFixed(0)}',
                        style: GoogleFonts.chivo(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pay Button
                BauhausButton(
                  label: 'PROCEED TO PAY',
                  onPressed: _isSubmitting
                      ? null
                      : () => _showPaymentDialog(context, cart.total),
                  height: 48,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Continue Shopping',
                      style: GoogleFonts.chivo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BauhausTheme.mediumGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, double totalAmount) {
    late TextEditingController nameCtrl;
    late TextEditingController phoneCtrl;
    String? selectedOrderType;
    String selectedPayment = 'cod';

    nameCtrl = TextEditingController();
    phoneCtrl = TextEditingController();

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
                // Name Field
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
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enter your name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
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
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enter your phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Type
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
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 2),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('DINE-IN'),
                        value: 'dine_in',
                        groupValue: selectedOrderType,
                        onChanged: (value) =>
                            setState(() => selectedOrderType = value),
                      ),
                      const Divider(
                          height: 0,
                          thickness: 1,
                          color: BauhausTheme.primaryBlack),
                      RadioListTile<String>(
                        title: const Text('TAKEAWAY'),
                        value: 'takeaway',
                        groupValue: selectedOrderType,
                        onChanged: (value) =>
                            setState(() => selectedOrderType = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                Text(
                  'PAYMENT METHOD',
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
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 2),
                  ),
                  child: Column(
                    children: [
                      _PaymentTile(
                        icon: '💵',
                        label: 'CASH ON DELIVERY',
                        sublabel: 'Pay when your order arrives',
                        value: 'cod',
                        selected: selectedPayment == 'cod',
                        onTap: () => setState(() => selectedPayment = 'cod'),
                      ),
                      const Divider(
                          height: 0,
                          thickness: 1,
                          color: BauhausTheme.primaryBlack),
                      _PaymentTile(
                        icon: '💳',
                        label: 'ONLINE PAYMENT',
                        sublabel: 'UPI / Card / Net Banking',
                        value: 'online',
                        selected: selectedPayment == 'online',
                        onTap: () =>
                            setState(() => selectedPayment = 'online'),
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
                // Validate fields
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                  return;
                }
                if (phoneCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter your phone number')),
                  );
                  return;
                }
                if (selectedOrderType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select order type')),
                  );
                  return;
                }

                // Place order
                setState(() => _isSubmitting = true);
                try {
                  final cart = this.context.read<CartProvider>();
                  final order = this.context.read<OrderProvider>();

                  final orderId = await order.createOrder(
                    customerName: nameCtrl.text,
                    customerPhone: phoneCtrl.text,
                    orderType: selectedOrderType!,
                    paymentMethod: selectedPayment,
                    items: cart.items.map((item) {
                      return {
                        'menu_item_id': item.item.id,
                        'name': item.item.name,
                        'quantity': item.quantity,
                        'price': item.item.price,
                      };
                    }).toList(),
                    totalPrice: totalAmount,
                  );

                  cart.clear();
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    this.context.go('/confirmation?orderId=$orderId');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isSubmitting = false);
                  }
                }
              },
              child: Text(
                _isSubmitting ? 'PROCESSING...' : 'PLACE ORDER',
                style: GoogleFonts.chivo(
                  fontWeight: FontWeight.w700,
                  color: BauhausTheme.accentRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        color: selected
            ? BauhausTheme.primaryBlack
            : BauhausTheme.white,
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.chivo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? BauhausTheme.white : BauhausTheme.primaryBlack,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.chivo(
                      fontSize: 11,
                      color: selected ? Colors.white70 : BauhausTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: BauhausTheme.white, size: 18),
          ],
        ),
      ),
    );
  }
}
