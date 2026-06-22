import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import 'order_success_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CheckoutScreen
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final String restaurantName;
  final String restaurantId;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.restaurantName,
    required this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0; // 0 = Visa, 1 = Mastercard
  final _instructionsController = TextEditingController();
  bool _isPlacingOrder = false;
  final _api = ApiService.instance;

  static const int _maxInstructions = 200;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String _generateFallbackOrderId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = math.Random();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    final paymentMethod = _selectedPayment == 0
        ? 'Visa ending in 1234'
        : 'Mastercard ending in 5678';

    String orderId;
    try {
      // Try API first
      final orderData = await _api.createOrder(
        restaurantId: int.tryParse(widget.restaurantId) ?? 1,
        items: widget.items.map((item) => {
          'menu_item_id': int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
          'name': item.itemName,
          'quantity': item.quantity,
          'unit_price': item.price,
        }).toList(),
        deliveryAddress: '9828 Pine Street, Hayward, CA 94187',
        paymentMethod: paymentMethod,
        specialNotes: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
      );
      orderId = orderData['order_id'] as String? ?? _generateFallbackOrderId();
    } catch (_) {
      // Fallback to local order ID if API is unavailable
      orderId = _generateFallbackOrderId();
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: orderId,
          restaurantName: widget.restaurantName,
          totalAmount: widget.total,
          items: widget.items,
          deliveryAddress: '9828 Pine Street, Hayward, CA 94187',
          paymentMethod: paymentMethod,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(children: [
          _buildOrderSummary(),
          const SizedBox(height: 16),
          _buildDeliveryAddress(),
          const SizedBox(height: 16),
          _buildPaymentMethod(),
          const SizedBox(height: 16),
          _buildSpecialInstructions(),
        ]),
      ),
      bottomNavigationBar: _buildPlaceOrderBar(),
    );
  }

  // ── Order Summary Card ────────────────────────────────────────────────────

  Widget _buildOrderSummary() {
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Summary',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(widget.restaurantName,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        // Items
        ...widget.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantity}x ${item.itemName}',
                      style: GoogleFonts.poppins(fontSize: 14)),
                  Text('\$${item.subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            )),

        const Divider(height: 20),

        _CheckoutPriceRow('Subtotal', widget.subtotal),
        const SizedBox(height: 4),
        _CheckoutPriceRow('Delivery Fee', widget.deliveryFee),
        const SizedBox(height: 4),
        _CheckoutPriceRow('Tax & Fees', widget.tax),

        const Divider(height: 20),

        _CheckoutPriceRow('Total', widget.total,
            isBold: true, isGreen: true),
      ]),
    );
  }

  // ── Delivery Address Card ─────────────────────────────────────────────────

  Widget _buildDeliveryAddress() {
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text('Delivery Address',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),

        // Address box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Location',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '9485 Cherry Boulevard,\nMountain View, CA 94174',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ]),
                  ]),
            ),
            const Icon(Icons.edit_location_outlined,
                color: AppColors.textSecondary, size: 22),
          ]),
        ),
        const SizedBox(height: 12),

        // Google Map
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 160,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.6879, -122.0807), // Hayward, CA
                zoom: 14,
              ),
              markers: {
                const Marker(
                  markerId: MarkerId('delivery'),
                  position: LatLng(37.6879, -122.0807),
                  infoWindow: InfoWindow(
                    title: 'Delivery Address',
                    snippet: '9828 Pine Street, Hayward, CA',
                  ),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Use current location
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.my_location, size: 16),
          label: Text('Use Current Location',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 14)),
          style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero),
        ),
      ]),
    );
  }

  // ── Payment Method Card ───────────────────────────────────────────────────

  Widget _buildPaymentMethod() {
    const cards = [
      ('Visa ending in 1234', 'Default'),
      ('Mastercard ending in 5678', ''),
    ];

    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.credit_card,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text('Payment Method',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Card options
        ...List.generate(cards.length, (i) {
          final (name, subtitle) = cards[i];
          return InkWell(
            onTap: () => setState(() => _selectedPayment = i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                // Radio for payment selection
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedPayment == i
                          ? AppColors.primary
                          : AppColors.divider,
                      width: 2,
                    ),
                  ),
                  child: _selectedPayment == i
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        if (subtitle.isNotEmpty)
                          Text(subtitle,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                      ]),
                ),
                const Icon(Icons.credit_card,
                    color: AppColors.textSecondary, size: 22),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  // ── Special Instructions Card ─────────────────────────────────────────────

  Widget _buildSpecialInstructions() {
    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.note_outlined,
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Text('Special Instructions',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),

        TextField(
          controller: _instructionsController,
          maxLines: 4,
          maxLength: _maxInstructions,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Any special requests for your order?',
            counterText:
                '${_instructionsController.text.length}/$_maxInstructions',
            counterStyle: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Place Order Bottom Bar ────────────────────────────────────────────────

  Widget _buildPlaceOrderBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 12, color: Colors.black12,
                offset: Offset(0, -4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Place Order  •  \$${widget.total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: child,
      );
}

class _CheckoutPriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool isGreen;

  const _CheckoutPriceRow(this.label, this.amount,
      {this.isBold = false, this.isGreen = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: isBold ? 15 : 14,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text('\$${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: isBold ? 16 : 14,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                  color:
                      isGreen ? AppColors.primary : AppColors.textPrimary)),
        ],
      );
}

// _MapPainter removed — replaced with google_maps_flutter GoogleMap widget
