import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pos_system.db');

    return await openDatabase(path, version: 10, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {

    // Create company table (for branding)
    await db.execute('''
      CREATE TABLE company(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_id TEXT,
        auto_cash_book INTEGER DEFAULT 1,
        auto_bank_book INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== CATEGORIES TABLE ==========
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        is_vat_exempt INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== BASE UNITS TABLE ==========
    await db.execute('''
      CREATE TABLE base_units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== UNITS TABLE ==========
    await db.execute('''
      CREATE TABLE units(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        base_unit_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        conversion_factor REAL NOT NULL DEFAULT 1,
        is_base_unit INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(base_unit_id) REFERENCES base_units(id)
      )
    ''');

    // ========== PRODUCTS TABLE ==========
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        category_name TEXT,
        unit_id INTEGER,
        name TEXT NOT NULL,
        sku TEXT UNIQUE,
        barcode TEXT,
        cost_price REAL,
        selling_price REAL,
        stock_quantity REAL DEFAULT 0,
        min_stock_level REAL DEFAULT 0,
        is_vat_exempt INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(unit_id) REFERENCES units(id)
      )
    ''');

    // ========== VENDORS TABLE ==========
    await db.execute('''
      CREATE TABLE vendors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        contact_person TEXT,
        tax_id TEXT,
        is_vat_registered INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== PURCHASE ORDERS TABLE ==========
    await db.execute('''
      CREATE TABLE purchase_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        po_number TEXT UNIQUE NOT NULL,
        vendor_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        expected_delivery TEXT,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(vendor_id) REFERENCES vendors(id)
      )
    ''');

    // ========== PURCHASE ORDER ITEMS TABLE ==========
    await db.execute('''
      CREATE TABLE purchase_order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        received_quantity REAL DEFAULT 0,
        FOREIGN KEY(purchase_order_id) REFERENCES purchase_orders(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    // ========== CUSTOMERS TABLE ==========
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        credit_limit REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        reference TEXT,
        user_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE bank_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        account_name TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        cheque_number TEXT,
        description TEXT NOT NULL,
        reference TEXT,
        user_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== SALES TABLE ==========
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        sale_date TEXT NOT NULL,
        customer_id INTEGER,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT,
        paid_amount REAL,
        change_amount REAL DEFAULT 0,
        cashier_id INTEGER,
        status TEXT DEFAULT 'completed',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========== SALE ITEMS TABLE ==========
    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        is_vat_exempt INTEGER DEFAULT 0,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    // Add to _onCreate method

    // Sales Returns table
    await db.execute('''
      CREATE TABLE sales_returns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_number TEXT UNIQUE NOT NULL,
        sale_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL,
        return_date TEXT NOT NULL,
        total_refund REAL NOT NULL,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        rejection_reason TEXT,
        cashier_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(sale_id) REFERENCES sales(id)
      )
    ''');

    // Return Items table
    await db.execute('''
      CREATE TABLE return_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id INTEGER NOT NULL,
        sale_item_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        sku TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        reason TEXT NOT NULL,
        FOREIGN KEY(return_id) REFERENCES sales_returns(id),
        FOREIGN KEY(sale_item_id) REFERENCES sale_items(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    // Add to _onCreate method
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        reference TEXT,
        vendor TEXT,
        user_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    // Add to _onCreate method
    await db.execute('''
  CREATE TABLE users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    last_login TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    // Create default admin user
    final adminPassword = BCrypt.hashpw('admin123', BCrypt.gensalt());
    await db.insert('users', {
      'username': 'admin',
      'password': adminPassword,
      'full_name': 'System Administrator',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // ========== INSERT SAMPLE CATEGORIES ==========
    await db.insert('categories', {'name': 'Beverages'});
    await db.insert('categories', {'name': 'Food'});
    await db.insert('categories', {'name': 'Household'});

    // Get category IDs
    List<Map<String, dynamic>> cats = await db.query('categories');
    Map<String, int> catMap = {};
    for (var cat in cats) {
      catMap[cat['name']] = cat['id'];
    }

    // ========== INSERT SAMPLE BASE UNITS ==========
    await db.insert('base_units', {'name': 'Piece', 'symbol': 'pcs'});
    await db.insert('base_units', {'name': 'Kilogram', 'symbol': 'kg'});
    await db.insert('base_units', {'name': 'Liter', 'symbol': 'L'});

    // Get unit IDs
    List<Map<String, dynamic>> baseUnits = await db.query('base_units');
    int pieceId = baseUnits.firstWhere((b) => b['symbol'] == 'pcs')['id'];
    int kgId = baseUnits.firstWhere((b) => b['symbol'] == 'kg')['id'];
    int literId = baseUnits.firstWhere((b) => b['symbol'] == 'L')['id'];

    // Insert units for Piece
    await db.insert('units', {
      'base_unit_id': pieceId,
      'name': 'Piece',
      'symbol': 'pcs',
      'conversion_factor': 1,
      'is_base_unit': 1,
    });
    await db.insert('units', {
      'base_unit_id': pieceId,
      'name': 'Carton',
      'symbol': 'ctn',
      'conversion_factor': 12,
      'is_base_unit': 0,
    });
    await db.insert('units', {
      'base_unit_id': pieceId,
      'name': 'Crate',
      'symbol': 'crt',
      'conversion_factor': 24,
      'is_base_unit': 0,
    });

    // Insert units for Kilogram
    await db.insert('units', {
      'base_unit_id': kgId,
      'name': 'Kilogram',
      'symbol': 'kg',
      'conversion_factor': 1,
      'is_base_unit': 1,
    });
    await db.insert('units', {
      'base_unit_id': kgId,
      'name': 'Gram',
      'symbol': 'g',
      'conversion_factor': 0.001,
      'is_base_unit': 0,
    });

    // Insert units for Liter
    await db.insert('units', {
      'base_unit_id': literId,
      'name': 'Liter',
      'symbol': 'L',
      'conversion_factor': 1,
      'is_base_unit': 1,
    });
    await db.insert('units', {
      'base_unit_id': literId,
      'name': 'Milliliter',
      'symbol': 'ml',
      'conversion_factor': 0.001,
      'is_base_unit': 0,
    });

    // Get unit IDs for sample products
    List<Map<String, dynamic>> units = await db.query('units');
    int literUnitId = units.firstWhere((u) => u['symbol'] == 'L')['id'];
    int pieceUnitId = units.firstWhere((u) => u['symbol'] == 'pcs')['id'];
    int kgUnitId = units.firstWhere((u) => u['symbol'] == 'kg')['id'];

    // ========== INSERT SAMPLE PRODUCTS ==========
    await db.insert('products', {
      'category_id': catMap['Beverages'],
      'category_name': 'Beverages',
      'unit_id': literUnitId,
      'name': 'Coca-Cola 50cl',
      'sku': 'BEV001',
      'barcode': '123456789',
      'cost_price': 150.00,
      'selling_price': 200.00,
      'stock_quantity': 100,
    });

    await db.insert('products', {
      'category_id': catMap['Beverages'],
      'category_name': 'Beverages',
      'unit_id': literUnitId,
      'name': 'Fanta 50cl',
      'sku': 'BEV002',
      'barcode': '123456790',
      'cost_price': 150.00,
      'selling_price': 200.00,
      'stock_quantity': 100,
    });

    await db.insert('products', {
      'category_id': catMap['Food'],
      'category_name': 'Food',
      'unit_id': pieceUnitId,
      'name': 'Indomie Noodles',
      'sku': 'FOOD001',
      'barcode': '123456791',
      'cost_price': 80.00,
      'selling_price': 100.00,
      'stock_quantity': 200,
    });

    await db.insert('products', {
      'category_id': catMap['Household'],
      'category_name': 'Household',
      'unit_id': kgUnitId,
      'name': 'Detergent 500g',
      'sku': 'HOUSE001',
      'barcode': '123456792',
      'cost_price': 300.00,
      'selling_price': 400.00,
      'stock_quantity': 50,
    });

    print('✅ Database tables created with sample data');
  }

  Future<List<Map<String, dynamic>>> query(String sql) async {
    final db = await database;
    return await db.rawQuery(sql);
  }

  Future<void> execute(String sql, List<dynamic> params) async {
    final db = await database;
    await db.rawUpdate(sql, params);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<bool> testConnection() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1 as test');
      return result.isNotEmpty;
    } catch (e) {
      print('Database test failed: $e');
      return false;
    }
  }
}
