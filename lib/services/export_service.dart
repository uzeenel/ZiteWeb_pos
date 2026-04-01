import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pos_system/models/stock_report.dart';
import 'package:pos_system/models/sales_report.dart';
import 'package:pos_system/models/cash_book.dart';
import 'package:intl/intl.dart';

class ExportService {
  final NumberFormat _formatter = NumberFormat("#,##0.00");
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // Helper method for currency cells
  CellValue _currencyCell(double value) {
    return TextCellValue('₦${_formatter.format(value)}');
  }

  // ==================== STOCK REPORT EXPORTS ====================

  Future<File?> exportStockToExcelWithPicker(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    try {
      final file = await exportStockToExcel(reports, summary);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Stock Report',
        fileName:
            'Stock_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final savedFile = await file.copy(outputFile);
        return savedFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<File> exportStockToExcel(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    var excel = Excel.createExcel();

    Sheet stockSheet = excel['Stock Report'];
    Sheet summarySheet = excel['Summary'];

    // Summary Sheet
    summarySheet.appendRow([TextCellValue('STOCK SUMMARY REPORT')]);
    summarySheet.appendRow([
      TextCellValue('Generated:'),
      TextCellValue(_dateFormat.format(DateTime.now())),
    ]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summarySheet.appendRow([
      TextCellValue('Total Products'),
      IntCellValue(summary.totalProducts),
    ]);
    summarySheet.appendRow([
      TextCellValue('Low Stock Items'),
      IntCellValue(summary.lowStockCount),
    ]);
    summarySheet.appendRow([
      TextCellValue('Out of Stock Items'),
      IntCellValue(summary.outOfStockCount),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Inventory Value'),
      _currencyCell(summary.totalInventoryValue),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Potential Revenue'),
      _currencyCell(summary.totalPotentialRevenue),
    ]);
    summarySheet.appendRow([]);
    summarySheet.appendRow([TextCellValue('Category Breakdown')]);
    summarySheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Product Count'),
      TextCellValue('Inventory Value'),
    ]);

    summary.categoryCounts.forEach((category, count) {
      summarySheet.appendRow([
        TextCellValue(category),
        IntCellValue(count),
        _currencyCell(summary.categoryValues[category] ?? 0),
      ]);
    });

    // Stock Sheet
    stockSheet.appendRow([
      TextCellValue('Product Name'),
      TextCellValue('SKU'),
      TextCellValue('Category'),
      TextCellValue('Stock Quantity'),
      TextCellValue('Unit Cost'),
      TextCellValue('Selling Price'),
      TextCellValue('Inventory Value'),
      TextCellValue('Potential Revenue'),
      TextCellValue('Status'),
    ]);

    for (var report in reports) {
      stockSheet.appendRow([
        TextCellValue(report.productName),
        TextCellValue(report.sku),
        TextCellValue(report.category),
        DoubleCellValue(report.stockQuantity),
        _currencyCell(report.unitCost),
        _currencyCell(report.sellingPrice),
        _currencyCell(report.inventoryValue),
        _currencyCell(report.potentialRevenue),
        TextCellValue(_getStockStatusText(report)),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final fileName =
        'Stock_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final fileBytes = await excel.encode();

    if (fileBytes != null) {
      File(filePath).writeAsBytesSync(fileBytes);
      return File(filePath);
    }

    throw Exception('Failed to generate Excel file');
  }

  Future<File?> exportStockToPdfWithPicker(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    try {
      final file = await exportStockToPdf(reports, summary);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Stock Report',
        fileName:
            'Stock_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final savedFile = await file.copy(outputFile);
        return savedFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<File> exportStockToPdf(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Stock Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Generated: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // Summary Section Title
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),

          // Summary Table
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Products', summary.totalProducts.toString()],
              ['Low Stock Items', summary.lowStockCount.toString()],
              ['Out of Stock Items', summary.outOfStockCount.toString()],
              [
                'Total Inventory Value',
                'NGN ${_formatter.format(summary.totalInventoryValue)}',
              ],
              [
                'Total Potential Revenue',
                'NGN ${_formatter.format(summary.totalPotentialRevenue)}',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: pw.TextStyle(fontSize: 11),
          ),

          pw.SizedBox(height: 25),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Category Breakdown
          pw.Text(
            'Category Breakdown',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Products', 'Inventory Value'],
            data: summary.categoryCounts.keys
                .map(
                  (category) => [
                    category,
                    summary.categoryCounts[category].toString(),
                    'NGN ${_formatter.format(summary.categoryValues[category] ?? 0)}',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),

          pw.SizedBox(height: 25),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Stock Table
          pw.Text(
            'Detailed Stock List',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              'Product',
              'SKU',
              'Category',
              'Stock',
              'Unit Cost',
              'Selling Price',
              'Value',
              'Status',
            ],
            data: reports
                .map(
                  (report) => [
                    report.productName,
                    report.sku,
                    report.category,
                    report.stockQuantity.toStringAsFixed(0),
                    'NGN ${_formatter.format(report.unitCost)}',
                    'NGN ${_formatter.format(report.sellingPrice)}',
                    'NGN ${_formatter.format(report.inventoryValue)}',
                    _getStockStatusText(report),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: pw.TextStyle(fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),

          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Generated by POS System',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final fileName =
        'Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ==================== SALES REPORT EXPORTS ====================

  Future<File?> exportSalesReportToExcel(
    SalesReportData reportData,
    DateTime date,
  ) async {
    try {
      var excel = Excel.createExcel();

      Sheet summarySheet = excel['Summary'];
      Sheet categorySheet = excel['Sales by Category'];
      Sheet productSheet = excel['Sales by Product'];

      // ========== SUMMARY SHEET ==========
      summarySheet.appendRow([TextCellValue('SALES REPORT')]);
      summarySheet.appendRow([
        TextCellValue('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ]);
      summarySheet.appendRow([
        TextCellValue('Generated: ${_dateFormat.format(DateTime.now())}'),
      ]);
      summarySheet.appendRow([]);

      summarySheet.appendRow([TextCellValue('SUMMARY')]);
      summarySheet.appendRow([
        TextCellValue('Total Sales'),
        _currencyCell(reportData.summary.totalSales),
      ]);
      summarySheet.appendRow([
        TextCellValue('Total Transactions'),
        IntCellValue(reportData.summary.totalTransactions),
      ]);
      summarySheet.appendRow([
        TextCellValue('Average Ticket'),
        _currencyCell(reportData.summary.averageTicket),
      ]);
      summarySheet.appendRow([
        TextCellValue('VAT Collected'),
        _currencyCell(reportData.summary.totalTax),
      ]);
      summarySheet.appendRow([]);

      summarySheet.appendRow([TextCellValue('PAYMENT METHODS')]);
      summarySheet.appendRow([
        TextCellValue('Method'),
        TextCellValue('Amount'),
        TextCellValue('Percentage'),
      ]);
      for (var entry in reportData.summary.paymentMethodBreakdown.entries) {
        double percentage = (entry.value / reportData.summary.totalSales) * 100;
        summarySheet.appendRow([
          TextCellValue(entry.key),
          _currencyCell(entry.value),
          TextCellValue('${percentage.toStringAsFixed(1)}%'),
        ]);
      }

      // ========== CATEGORY SHEET ==========
      categorySheet.appendRow([TextCellValue('SALES BY CATEGORY')]);
      categorySheet.appendRow([
        TextCellValue('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ]);
      categorySheet.appendRow([]);
      categorySheet.appendRow([
        TextCellValue('Category'),
        TextCellValue('Quantity'),
        TextCellValue('Revenue'),
        TextCellValue('Percentage'),
      ]);
      for (var cat in reportData.categoryReports) {
        categorySheet.appendRow([
          TextCellValue(cat.category),
          IntCellValue(cat.quantitySold),
          _currencyCell(cat.totalRevenue),
          TextCellValue('${cat.percentageOfTotal.toStringAsFixed(1)}%'),
        ]);
      }

      // ========== PRODUCT SHEET ==========
      productSheet.appendRow([TextCellValue('SALES BY PRODUCT')]);
      productSheet.appendRow([
        TextCellValue('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ]);
      productSheet.appendRow([]);
      productSheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Product'),
        TextCellValue('SKU'),
        TextCellValue('Category'),
        TextCellValue('Quantity'),
        TextCellValue('Unit Price'),
        TextCellValue('Total Revenue'),
        TextCellValue('Percentage'),
      ]);

      int rank = 1;
      for (var product in reportData.allProducts) {
        double percentage =
            (product.totalRevenue / reportData.summary.totalSales) * 100;
        productSheet.appendRow([
          IntCellValue(rank++),
          TextCellValue(product.productName),
          TextCellValue(product.sku),
          TextCellValue(product.category),
          IntCellValue(product.quantitySold),
          _currencyCell(product.unitPrice),
          _currencyCell(product.totalRevenue),
          TextCellValue('${percentage.toStringAsFixed(1)}%'),
        ]);
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final fileBytes = await excel.encode();

      if (fileBytes != null) {
        File(filePath).writeAsBytesSync(fileBytes);

        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Sales Report',
          fileName: fileName,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final savedFile = await File(filePath).copy(outputFile);
          return savedFile;
        }
        return null;
      }
      throw Exception('Failed to generate Excel file');
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<File?> exportSalesReportToPdf(
    SalesReportData reportData,
    DateTime date,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Sales Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(date)}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Generated: ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Summary
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                [
                  'Total Sales',
                  'NGN ${_formatter.format(reportData.summary.totalSales)}',
                ],
                [
                  'Total Transactions',
                  reportData.summary.totalTransactions.toString(),
                ],
                [
                  'Average Ticket',
                  'NGN ${_formatter.format(reportData.summary.averageTicket)}',
                ],
                [
                  'VAT Collected',
                  'NGN ${_formatter.format(reportData.summary.totalTax)}',
                ],
              ],
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Payment Methods
            pw.Text(
              'Payment Methods',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Method', 'Amount', 'Percentage'],
              data: reportData.summary.paymentMethodBreakdown.entries.map((
                entry,
              ) {
                double percentage =
                    (entry.value / reportData.summary.totalSales) * 100;
                return [
                  entry.key,
                  'NGN ${_formatter.format(entry.value)}',
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Category Breakdown
            pw.Text(
              'Sales by Category',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Quantity', 'Revenue', 'Percentage'],
              data: reportData.categoryReports
                  .map(
                    (cat) => [
                      cat.category,
                      cat.quantitySold.toString(),
                      'NGN ${_formatter.format(cat.totalRevenue)}',
                      '${cat.percentageOfTotal.toStringAsFixed(1)}%',
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Product Sales - FULL DETAILS
            pw.Text(
              'Sales by Product',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'Rank',
                'Product',
                'SKU',
                'Category',
                'Qty',
                'Unit Price',
                'Total',
                '%',
              ],
              data: reportData.allProducts.asMap().entries.map((entry) {
                int index = entry.key;
                var product = entry.value;
                double percentage =
                    (product.totalRevenue / reportData.summary.totalSales) *
                    100;
                return [
                  (index + 1).toString(),
                  product.productName,
                  product.sku,
                  product.category,
                  product.quantitySold.toString(),
                  'NGN ${_formatter.format(product.unitPrice)}',
                  'NGN ${_formatter.format(product.totalRevenue)}',
                  '${percentage.toStringAsFixed(1)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Generated by POS System',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          'Sales_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Sales Report',
        fileName: fileName,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final savedFile = await file.copy(outputFile);
        return savedFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  // ==================== CASH BOOK EXPORTS ====================

  Future<File?> exportCashBookToExcel(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    try {
      var excel = Excel.createExcel();

      Sheet sheet = excel['Cash Book'];

      // Title
      sheet.appendRow([TextCellValue('CASH BOOK')]);
      sheet.appendRow([
        TextCellValue('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ]);
      sheet.appendRow([
        TextCellValue('Generated: ${_dateFormat.format(DateTime.now())}'),
      ]);
      sheet.appendRow([]);

      // Summary
      sheet.appendRow([TextCellValue('SUMMARY')]);
      sheet.appendRow([
        TextCellValue('Opening Balance'),
        _currencyCell(summary.openingBalance),
      ]);
      sheet.appendRow([
        TextCellValue('Total Cash In'),
        _currencyCell(summary.totalCashIn),
      ]);
      sheet.appendRow([
        TextCellValue('Total Cash Out'),
        _currencyCell(summary.totalCashOut),
      ]);
      sheet.appendRow([
        TextCellValue('Net Cash'),
        _currencyCell(summary.netCash),
      ]);
      sheet.appendRow([
        TextCellValue('Closing Balance'),
        _currencyCell(summary.closingBalance),
      ]);
      sheet.appendRow([
        TextCellValue('Total Transactions'),
        IntCellValue(summary.transactionCount),
      ]);
      sheet.appendRow([]);

      // Transactions
      sheet.appendRow([TextCellValue('TRANSACTIONS')]);
      sheet.appendRow([
        TextCellValue('Time'),
        TextCellValue('Type'),
        TextCellValue('Category'),
        TextCellValue('Description'),
        TextCellValue('Reference'),
        TextCellValue('Amount'),
      ]);

      for (var t in transactions) {
        sheet.appendRow([
          TextCellValue(DateFormat('HH:mm').format(t.date)),
          TextCellValue(
            t.type == TransactionType.cashIn ? 'Cash In' : 'Cash Out',
          ),
          TextCellValue(t.category),
          TextCellValue(t.description),
          TextCellValue(t.reference ?? ''),
          _currencyCell(t.amount),
        ]);
      }

      final directory = await getTemporaryDirectory();
      final fileName =
          'Cash_Book_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final fileBytes = await excel.encode();

      if (fileBytes != null) {
        File(filePath).writeAsBytesSync(fileBytes);

        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Cash Book',
          fileName: fileName,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile != null) {
          final savedFile = await File(filePath).copy(outputFile);
          return savedFile;
        }
        return null;
      }
      throw Exception('Failed to generate Excel file');
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  Future<File?> exportCashBookToPdf(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Cash Book',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(date)}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Generated: ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),

            // Summary
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                [
                  'Opening Balance',
                  'NGN ${_formatter.format(summary.openingBalance)}',
                ],
                [
                  'Total Cash In',
                  'NGN ${_formatter.format(summary.totalCashIn)}',
                ],
                [
                  'Total Cash Out',
                  'NGN ${_formatter.format(summary.totalCashOut)}',
                ],
                ['Net Cash', 'NGN ${_formatter.format(summary.netCash)}'],
                [
                  'Closing Balance',
                  'NGN ${_formatter.format(summary.closingBalance)}',
                ],
                ['Total Transactions', summary.transactionCount.toString()],
              ],
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 20),

            // Transactions
            pw.Text(
              'Transactions',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'Time',
                'Type',
                'Category',
                'Description',
                'Reference',
                'Amount',
              ],
              data: transactions
                  .map(
                    (t) => [
                      DateFormat('HH:mm').format(t.date),
                      t.type == TransactionType.cashIn ? 'Cash In' : 'Cash Out',
                      t.category,
                      t.description,
                      t.reference ?? '',
                      'NGN ${_formatter.format(t.amount)}',
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Generated by POS System',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          'Cash_Book_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Cash Book',
        fileName: fileName,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final savedFile = await file.copy(outputFile);
        return savedFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  String _getStockStatusText(StockReport report) {
    if (report.stockQuantity <= 0) return 'Out of Stock';
    if (report.isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Future<void> shareFile(File file, String title) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Report Export');
  }
}
