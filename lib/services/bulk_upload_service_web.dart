import 'dart:html' as html;
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class BulkUploadService {
  static Future<List<Map<String, dynamic>>> pickAndParseFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result == null) return [];

    final bytes = result.files.first.bytes;
    final extension = result.files.first.extension;

    if (bytes == null) return [];

    if (extension == 'csv') {
      return _parseCsvBytes(bytes);
    } else {
      return _parseExcelBytes(bytes);
    }
  }

  static Future<bool> downloadTemplate() async {
    final headers =
        'name,sku,barcode,category,unit,cost_price,selling_price,stock_quantity,min_stock_level,is_vat_exempt';

    final blob = html.Blob([headers], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'product_template.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    return true;
  }

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
      if (product.isNotEmpty && product.containsKey('name')) {
        products.add(product);
      }
    }
    return products;
  }

  static List<Map<String, dynamic>> _parseCsvBytes(List<int> bytes) {
    final csvString = utf8.decode(bytes);
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
      if (product.isNotEmpty && product.containsKey('name')) {
        products.add(product);
      }
    }
    return products;
  }
}
