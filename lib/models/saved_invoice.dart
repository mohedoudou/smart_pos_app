class SavedInvoice {
  final int? id;
  final String invoiceNumber;
  final String date;
  final double totalAmount;
  final List<SavedInvoiceItem> items;

  SavedInvoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.totalAmount,
    this.items = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'date': date,
        'total_amount': totalAmount,
      };
}

class SavedInvoiceItem {
  final int? id;
  final String invoiceNumber;
  final String productName;
  final int quantity;
  final double price;

  SavedInvoiceItem({
    this.id,
    required this.invoiceNumber,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'product_name': productName,
        'quantity': quantity,
        'price': price,
      };
}
