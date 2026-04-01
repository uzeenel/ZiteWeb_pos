import 'package:pos_system/models/cash_book.dart';
import 'package:pos_system/services/api_service.dart';

class CashBookService {
  // Get transactions by date range
  Future<List<CashTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await ApiService.getCashTransactions(start, end);
      return response
          .map((json) => CashTransaction.fromMap(_convertNumbers(json)))
          .toList();
    } catch (e) {
      print('Error fetching cash transactions: $e');
      return [];
    }
  }

  // Helper to convert string numbers to actual numbers
  Map<String, dynamic> _convertNumbers(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);

    // Convert amount from string to double
    if (converted['amount'] is String) {
      converted['amount'] = double.tryParse(converted['amount']) ?? 0;
    }

    return converted;
  }

  // Get summary for date range
  Future<CashSummary> getSummaryForDateRange(
    DateTime start,
    DateTime end,
    double openingBalance,
  ) async {
    try {
      final transactions = await getTransactionsByDateRange(start, end);

      double totalCashIn = 0;
      double totalCashOut = 0;

      for (var t in transactions) {
        if (t.type == TransactionType.cashIn) {
          totalCashIn += t.amount;
        } else {
          totalCashOut += t.amount;
        }
      }

      final netCash = totalCashIn - totalCashOut;
      final closingBalance = openingBalance + netCash;

      return CashSummary(
        openingBalance: openingBalance,
        totalCashIn: totalCashIn,
        totalCashOut: totalCashOut,
        netCash: netCash,
        closingBalance: closingBalance,
        transactionCount: transactions.length,
      );
    } catch (e) {
      print('Error getting cash summary: $e');
      return CashSummary(
        openingBalance: openingBalance,
        totalCashIn: 0,
        totalCashOut: 0,
        netCash: 0,
        closingBalance: openingBalance,
        transactionCount: 0,
      );
    }
  }

  // Add transaction
  Future<CashTransaction> addTransaction(CashTransaction transaction) async {
    try {
      // Ensure amount is positive for storage
      final positiveAmount = transaction.amount.abs();

      final response = await ApiService.addCashTransaction(
        date: transaction.date,
        type: transaction.type == TransactionType.cashIn
            ? 'cash_in'
            : 'cash_out',
        amount: positiveAmount,
        category: transaction.category,
        description: transaction.description,
        reference: transaction.reference,
        userId: null,
      );

      return CashTransaction(
        id: response['id'] as int?,
        date: transaction.date,
        type: transaction.type,
        amount: positiveAmount,
        category: transaction.category,
        description: transaction.description,
        reference: transaction.reference,
        createdAt: transaction.createdAt,
      );
    } catch (e) {
      print('Error adding cash transaction: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    try {
      await ApiService.deleteCashTransaction(id);
    } catch (e) {
      print('Error deleting cash transaction: $e');
      rethrow;
    }
  }

  // Get single transaction
  Future<CashTransaction?> getTransaction(int id) async {
    try {
      final response = await ApiService.getCashTransaction(id);
      if (response != null) {
        final converted = _convertNumbers(response);
        return CashTransaction.fromMap(converted);
      }
      return null;
    } catch (e) {
      print('Error getting cash transaction: $e');
      return null;
    }
  }

  // Check if auto cash book is enabled
  Future<bool> isAutoCashBookEnabled() async {
    return true;
  }
}
