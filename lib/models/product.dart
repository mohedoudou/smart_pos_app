class Product {
  final int? id;
  final String barcode;
  final String name;
  final double price;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'price': price,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        barcode: map['barcode'] as String,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
      );
}
