import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CartScreen
// ─────────────────────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  final String restaurantName;
  final String restaurantId;
  final double deliveryFee;
  final double minimumOrder;
  final List<CartItem> initialItems;

  const CartScreen({
    super.key,
    required this.restaurantName,
    this.restaurantId = '1',
    required this.deliveryFee,
    required this.minimumOrder,
    required this.initialItems,
  });

  /// Demo constructor — pre-filled with Pizza Palace data (matches screenshot)
  static CartScreen demo() => CartScreen(
        restaurantName: 'Pizza Palace',
        deliveryFee: 2.99,
        minimumOrder: 15.00,
        initialItems: [
          CartItem(
            id: 'c1',
            itemName: 'Margherita Pizza',
            price: 14.99,
            imageUrl:
                'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
          ),
        ],
      );

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  // ── Calculations ──────────────────────────────────────────────────────────
  double get _subtotal => _items.fold(0, (s, i) => s + i.subtotal);
  double get _tax => double.parse((_subtotal * 0.08).toStringAsFixed(2));
  double get _total =>
      double.parse((_subtotal + widget.deliveryFee + _tax).toStringAsFixed(2));
  bool get _meetsMinimum => _subtotal >= widget.minimumOrder;
  double get _amountToMinimum =>
      double.parse((widget.minimumOrder - _subtotal).toStringAsFixed(2));

  // ── Mutations ─────────────────────────────────────────────────────────────
  void _changeQty(String id, int delta) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx < 0) return;
      _items[idx].quantity += delta;
      if (_items[idx].quantity <= 0) _items.removeAt(idx);
    });
  }

  void _removeItem(String id) =>
      setState(() => _items.removeWhere((i) => i.id == id));

  void _clearCart() => setState(() => _items.clear());

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showInstructionsDialog(CartItem item) {
    final ctrl = TextEditingController(text: item.specialInstructions);
    showDialog(
      context: context,
      builder: (_) => _InstructionsDialog(
        controller: ctrl,
        onSave: (text) => setState(() => item.specialInstructions = text),
      ),
    );
  }

  void _confirmClearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Remove all items?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              _clearCart();
              Navigator.pop(ctx);
            },
            child: Text('Clear',
                style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _confirmClearCart,
            child: Text('Clear All',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: _items.isEmpty ? _buildEmpty() : _buildContent(),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: GoogleFonts.poppins(
                  fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Add items from a restaurant to get started',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textHint)),
        ]),
      );

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() => Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              // "Ordering from" header
              Text('Ordering from',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(widget.restaurantName,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Item cards
              ..._items.map((item) => _CartItemCard(
                    item: item,
                    onIncrement: () => _changeQty(item.id, 1),
                    onDecrement: () => _changeQty(item.id, -1),
                    onRemove: () => _removeItem(item.id),
                    onAddInstructions: () => _showInstructionsDialog(item),
                  )),
            ],
          ),
        ),

        // Price breakdown + checkout button
        _buildPriceSection(),
      ]);

  // ── Price & checkout ──────────────────────────────────────────────────────
  Widget _buildPriceSection() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                blurRadius: 14,
                color: Colors.black12,
                offset: Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimum order warning
            if (!_meetsMinimum) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC02)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF9800), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minimum order: \$${widget.minimumOrder.toStringAsFixed(2)}. '
                      'Add \$$_amountToMinimum more.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFFE65100)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            _PriceRow('Subtotal', _subtotal),
            const SizedBox(height: 4),
            _PriceRow('Delivery Fee', widget.deliveryFee),
            const SizedBox(height: 4),
            _PriceRow('Tax & Fees', _tax),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider()),
            _PriceRow('Total', _total, isBold: true, isGreen: true),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _meetsMinimum
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            restaurantName: widget.restaurantName,
                            restaurantId: widget.restaurantId,
                            items: _items,
                            subtotal: _subtotal,
                            deliveryFee: widget.deliveryFee,
                            tax: _tax,
                            total: _total,
                          ),
                        ),
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _meetsMinimum ? AppColors.primary : Colors.grey[300],
                foregroundColor:
                    _meetsMinimum ? Colors.white : Colors.grey[500],
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Proceed to Checkout',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartItemCard
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement, onDecrement, onRemove, onAddInstructions;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onAddInstructions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood)),
                  errorWidget: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood)),
                ),
              ),
              const SizedBox(width: 12),

              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + delete button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.price.toStringAsFixed(2)} each',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Qty control + subtotal
                    Row(
                      children: [
                        _QtyControl(
                          qty: item.quantity,
                          onDecrement: onDecrement,
                          onIncrement: onIncrement,
                        ),
                        const Spacer(),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
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
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Special instructions (if set)
          if (item.specialInstructions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${item.specialInstructions}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Add / Edit instructions
          GestureDetector(
            onTap: onAddInstructions,
            child: Row(children: [
              const Icon(Icons.add, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text(
                item.specialInstructions.isEmpty
                    ? 'Add Instructions'
                    : 'Edit Instructions',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QtyControl
// ─────────────────────────────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement, onIncrement;

  const _QtyControl({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _QtyBtn(icon: Icons.remove, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$qty',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        _QtyBtn(icon: Icons.add, onTap: onIncrement),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _PriceRow
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool isGreen;

  const _PriceRow(this.label, this.amount,
      {this.isBold = false, this.isGreen = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: isBold ? 15 : 14,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: isBold ? 16 : 14,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal,
                color: isGreen ? AppColors.primary : AppColors.textPrimary),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _InstructionsDialog
// ─────────────────────────────────────────────────────────────────────────────

class _InstructionsDialog extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSave;

  const _InstructionsDialog(
      {required this.controller, required this.onSave});

  @override
  State<_InstructionsDialog> createState() => _InstructionsDialogState();
}

class _InstructionsDialogState extends State<_InstructionsDialog> {
  static const int _maxChars = 200;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Special Instructions',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: widget.controller,
            maxLines: 4,
            maxLength: _maxChars,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. No onions, extra sauce...',
              hintStyle: GoogleFonts.poppins(
                  color: AppColors.textHint, fontSize: 13),
              counterText: '',
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length}/$_maxChars',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                widget.onSave(widget.controller.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save', style: GoogleFonts.poppins()),
            ),
          ]),
        ]),
      ),
    );
  }
}
