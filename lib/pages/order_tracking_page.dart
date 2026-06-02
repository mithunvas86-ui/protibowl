import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../theme/bauhaus_theme.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<OrderProvider>().fetchOrders();
    // Poll Supabase every 10 seconds for live status updates
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY ORDERS',
          style: GoogleFonts.chivo(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        backgroundColor: BauhausTheme.white,
        elevation: 0,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'NO ORDERS YET',
                    style: GoogleFonts.chivo(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              final items = (order['items'] ?? order['order_items'] ?? []) as List;
              final status = order['status'] ?? 'pending';
              final statusColor = _getStatusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: BauhausTheme.primaryBlack, width: 2),
                  color: BauhausTheme.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: statusColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER #${order['id'].toString().toUpperCase()}',
                                style: GoogleFonts.chivo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: BauhausTheme.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.chivo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BauhausTheme.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${order['total_price']}',
                            style: GoogleFonts.chivo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: BauhausTheme.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Items
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${item['quantity']}x Item - ₹${item['price']}',
                                style: GoogleFonts.chivo(fontSize: 12),
                              ),
                            );
                          }).toList(),
                          if (order['special_instructions']?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: BauhausTheme.primaryBlack,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOTES',
                                    style: GoogleFonts.chivo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    order['special_instructions'],
                                    style: GoogleFonts.chivo(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return const Color(0xFF1565C0); // dark blue
      case 'preparing':
        return const Color(0xFF6A1B9A); // purple
      case 'ready':
        return const Color(0xFF2E7D32); // dark green
      case 'completed':
        return const Color(0xFF1B5E20); // deep green
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
