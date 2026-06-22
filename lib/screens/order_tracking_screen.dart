import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrderTrackingScreen
// Matches screenshots: normal tracking, cancel dialog, and cancelled state
// ─────────────────────────────────────────────────────────────────────────────

enum OrderStatus { confirmed, preparing, readyForPickup, outForDelivery, delivered, cancelled }

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final double totalAmount;
  final List<CartItem> items;
  final String deliveryAddress;
  final String paymentMethod;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.totalAmount,
    required this.items,
    this.deliveryAddress = '9828 Pine Street, Hayward, CA 94187',
    this.paymentMethod = 'Visa ending in 1234',
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderStatus _currentStatus = OrderStatus.confirmed;
  bool _isCancelled = false;
  Timer? _progressTimer;
  final _api = ApiService.instance;

  // The ordered list of "active" statuses (excluding cancelled)
  static const _progressSteps = [
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _stepLabels = [
    'Order Confirmed',
    'Preparing Food',
    'Ready for Pickup',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    // Simulate order progressing automatically (demo purposes)
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (_isCancelled || !mounted) {
        t.cancel();
        return;
      }
      final idx = _progressSteps.indexOf(_currentStatus);
      if (idx < _progressSteps.length - 1) {
        setState(() => _currentStatus = _progressSteps[idx + 1]);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  // ── Progress value 0.0 – 1.0 ─────────────────────────────────────────────
  double get _progressValue {
    if (_isCancelled) return 0.0;
    final idx = _progressSteps.indexOf(_currentStatus);
    return (idx + 1) / _progressSteps.length;
  }

  int get _currentStepIndex => _progressSteps.indexOf(_currentStatus);

  // ── Cancel order dialog ───────────────────────────────────────────────────
  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel Order',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel this order?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // No button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'No',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Yes, Cancel button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Yes, Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    _progressTimer?.cancel();
    try {
      await _api.cancelOrder(widget.orderId);
    } catch (_) {
      // Proceed with local cancel even if API fails
    }
    if (mounted) {
      setState(() {
        _isCancelled = true;
        _currentStatus = OrderStatus.cancelled;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Text(
          'Order Tracking',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            // ── Status / Progress Card ──────────────────────────────────────
            _buildStatusCard(),
            const SizedBox(height: 14),

            // ── Order Details Card ──────────────────────────────────────────
            _buildOrderDetailsCard(),
            const SizedBox(height: 14),

            // ── Order Items Card ────────────────────────────────────────────
            _buildOrderItemsCard(),
            const SizedBox(height: 24),

            // ── Cancel Order button (only if not cancelled) ─────────────────
            if (!_isCancelled) ...[
              OutlinedButton(
                onPressed: _showCancelDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Cancel Order',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Need Help?',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ] else ...[
              // Need Help button for cancelled state
              TextButton(
                onPressed: () {},
                child: Text(
                  'Need Help?',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Status Card ───────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return _Card(
      child: _isCancelled
          ? _buildCancelledStatus()
          : _buildActiveProgress(),
    );
  }

  Widget _buildCancelledStatus() {
    return Column(
      children: [
        // Red X circle
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          'Cancelled',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Order has been cancelled',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Estimated delivery: Just now',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Order Progress section (all green checkmarks when cancelled)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order Progress',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '0%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 8),
        ...List.generate(_stepLabels.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  _stepLabels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActiveProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Orange progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progressValue,
            minHeight: 6,
            backgroundColor: const Color(0xFFEEEEEE),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
          ),
        ),
        const SizedBox(height: 16),

        // Step list
        ...List.generate(_stepLabels.length, (i) {
          final isActive = i <= _currentStepIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : const Color(0xFFDDDDDD),
                    shape: BoxShape.circle,
                  ),
                  child: isActive
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  _stepLabels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Order Details Card ────────────────────────────────────────────────────
  Widget _buildOrderDetailsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Order ID', value: widget.orderId),
          _DetailRow(
              label: 'Restaurant', value: widget.restaurantName),
          _DetailRow(label: 'Order Time', value: 'Just now'),
          _DetailRow(
              label: 'Delivery Address', value: widget.deliveryAddress),
          _DetailRow(
              label: 'Payment Method', value: widget.paymentMethod,
              isLast: true),
        ],
      ),
    );
  }

  // ── Order Items Card ──────────────────────────────────────────────────────
  Widget _buildOrderItemsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          const SizedBox(height: 10),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${widget.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(color: Color(0xFFF5F5F5), height: 1),
      ],
    );
  }
}
