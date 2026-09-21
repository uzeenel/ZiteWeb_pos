import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class BulkUploadService {
  // Pick and parse Excel or CSV file
  static Future<List<Map<String, dynamic>>> pickAndParseFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null) return [];

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final extension = result.files.single.extension;

    if (extension == 'csv') {
      return _parseCsvBytes(bytes);
    } else {
      return _parseExcelBytes(bytes);
    }
  }

  // Download template - opens Save As dialog
  static Future<bool> downloadTemplate() async {
    final headers =
        'name,sku,barcode,category,unit,cost_price,selling_price,stock_quantity,min_stock_level,is_vat_exempt';

    // Open Save As dialog
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Product Template',
      fileName: 'product_template.csv',
      allowedExtensions: ['csv'],
    );

    if (outputFile == null) {
      return false; // User cancelled
    }

    // Save the file
    final file = File(outputFile);
    await file.writeAsString(headers);
    return true;
  }

  // Parse Excel file from bytes
  static List<Map<String, dynamic>> _parseExcelBytes(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString())
        .toList();
    final List<Map<String, dynamic>> products = [];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final product = <String, dynamic>{};

      for (var j = 0; j < headers.length; j++) {
        final header = headers[j];
        final cell = row[j];
        if (header != null && header.isNotEmpty && cell != null) {
          final value = cell.value;
          if (value != null && value.toString().isNotEmpty) {
            product[header] = value.toString();
          }
        }
      }
      if (product.isNotEmpty &&
          product.containsKey('name') &&
          product['name'] != null &&
          product['name'].toString().isNotEmpty) {
        products.add(product);
      }
    }
    return products;
  }

  // Parse CSV file from bytes
  static List<Map<String, dynamic>> _parseCsvBytes(List<int> bytes) {
    final csvString = String.fromCharCodes(bytes);
    final csvTable = const CsvToListConverter().convert(csvString);

    if (csvTable.isEmpty) return [];

    final headers = csvTable.first.map((h) => h.toString()).toList();
    final List<Map<String, dynamic>> products = [];

    for (var i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      final product = <String, dynamic>{};

      for (var j = 0; j < headers.length; j++) {
        final header = headers[j];
        if (j < row.length && row[j] != null && row[j].toString().isNotEmpty) {
          product[header] = row[j].toString();
        }
      }
      if (product.isNotEmpty &&
          product.containsKey('name') &&
          product['name'] != null &&
          product['name'].toString().isNotEmpty) {
        products.add(product);
      }
    }
    return products;
  }
}
