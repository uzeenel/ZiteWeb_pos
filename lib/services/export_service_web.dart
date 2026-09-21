import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:zite_web_pos/models/stock_report.dart';
import 'package:zite_web_pos/models/sales_report.dart';
import 'package:zite_web_pos/models/cash_book.dart';
import 'package:zite_web_pos/models/stock_movement.dart';
import 'package:zite_web_pos/models/product.dart';

class ExportService {
  final NumberFormat _formatter = NumberFormat("#,##0.00");
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd_HH-mm');
  final DateFormat _dateFormatShort = DateFormat('dd-MM-yyyy');

  // ==================== HELPERS ====================

  CellValue _currencyCell(double value) {
    return TextCellValue('NGN${_formatter.format(value)}');
  }

  String _getStockStatusText(StockReport report) {
    if (report.stockQuantity <= 0) return 'Out of Stock';
    if (report.isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> _downloadBytes(List<int> bytes, String filename) async {
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _buildPdfHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'ZiteMart POS System',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ==================== SALES REPORT ====================

  Future<void> exportSalesReportToExcelWeb(
    SalesReportData reportData,
    DateTime date,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sales Report'];

    sheet.appendRow([TextCellValue('SALES REPORT')]);
    sheet.appendRow([TextCellValue('Date: ${_dateFormatShort.format(date)}')]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('SUMMARY')]);
    sheet.appendRow([
      TextCellValue('Total Sales'),
      _currencyCell(reportData.summary.totalSales),
    ]);
    sheet.appendRow([
      TextCellValue('Total Transactions'),
      TextCellValue(reportData.summary.totalTransactions.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Average Ticket'),
      _currencyCell(reportData.summary.averageTicket),
    ]);
    sheet.appendRow([
      TextCellValue('VAT Collected'),
      _currencyCell(reportData.summary.totalTax),
    ]);
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('PAYMENT METHODS')]);
    for (var entry in reportData.summary.paymentMethodBreakdown.entries) {
      sheet.appendRow([TextCellValue(entry.key), _currencyCell(entry.value)]);
    }
    sheet.appendRow([]);

    sheet.appendRow([TextCellValue('TOP PRODUCTS')]);
    sheet.appendRow([
      TextCellValue('Product'),
      TextCellValue('Qty'),
      TextCellValue('Revenue'),
    ]);
    for (var product in reportData.topProducts) {
      sheet.appendRow([
        TextCellValue(product.productName),
        TextCellValue(product.quantitySold.toString()),
        _currencyCell(product.totalRevenue),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _downloadBytes(
        bytes,
        'Sales_Report_${_sanitizeFileName(_dateFormatShort.format(date))}.xlsx',
      );
    }
  }

  Future<void> exportSalesReportToPdfWeb(
    SalesReportData reportData,
    DateTime date,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader(
              'SALES REPORT',
              'Date: ${_dateFormatShort.format(date)}',
            ),
            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                children: [
                  _buildPdfSummaryRow(
                    'Total Sales:',
                    'NGN${_formatter.format(reportData.summary.totalSales)}',
                    bold: true,
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'Total Transactions:',
                    reportData.summary.totalTransactions.toString(),
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'Average Ticket:',
                    'NGN${_formatter.format(reportData.summary.averageTicket)}',
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'VAT Collected:',
                    'NGN${_formatter.format(reportData.summary.totalTax)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'PAYMENT METHODS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                children: reportData.summary.paymentMethodBreakdown.entries.map(
                  (entry) {
                    return _buildPdfSummaryRow(
                      entry.key,
                      'NGN${_formatter.format(entry.value)}',
                    );
                  },
                ).toList(),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'TOP PRODUCTS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            'Product',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Revenue',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...reportData.topProducts.map(
                    (product) => pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(product.productName),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              product.quantitySold.toString(),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'NGN${_formatter.format(product.totalRevenue)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _buildPdfFooter(),
          ],
        ),
      ),
    );
    final bytes = await pdf.save();
    await _downloadBytes(
      bytes,
      'Sales_Report_${_sanitizeFileName(_dateFormatShort.format(date))}.pdf',
    );
  }

  // ==================== STOCK REPORT ====================

  Future<void> exportStockToExcelWeb(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Stock Report'];

    sheet.appendRow([TextCellValue('STOCK REPORT')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('SUMMARY')]);
    sheet.appendRow([
      TextCellValue('Total Products:'),
      TextCellValue(summary.totalProducts.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Total Inventory Value:'),
      _currencyCell(summary.totalInventoryValue),
    ]);
    sheet.appendRow([
      TextCellValue('Total Potential Revenue:'),
      _currencyCell(summary.totalPotentialRevenue),
    ]);
    sheet.appendRow([
      TextCellValue('Low Stock Items:'),
      TextCellValue(summary.lowStockCount.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Out of Stock:'),
      TextCellValue(summary.outOfStockCount.toString()),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('PRODUCTS')]);
    sheet.appendRow([
      TextCellValue('Product'),
      TextCellValue('Stock'),
      TextCellValue('Status'),
    ]);

    for (var r in reports) {
      sheet.appendRow([
        TextCellValue(r.productName),
        TextCellValue(r.stockQuantity.toString()),
        TextCellValue(_getStockStatusText(r)),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _downloadBytes(bytes, 'Stock_Report.xlsx');
    }
  }

    Future<void> exportStockToPdfWeb(
    List<StockReport> reports,
    StockSummary summary,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildPdfHeader('STOCK REPORT', ''),
          pw.Text(
            'SUMMARY',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              children: [
                _buildPdfSummaryRow(
                  'Total Products:',
                  summary.totalProducts.toString(),
                ),
                pw.SizedBox(height: 4),
                _buildPdfSummaryRow(
                  'Total Inventory Value:',
                  'NGN${_formatter.format(summary.totalInventoryValue)}',
                  bold: true,
                ),
                pw.SizedBox(height: 4),
                _buildPdfSummaryRow(
                  'Total Potential Revenue:',
                  'NGN${_formatter.format(summary.totalPotentialRevenue)}',
                ),
                pw.SizedBox(height: 4),
                _buildPdfSummaryRow(
                  'Low Stock Items:',
                  summary.lowStockCount.toString(),
                ),
                pw.SizedBox(height: 4),
                _buildPdfSummaryRow(
                  'Out of Stock:',
                  summary.outOfStockCount.toString(),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'PRODUCTS',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey300,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Product',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Stock',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Status',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                ...reports.map(
                  (r) => pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(r.productName)),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            r.stockQuantity.toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            _getStockStatusText(r),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildPdfFooter(),
        ],
      ),
    );
    final bytes = await pdf.save();
    await _downloadBytes(bytes, 'Stock_Report.pdf');
  }

  // ==================== CASH BOOK ====================

  Future<void> exportCashBookToExcelWeb(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Cash Book'];

    sheet.appendRow([TextCellValue('CASH BOOK')]);
    sheet.appendRow([TextCellValue('Date: ${_dateFormatShort.format(date)}')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('SUMMARY')]);
    sheet.appendRow([
      TextCellValue('Cash In:'),
      _currencyCell(summary.totalCashIn),
    ]);
    sheet.appendRow([
      TextCellValue('Cash Out:'),
      _currencyCell(summary.totalCashOut),
    ]);
    sheet.appendRow([
      TextCellValue('Net Cash:'),
      _currencyCell(summary.netCash),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('TRANSACTIONS')]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Category'),
      TextCellValue('Description'),
    ]);

    for (var t in transactions) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(t.date)),
        TextCellValue(t.type.toString().split('.').last),
        _currencyCell(t.amount),
        TextCellValue(t.category),
        TextCellValue(t.description),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _downloadBytes(
        bytes,
        'Cash_Book_${_sanitizeFileName(_dateFormatShort.format(date))}.xlsx',
      );
    }
  }

  Future<void> exportCashBookToPdfWeb(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader(
              'CASH BOOK',
              'Date: ${_dateFormatShort.format(date)}',
            ),
            pw.Text(
              'SUMMARY',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  _buildPdfSummaryRow(
                    'Cash In:',
                    'NGN${_formatter.format(summary.totalCashIn)}',
                    bold: true,
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'Cash Out:',
                    'NGN${_formatter.format(summary.totalCashOut)}',
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'Net Cash:',
                    'NGN${_formatter.format(summary.netCash)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'TRANSACTIONS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Category',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...transactions.map(
                    (t) => pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(t.date),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              t.type.toString().split('.').last,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'NGN${_formatter.format(t.amount)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(flex: 2, child: pw.Text(t.category)),
                          pw.Expanded(flex: 3, child: pw.Text(t.description)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _buildPdfFooter(),
          ],
        ),
      ),
    );
    final bytes = await pdf.save();
    await _downloadBytes(
      bytes,
      'Cash_Book_${_sanitizeFileName(_dateFormatShort.format(date))}.pdf',
    );
  }

  // ==================== STOCK MOVEMENTS ====================

  Future<void> exportStockMovementsToExcelWeb(
    List<StockMovement> movements,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange = _sanitizeFileName(
        '${_dateFormatShort.format(startDate)} to ${_dateFormatShort.format(endDate)}',
      );
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Stock Movements'];

    sheet.appendRow([TextCellValue('STOCK MOVEMENTS')]);
    if (dateRange.isNotEmpty) {
      sheet.appendRow([TextCellValue('Date Range: $dateRange')]);
    }
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Product'),
      TextCellValue('Type'),
      TextCellValue('Quantity'),
      TextCellValue('Balance'),
      TextCellValue('Reference'),
    ]);

