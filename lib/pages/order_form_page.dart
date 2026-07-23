import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/service_hours_service.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/status_animation.dart';
import '../widgets/bauhaus_button.dart';
import '../widgets/location_picker.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  bool _isSubmitting = false;

  TextStyle _sg(double size, FontWeight weight, Color color,
          {double? spacing}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: BauhausTheme.heading(size: 22, weight: FontWeight.w700),
        ),
        backgroundColor: BauhausTheme.background,
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
                  decoration: BoxDecoration(
                    color: BauhausTheme.white,
                    borderRadius:
                        BorderRadius.circular(BauhausTheme.radiusLg),
                    boxShadow: BauhausTheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
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
                                      Text(ci.item.name,
                                          style: BauhausTheme.heading(
                                              size: 15,
                                              weight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (ci.item.discountPercent > 0) ...[
                                            Text(
                                                '₹${ci.item.compareAtPrice.toStringAsFixed(0)}',
                                                style: _sg(12,
                                                        FontWeight.w400,
                                                        BauhausTheme
                                                            .mediumGrey)
                                                    .copyWith(
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough)),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                              'x${ci.quantity} @ ₹${ci.item.price.toStringAsFixed(0)}',
                                              style: _sg(12, FontWeight.w400,
                                                  BauhausTheme.mediumGrey)),
                                        ],
                                      ),
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
                                color: BauhausTheme.patternGrey, thickness: 1,
                                height: 0),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── TOTAL ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BauhausTheme.white,
                    borderRadius:
                        BorderRadius.circular(BauhausTheme.radiusLg),
                    boxShadow: BauhausTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total',
                              style: BauhausTheme.heading(
                                  size: 22, weight: FontWeight.w700)),
                          Text('₹${cart.total.toStringAsFixed(0)}',
                              style: BauhausTheme.body(
                                  size: 24,
                                  weight: FontWeight.w600,
                                  color: BauhausTheme.accentRed)),
                        ],
                      ),
                      Builder(builder: (context) {
                        final saved = cart.items.fold<double>(
                            0,
                            (s, ci) => s +
                                (ci.item.discountPercent > 0
                                    ? (ci.item.compareAtPrice -
                                            ci.item.price) *
                                        ci.quantity
                                    : 0));
                        if (saved <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              'You saved ₹${saved.toStringAsFixed(0)}',
                              style: _sg(12, FontWeight.w700,
                                  const Color(0xFF2E7D32))),
                        );
                      }),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(BauhausTheme.radiusMd),
                      border:
                          Border.all(color: BauhausTheme.patternGrey, width: 1),
                    ),
                    child: Center(
                      child: Text('Cancel Order',
                          style: _sg(14, FontWeight.w600,
                              BauhausTheme.mediumGrey,
                              spacing: 0.2)),
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

    // Precise delivery pin (from the map picker).
    double? pickedLat;
    double? pickedLng;
    String? mapsLink;

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

          // Service-hours availability per order type.
          final hours = ServiceHoursService();
          String subFor(String base, String type) {
            if (hours.isAvailable(type)) return base;
            final lbl = hours.label(type);
            return (lbl.isEmpty || lbl == 'Currently unavailable')
                ? 'Currently unavailable'
                : 'Available $lbl';
          }

          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text('CUSTOMER DETAILS',
                style: GoogleFonts.inter(
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
                            color: BauhausTheme.patternGrey, width: 1)),
                      ),
                      child: Column(
                        children: [
                          _RadioRow(
                            icon: Icons.restaurant,
                            label: 'DINE IN',
                            sublabel:
                                subFor('Eat at the restaurant', 'dine_in'),
                            value: 'dine_in',
                            groupValue: selectedOrderType,
                            disabled: !hours.isAvailable('dine_in'),
                            onChanged: (v) =>
                                setDialog(() => selectedOrderType = v),
                          ),
                          const Divider(
                              height: 0,
                              thickness: 1, color: BauhausTheme.patternGrey),
                          _RadioRow(
                            icon: Icons.takeout_dining,
                            label: 'TAKEAWAY',
                            sublabel:
                                subFor('Pick up your order', 'takeaway'),
                            value: 'takeaway',
                            groupValue: selectedOrderType,
                            disabled: !hours.isAvailable('takeaway'),
                            onChanged: (v) =>
                                setDialog(() => selectedOrderType = v),
                          ),
                          const Divider(
                              height: 0,
                              thickness: 1, color: BauhausTheme.patternGrey),
                          _RadioRow(
                            icon: Icons.delivery_dining,
                            label: 'DELIVERY',
                            sublabel:
                                subFor('Delivered to your address', 'delivery'),
                            value: 'delivery',
                            groupValue: selectedOrderType,
                            disabled: !hours.isAvailable('delivery'),
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
                          hasPin: pickedLat != null,
                          onPickLocation: () async {
                            final result = await Navigator.of(ctx)
                                .push<LocationPickerResult>(
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => LocationPickerPage(
                                  initialLocation: pickedLat != null
                                      ? LatLng(pickedLat!, pickedLng!)
                                      : null,
                                ),
                              ),
                            );
                            if (result != null) {
                              setDialog(() {
                                pickedLat = result.latitude;
                                pickedLng = result.longitude;
                                mapsLink = result.mapsLink;
                                if (result.addressLine.isNotEmpty &&
                                    addressCtrl.text.trim().isEmpty) {
                                  addressCtrl.text = result.addressLine;
                                }
                                if (result.city.isNotEmpty) {
                                  cityCtrl.text = result.city;
                                }
                                if (result.pincode.isNotEmpty) {
                                  pincodeCtrl.text = result.pincode;
                                }
                              });
                            }
                          },
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
                            color: BauhausTheme.patternGrey, width: 1)),
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
                              thickness: 1, color: BauhausTheme.patternGrey),
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
                    style: GoogleFonts.inter(
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
                        if (!ServiceHoursService()
                            .isAvailable(selectedOrderType!)) {
                          _snack(
                              ctx,
                              '${selectedOrderType!.replaceAll('_', ' ')} '
                              'is not available right now');
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
                            // Map pin is optional — extra precision when set.
                            if (pickedLat != null)
                              'latitude': pickedLat!.toStringAsFixed(7),
                            if (pickedLng != null)
                              'longitude': pickedLng!.toStringAsFixed(7),
                            if (mapsLink != null) 'maps_link': mapsLink!,
                          };
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          final cart =
                              this.context.read<CartProvider>();
                          final orderProvider =
                              this.context.read<OrderProvider>();

                          // Server computes the price from item ids + quantity —
                          // the client never sends prices/totals.
                          final serverItems = cart.items
                              .map((item) => {
                                    'menu_item_id': item.item.id,
                                    'quantity': item.quantity,
                                  })
                              .toList();

                          final String orderId;
                          if (selectedPayment == 'online') {
                            final result =
                                await orderProvider.placeOnlineOrder(
                              customerName: name,
                              customerPhone: phone,
                              orderType: selectedOrderType!,
                              items: serverItems,
                              deliveryAddress: deliveryAddress,
                            );
                            if (!result.success) {
                              if (mounted) {
                                _showPaymentFailed(result.message);
                              }
                              return; // finally{} resets _isSubmitting
                            }
                            orderId = result.orderNumber ?? '';
                          } else {
                            orderId = await orderProvider.placeCodOrder(
                              customerName: name,
                              customerPhone: phone,
                              orderType: selectedOrderType!,
                              items: serverItems,
                              deliveryAddress: deliveryAddress,
                            );
                          }

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
                  style: GoogleFonts.inter(
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

  void _showPaymentFailed(String message) {
    showDialog(
      context: context,
      builder: (_) => _PaymentFailedDialog(message: message),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: BauhausTheme.primaryBlack,
          letterSpacing: 0.6,
        ),
      );

  InputDecoration _inputDeco(String hint, {bool counter = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            fontSize: 13, color: BauhausTheme.mediumGrey),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
  final bool hasPin;
  final VoidCallback onPickLocation;

  const _DeliveryAddressSection({
    required this.addressCtrl,
    required this.landmarkCtrl,
    required this.cityCtrl,
    required this.pincodeCtrl,
    required this.hasPin,
    required this.onPickLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1565C0), width: 1),
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1565C0),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Pin-on-map ─────────────────────────────────────────
          InkWell(
            onTap: onPickLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: hasPin
                    ? Colors.green.withValues(alpha: 0.08)
                    : const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPin ? Colors.green : const Color(0xFF1565C0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(hasPin ? Icons.check_circle : Icons.map_outlined,
                      size: 20,
                      color: hasPin ? Colors.green : const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPin
                              ? 'Location pinned on map'
                              : 'Pin your location on map',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: hasPin
                                ? Colors.green.shade800
                                : const Color(0xFF1565C0),
                          ),
                        ),
                        Text(
                          hasPin
                              ? 'Tap to adjust the precise spot'
                              : 'Optional — for accurate, on-time delivery',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: Colors.grey.shade500),
                ],
              ),
            ),
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
        hintStyle: GoogleFonts.inter(
            fontSize: 12, color: Colors.grey.shade500),
        border:
            const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
  final bool disabled;

  const _RadioRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = !disabled && groupValue == value;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
      onTap: disabled ? null : () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: selected ? BauhausTheme.accentRed : Colors.transparent,
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : BauhausTheme.primaryBlack,
                      )),
                  Text(sublabel,
                      style: GoogleFonts.inter(
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
            : selected ? BauhausTheme.accentRed
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
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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

// Self-dismissing dialog with the red ✗ animation for a failed/cancelled payment.
class _PaymentFailedDialog extends StatefulWidget {
  final String message;
  const _PaymentFailedDialog({required this.message});

  @override
  State<_PaymentFailedDialog> createState() => _PaymentFailedDialogState();
}

class _PaymentFailedDialogState extends State<_PaymentFailedDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-close after the animation has played, returning to the order form.
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BauhausTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusAnimation(success: false, size: 88),
            const SizedBox(height: 18),
            Text(
              'Payment Unsuccessful',
              textAlign: TextAlign.center,
              style: BauhausTheme.heading(size: 18, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style:
                  BauhausTheme.body(size: 13, color: BauhausTheme.mediumGrey),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(
                'TRY AGAIN',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
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
