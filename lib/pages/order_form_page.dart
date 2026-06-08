import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(
        title: Text(
          'ORDER SUMMARY',
          style: _sg(22, FontWeight.w800, BauhausTheme.primaryBlack,
              spacing: 0.5),
        ),
        backgroundColor: BauhausTheme.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: BauhausTheme.primaryBlack),
        ),
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
                  Text('Cart is empty',
                      style: _sg(18, FontWeight.w600, Colors.grey)),
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
                // ── ORDER ITEMS ───────────────────────────────────
                Text('ORDER ITEMS',
                    style: _sg(13, FontWeight.w700,
                        BauhausTheme.primaryBlack,
                        spacing: 0.5)),
                const SizedBox(height: 10),
                Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                        BorderSide(color: BauhausTheme.primaryBlack, width: 2)),
                  ),
                  child: Column(
                    children: cart.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ci = entry.value;
                      final isLast = index == cart.items.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(ci.item.name.toUpperCase(),
                                          style: _sg(12, FontWeight.w700,
                                              BauhausTheme.primaryBlack)),
                                      Text(
                                          'x${ci.quantity} @ ₹${ci.item.price.toStringAsFixed(0)}',
                                          style: _sg(11, FontWeight.w400,
                                              BauhausTheme.mediumGrey)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${ci.subtotal.toStringAsFixed(0)}',
                                  style: _sg(13, FontWeight.w800,
                                      BauhausTheme.accentRed),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            const Divider(
                                color: BauhausTheme.primaryBlack,
                                thickness: 1,
                                height: 0),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── TOTAL ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BauhausTheme.accentRed, width: 2),
                    color:
                        BauhausTheme.accentRed.withValues(alpha: 0.07),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL',
                          style: _sg(16, FontWeight.w800,
                              BauhausTheme.primaryBlack,
                              spacing: 1)),
                      Text('₹${cart.total.toStringAsFixed(0)}',
                          style: _sg(22, FontWeight.w800,
                              BauhausTheme.accentRed)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                BauhausButton(
                  label: 'PROCEED TO PAY',
                  onPressed: _isSubmitting
                      ? null
                      : () => _showCustomerDialog(context, cart.total),
                  height: 48,
                ),
                const SizedBox(height: 12),

                // Cancel
                GestureDetector(
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('CANCEL ORDER',
                            style: _sg(
                                16, FontWeight.w800, BauhausTheme.primaryBlack)),
                        content: Text(
                            'Clear your cart and go back to the menu?',
                            style: _sg(13, FontWeight.w400,
                                BauhausTheme.primaryBlack)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('NO',
                                  style: _sg(13, FontWeight.w700,
                                      BauhausTheme.mediumGrey))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('YES, CANCEL',
                                  style: _sg(13, FontWeight.w700,
                                      Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true && mounted) {
                      context.read<CartProvider>().clear();
                      context.go('/');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade700, width: 1.5),
                      color: Colors.red.withValues(alpha: 0.05),
                    ),
                    child: Center(
                      child: Text('CANCEL ORDER',
                          style: _sg(13, FontWeight.w800, Colors.red.shade700,
                              spacing: 0.5)),
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

  void _showCustomerDialog(BuildContext context, double totalAmount) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final landmarkCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();

    String? selectedOrderType;
    String selectedPayment = 'online';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final isDelivery = selectedOrderType == 'delivery';

          // Force online payment for delivery
          if (isDelivery && selectedPayment == 'cod') {
            selectedPayment = 'online';
          }

          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text('CUSTOMER DETAILS',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── NAME ────────────────────────────────────
                    _label('FULL NAME'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z ]')),
                      ],
                      decoration: _inputDeco('Enter your name'),
                    ),
                    const SizedBox(height: 14),

                    // ── PHONE ───────────────────────────────────
                    _label('PHONE NUMBER'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _inputDeco('10-digit mobile number',
                          counter: true),
                    ),
                    const SizedBox(height: 14),

                    // ── ORDER TYPE ──────────────────────────────
                    _label('ORDER TYPE'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border.fromBorderSide(BorderSide(
                            color: BauhausTheme.primaryBlack, width: 2)),
                      ),
                      child: Column(
                        children: [
                          _RadioRow(
                            icon: Icons.restaurant,
                            label: 'DINE IN',
                            sublabel: 'Eat at the restaurant',
                            value: 'dine_in',
                            groupValue: selectedOrderType,
                            onChanged: (v) =>
                                setDialog(() => selectedOrderType = v),
                          ),
                          const Divider(
                              height: 0,
                              thickness: 1,
                              color: BauhausTheme.primaryBlack),
                          _RadioRow(
                            icon: Icons.takeout_dining,
                            label: 'TAKEAWAY',
                            sublabel: 'Pick up your order',
                            value: 'takeaway',
                            groupValue: selectedOrderType,
                            onChanged: (v) =>
                                setDialog(() => selectedOrderType = v),
                          ),
                          const Divider(
                              height: 0,
                              thickness: 1,
                              color: BauhausTheme.primaryBlack),
                          _RadioRow(
                            icon: Icons.delivery_dining,
                            label: 'DELIVERY',
                            sublabel: 'Delivered to your address',
                            value: 'delivery',
                            groupValue: selectedOrderType,
                            onChanged: (v) =>
                                setDialog(() => selectedOrderType = v),
                          ),
                        ],
                      ),
                    ),

                    // ── DELIVERY ADDRESS (animated expand) ──────
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: isDelivery
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _DeliveryAddressSection(
                          addressCtrl: addressCtrl,
                          landmarkCtrl: landmarkCtrl,
                          cityCtrl: cityCtrl,
                          pincodeCtrl: pincodeCtrl,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── PAYMENT ─────────────────────────────────
                    _label('PAYMENT METHOD'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border.fromBorderSide(BorderSide(
                            color: BauhausTheme.primaryBlack, width: 2)),
                      ),
                      child: Column(
                        children: [
                          _PaymentTile(
                            icon: '💵',
                            label: 'CASH ON DELIVERY',
                            sublabel: isDelivery
                                ? 'Not available for delivery'
                                : 'Pay at the counter',
                            value: 'cod',
                            selected: selectedPayment == 'cod',
                            disabled: isDelivery,
                            onTap: isDelivery
                                ? null
                                : () =>
                                    setDialog(() => selectedPayment = 'cod'),
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
                            disabled: false,
                            onTap: () =>
                                setDialog(() => selectedPayment = 'online'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('CANCEL',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        color: BauhausTheme.mediumGrey)),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        // Validation
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();

                        if (name.isEmpty) {
                          _snack(ctx, 'Please enter your name');
                          return;
                        }
                        if (phone.length < 10) {
                          _snack(ctx, 'Enter a valid 10-digit phone number');
                          return;
                        }
                        if (selectedOrderType == null) {
                          _snack(ctx, 'Please select an order type');
                          return;
                        }

                        Map<String, String>? deliveryAddress;
                        if (isDelivery) {
                          if (addressCtrl.text.trim().isEmpty) {
                            _snack(ctx, 'Please enter your delivery address');
                            return;
                          }
                          if (cityCtrl.text.trim().isEmpty) {
                            _snack(ctx, 'Please enter your city');
                            return;
                          }
                          if (pincodeCtrl.text.trim().length < 6) {
                            _snack(ctx, 'Please enter a valid 6-digit pincode');
                            return;
                          }
                          deliveryAddress = {
                            'address': addressCtrl.text.trim(),
                            'landmark': landmarkCtrl.text.trim(),
                            'city': cityCtrl.text.trim(),
                            'pincode': pincodeCtrl.text.trim(),
                          };
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          final cart =
                              this.context.read<CartProvider>();
                          final orderProvider =
                              this.context.read<OrderProvider>();

                          final orderId =
                              await orderProvider.createOrder(
                            customerName: name,
                            customerPhone: phone,
                            orderType: selectedOrderType!,
                            paymentMethod: selectedPayment,
                            items: cart.items.map((item) => {
                                  'menu_item_id': item.item.id,
                                  'name': item.item.name,
                                  'quantity': item.quantity,
                                  'price': item.item.price,
                                }).toList(),
                            totalPrice: totalAmount,
                            deliveryAddress: deliveryAddress,
                          );

                          cart.clear();
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            this
                                .context
                                .go('/confirmation?orderId=$orderId');
                          }
                        } catch (e) {
                          if (mounted) {
                            _snack(this.context, 'Error: $e');
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      },
                child: Text(
                  _isSubmitting ? 'PROCESSING...' : 'PLACE ORDER',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w800,
                      color: BauhausTheme.accentRed),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: BauhausTheme.primaryBlack,
          letterSpacing: 0.6,
        ),
      );

  InputDecoration _inputDeco(String hint, {bool counter = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13, color: BauhausTheme.mediumGrey),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        counterText: counter ? null : '',
      );

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery address section
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryAddressSection extends StatelessWidget {
  final TextEditingController addressCtrl, landmarkCtrl, cityCtrl, pincodeCtrl;

  const _DeliveryAddressSection({
    required this.addressCtrl,
    required this.landmarkCtrl,
    required this.cityCtrl,
    required this.pincodeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1565C0), width: 2),
        color: const Color(0xFF1565C0).withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Color(0xFF1565C0), size: 18),
              const SizedBox(width: 6),
              Text(
                'DELIVERY ADDRESS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1565C0),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressCtrl,
            maxLines: 2,
            decoration: _deco('Building / Street / Area *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: landmarkCtrl,
            decoration: _deco('Landmark (optional)'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  decoration: _deco('City *'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _deco('Pincode *', counter: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String hint, {bool counter = false}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 12, color: Colors.grey.shade500),
        border:
            const OutlineInputBorder(borderRadius: BorderRadius.zero),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        counterText: counter ? null : '',
        isDense: true,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Radio row for order type
// ─────────────────────────────────────────────────────────────────────────────

class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String label, sublabel, value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: selected ? BauhausTheme.primaryBlack : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : BauhausTheme.primaryBlack,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : BauhausTheme.primaryBlack,
                      )),
                  Text(sublabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: selected ? Colors.white70 : Colors.grey,
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment tile
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final String icon, label, sublabel, value;
  final bool selected, disabled;
  final VoidCallback? onTap;

  const _PaymentTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: disabled
            ? Colors.grey.shade100
            : selected
                ? BauhausTheme.primaryBlack
                : BauhausTheme.white,
        child: Row(
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 20,
                    color: disabled ? Colors.grey.shade400 : null)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? Colors.grey.shade400
                          : selected
                              ? Colors.white
                              : BauhausTheme.primaryBlack,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: disabled
                          ? Colors.grey.shade400
                          : selected
                              ? Colors.white70
                              : BauhausTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (disabled)
              const Icon(Icons.block, color: Colors.grey, size: 16)
            else if (selected)
              const Icon(Icons.check_circle,
                  color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