    for (var m in movements) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(m.date)),
        TextCellValue(m.productName),
        TextCellValue(m.movementType),
        TextCellValue(m.quantity.toString()),
        TextCellValue(m.balanceAfter.toString()),
        TextCellValue(m.reference),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _downloadBytes(
        bytes,
        'Stock_Movements${dateRange.isNotEmpty ? '_$dateRange' : ''}.xlsx',
      );
    }
  }

  Future<void> exportStockMovementsToPdfWeb(
    List<StockMovement> movements,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange =
          '${_dateFormatShort.format(startDate)} to ${_dateFormatShort.format(endDate)}';
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader(
              'STOCK MOVEMENTS',
              dateRange.isNotEmpty ? 'Date Range: $dateRange' : '',
            ),
            pw.Text(
              'TRANSACTIONS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            'Product',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Bal',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Ref',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...movements.map(
                    (m) => pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(m.date),
                            ),
                          ),
                          pw.Expanded(flex: 3, child: pw.Text(m.productName)),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.movementType,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.quantity.toString(),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.balanceAfter.toString(),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(flex: 2, child: pw.Text(m.reference)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _buildPdfFooter(),
          ],
        ),
      ),
    );
    final bytes = await pdf.save();
    await _downloadBytes(
      bytes,
      'Stock_Movements${dateRange.isNotEmpty ? '_$dateRange' : ''}.pdf',
    );
  }

  // ==================== BINCARD ====================

  Future<void> exportBincardToExcel(
    Product product,
    List<dynamic> movements,
    dynamic dateRange,
    double openingBalance,
    double totalIn,
    double totalOut,
    double closingBalance,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Bincard'];

    sheet.appendRow([TextCellValue('BINCARD - ${product.name}')]);
    sheet.appendRow([TextCellValue('SKU: ${product.sku}')]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Opening Balance:'),
      TextCellValue(openingBalance.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Total In:'),
      TextCellValue(totalIn.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Total Out:'),
      TextCellValue(totalOut.toString()),
    ]);
    sheet.appendRow([
      TextCellValue('Closing Balance:'),
      TextCellValue(closingBalance.toString()),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Quantity'),
      TextCellValue('Balance'),
      TextCellValue('Reference'),
    ]);

    for (var m in movements) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(m.date)),
        TextCellValue(m.movementType),
        TextCellValue(m.quantity.toString()),
        TextCellValue(m.balanceAfter.toString()),
        TextCellValue(m.reference),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await _downloadBytes(
        bytes,
        'Bincard_${_sanitizeFileName(product.name)}.xlsx',
      );
    }
  }

  Future<void> exportBincardToPDF(
    Product product,
    List<dynamic> movements,
    dynamic dateRange,
    double openingBalance,
    double totalIn,
    double totalOut,
    double closingBalance,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPdfHeader('BINCARD', 'Product: ${product.name}'),
            pw.Text('SKU: ${product.sku}', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  _buildPdfSummaryRow(
                    'Opening Balance:',
                    openingBalance.toString(),
                  ),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow('Total In:', totalIn.toString()),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow('Total Out:', totalOut.toString()),
                  pw.SizedBox(height: 4),
                  _buildPdfSummaryRow(
                    'Closing Balance:',
                    closingBalance.toString(),
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'MOVEMENTS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.grey300,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Bal',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Ref',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...movements.map(
                    (m) => pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey300),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(m.date),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.movementType,
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.quantity.toString(),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              m.balanceAfter.toString(),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(flex: 2, child: pw.Text(m.reference)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _buildPdfFooter(),
          ],
        ),
      ),
    );
    final bytes = await pdf.save();
    await _downloadBytes(
      bytes,
      'Bincard_${_sanitizeFileName(product.name)}.pdf',
    );
  }

  Future<void> exportStockMovementsToPDF(
    List<StockMovement> movements,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    return exportStockMovementsToPdfWeb(movements, startDate, endDate);
  }

  Future<void> exportStockMovementsToExcel(
    List<StockMovement> movements,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    return exportStockMovementsToExcelWeb(movements, startDate, endDate);
  }

  Future<void> exportSalesReportToExcel(
    SalesReportData reportData,
    DateTime date,
  ) async {
    return exportSalesReportToExcelWeb(reportData, date);
  }

  Future<void> exportSalesReportToPdf(
    SalesReportData reportData,
    DateTime date,
  ) async {
    return exportSalesReportToPdfWeb(reportData, date);
  }

  Future<void> exportCashBookToExcel(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    return exportCashBookToExcelWeb(transactions, summary, date);
  }

  Future<void> exportCashBookToPdf(
    List<CashTransaction> transactions,
    CashSummary summary,
    DateTime date,
  ) async {
    return exportCashBookToPdfWeb(transactions, summary, date);
  }  
}
