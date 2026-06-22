import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/cart_item.dart';
import 'order_tracking_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderSuccessScreen  (matches "Order Placed Successfully!" screenshot)
// ─────────────────────────────────────────────────────────────────────────────

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final double totalAmount;
  final List<CartItem> items;
  final String deliveryAddress;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.totalAmount,
    required this.items,
    this.deliveryAddress = '9828 Pine Street, Hayward, CA 94187',
    this.paymentMethod = 'Visa ending in 1234',
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            children: [
              // ── Animated checkmark circle ─────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title & subtitle ──────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Order Placed\nSuccessfully!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thank you for your order! We're preparing\nit with care.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Order summary card ────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        icon: Icons.receipt_long,
                        label: 'Order ID',
                        value: widget.orderId,
                        valueColor: AppColors.primary,
                        valueBold: true,
                      ),
                      const _Divider(),
                      _SummaryRow(
                        icon: Icons.restaurant,
                        label: 'Restaurant',
                        value: widget.restaurantName,
                      ),
                      const _Divider(),
                      _SummaryRow(
                        icon: Icons.access_time_rounded,
                        label: 'Estimated Delivery',
                        value: '29 minutes',
                      ),
                      const _Divider(),
                      _SummaryRow(
                        icon: Icons.credit_card,
                        label: 'Total Amount',
                        value: '\$${widget.totalAmount.toStringAsFixed(2)}',
                        valueColor: AppColors.primary,
                        valueBold: true,
                        valueLarge: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Track Your Order button ───────────────────────────────────
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(
                        orderId: widget.orderId,
                        restaurantName: widget.restaurantName,
                        totalAmount: widget.totalAmount,
                        items: widget.items,
                        deliveryAddress: widget.deliveryAddress,
                        paymentMethod: widget.paymentMethod,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.track_changes, size: 20),
                label: Text(
                  'Track Your Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Back to Home button ───────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 20),
                label: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;
  final bool valueLarge;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
    this.valueLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: valueLarge ? 22 : 15,
                    fontWeight:
                        valueBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFF0F0F0));
}
