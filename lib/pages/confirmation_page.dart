import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/local_storage_service.dart';
import '../services/order_api_service.dart';
import '../theme/bauhaus_theme.dart';
import '../widgets/bauhaus_button.dart';

class ConfirmationPage extends StatefulWidget {
  final String orderId;
  const ConfirmationPage({super.key, required this.orderId});

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final _localStorage = LocalStorageService();
  final _apiService = UserOrderAPIService();
  String _apiStatus = 'Submitting order...';
  bool _apiSubmitted = false;

  @override
  void initState() {
    super.initState();
    _submitOrderToAPI();
  }

  Future<void> _submitOrderToAPI() async {
    try {
      final order = _localStorage.getCurrentOrder();
      if (order == null) return;

      final customerInfo = order['customer_info'] ?? {};
      final items = order['items'] ?? [];

      final orderRequest = OrderAPIRequest(
        orderId: widget.orderId,
        customerName: customerInfo['name'] ?? 'Guest',
        customerPhone: customerInfo['phone'],
        customerEmail: customerInfo['email'],
        orderType: order['order_type'] ?? 'DINE_IN',
        items: items
            .map<OrderItemData>((item) => OrderItemData(
                  name: item['name'] ?? 'Item',
                  price: (item['price'] as num).toDouble(),
                  quantity: item['quantity'] as int,
                  notes: item['notes'],
                ))
            .toList(),
        totalAmount: (order['total_price'] as num).toDouble(),
        specialNotes: order['special_notes'],
      );

      final result = await _apiService.submitOrder(orderRequest);

      if (mounted) {
        setState(() {
          _apiSubmitted = true;
          if (result['success'] == true) {
            _apiStatus = '✅ Order submitted to business API';
          } else {
            _apiStatus =
                '⚠️ API submission: ${result['error'] ?? 'Unknown error'}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiSubmitted = true;
          _apiStatus = '⚠️ API error: $e';
        });
      }
    }
  }

  Map<String, dynamic>? _getOrderDetails() {
    try {
      final order = _localStorage.getCurrentOrder();
      return order;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ORDER CONFIRMED',
          style: GoogleFonts.chivo(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        backgroundColor: BauhausTheme.white,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          final order = _getOrderDetails();

          if (order == null || order.isEmpty) {
            return Center(
              child: Text(
                'Order #${widget.orderId}',
                style: GoogleFonts.chivo(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            );
          }

          final items = order['items'] ?? [];
          final customerInfo = order['customer_info'] ?? {};
          final totalPrice = order['total_price'] ?? 0;
          final orderType = order['order_type'] ?? 'N/A';
          final customerName = customerInfo['name'] ?? 'Guest';
          final customerPhone = customerInfo['phone'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 48, color: Colors.green),
                      const SizedBox(height: 8),
                      Text(
                        '✅ ORDER CONFIRMED',
                        style: GoogleFonts.chivo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order ID
                Text(
                  'ORDER NUMBER',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.mediumGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 2),
                    color: BauhausTheme.lightGrey,
                  ),
                  child: Text(
                    '#${widget.orderId}',
                    style: GoogleFonts.chivo(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: BauhausTheme.primaryBlack,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Customer Info
                Text(
                  'CUSTOMER DETAILS',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.mediumGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Name:',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.mediumGrey,
                            ),
                          ),
                          Text(
                            customerInfo['name'] ?? 'N/A',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Phone:',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.mediumGrey,
                            ),
                          ),
                          Text(
                            customerInfo['phone'] ?? 'N/A',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Type:',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.mediumGrey,
                            ),
                          ),
                          Text(
                            orderType
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BauhausTheme.accentRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order Items
                Text(
                  'ORDER DETAILS',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BauhausTheme.mediumGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: BauhausTheme.primaryBlack, width: 1),
                  ),
                  child: items.isNotEmpty
                      ? Column(
                          children: [
                            ...List.generate(
                              items.length,
                              (index) {
                                final item =
                                    items[index] as Map<String, dynamic>;
                                final isLast = index == items.length - 1;
                                final itemName = item['name'] ?? 'Item';
                                final itemPrice =
                                    (item['price'] as num).toDouble();
                                final itemQty = item['quantity'] as int;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  itemName,
                                                  style: GoogleFonts.chivo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: BauhausTheme
                                                        .primaryBlack,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '₹${(itemPrice * itemQty).toStringAsFixed(0)}',
                                                style: GoogleFonts.chivo(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: BauhausTheme.accentRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'x$itemQty @ ₹${itemPrice.toStringAsFixed(0)}',
                                            style: GoogleFonts.chivo(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: BauhausTheme.mediumGrey,
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
                              },
                            ),
                          ],
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No items in order',
                              style: GoogleFonts.chivo(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: BauhausTheme.mediumGrey,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Total
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
                        'TOTAL AMOUNT',
                        style: GoogleFonts.chivo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.primaryBlack,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '₹${totalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.chivo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: BauhausTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _apiSubmitted && _apiStatus.startsWith('✅')
                          ? Colors.green
                          : Colors.blue,
                      width: 1,
                    ),
                    color: (_apiSubmitted && _apiStatus.startsWith('✅')
                            ? Colors.green
                            : Colors.blue)
                        .withValues(alpha: 0.1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _apiStatus,
                        style: GoogleFonts.chivo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _apiSubmitted && _apiStatus.startsWith('✅')
                              ? Colors.green[900]
                              : Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🖨️ Bill printing to thermal printer',
                        style: GoogleFonts.chivo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                BauhausButton(
                  label: 'VIEW YOUR ORDERS',
                  onPressed: () => context.go('/my-orders'),
                  height: 48,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: BauhausTheme.primaryBlack, width: 2),
                      color: BauhausTheme.white,
                    ),
                    child: Text(
                      'CONTINUE SHOPPING',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chivo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: BauhausTheme.primaryBlack,
                        letterSpacing: 1,
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
}
