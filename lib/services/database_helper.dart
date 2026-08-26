import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/saved_invoice.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL
      )
    ''');
  }

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (maps.isNotEmpty) return Product.fromMap(maps.first);
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveInvoice(SavedInvoice invoice) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      for (var item in invoice.items) {
        await txn.insert('invoice_items', item.toMap());
      }
    });
  }

  Future<SavedInvoice?> getInvoiceByBarcode(String invoiceNumber) async {
    final db = await instance.database;
    final invoiceResult = await db.query('invoices', where: 'invoice_number = ?', whereArgs: [invoiceNumber]);
    if (invoiceResult.isEmpty) return null;

    final itemsResult = await db.query('invoice_items', where: 'invoice_number = ?', whereArgs: [invoiceNumber]);
    final items = itemsResult.map((map) => SavedInvoiceItem(
          id: map['id'] as int?,
          invoiceNumber: map['invoice_number'] as String,
          productName: map['product_name'] as String,
          quantity: map['quantity'] as int,
          price: (map['price'] as num).toDouble(),
        )).toList();

    final data = invoiceResult.first;
    return SavedInvoice(
      id: data['id'] as int?,
      invoiceNumber: data['invoice_number'] as String,
      date: data['date'] as String,
      totalAmount: (data['total_amount'] as num).toDouble(),
      items: items,
    );
  }
}
