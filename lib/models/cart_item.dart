class CartItem {
  final String id;
  final String itemName;
  final double price;
  final String imageUrl;
  int quantity;
  String specialInstructions;

  CartItem({
    required this.id,
    required this.itemName,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.specialInstructions = '',
  });

  double get subtotal => price * quantity;
}
