import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _promoController = TextEditingController();

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Order summary data
  /// Fetch from current order or cart state
  /// Query: SELECT subtotal, delivery_fee, total FROM `Order`
  ///        WHERE id = ? AND user_id = ?
  /// -------------------------------------------------------
  final double _subtotal = 19.94;
  final double _deliveryFee = 0.0;
  double _discount = 0.0;

  double get _total => _subtotal + _deliveryFee - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow(
                  'Subtotal',
                  '\$${_subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  'Delivery fee',
                  _deliveryFee == 0
                      ? 'FREE'
                      : '\$${_deliveryFee.toStringAsFixed(2)}',
                  valueColor: _deliveryFee == 0
                      ? const Color(0xFF2E7D32)
                      : null,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total',
                  '\$${_total.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 24),
                _buildPromoCodeField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 17 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeField() {
    return Row(
      children: [
        Icon(Icons.local_offer_outlined, color: Colors.grey[500], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _promoController,
            decoration: InputDecoration(
              hintText: 'Promo code',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            /// -------------------------------------------------------
            /// TODO: [MySQL INTEGRATION] - Apply promo code
            /// Call ApiService.applyPromoCode() which queries:
            /// SELECT * FROM PromoCode
            /// WHERE code = ? AND expiry_date > NOW() AND is_active = 1
            /// -------------------------------------------------------
            if (_promoController.text.isNotEmpty) {
              // final discount = await ApiService.applyPromoCode(_promoController.text);
              // setState(() => _discount = discount);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
}
