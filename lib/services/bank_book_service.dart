import 'package:zite_web_pos/models/bank_book.dart';
import 'package:zite_web_pos/services/api_service.dart';

class BankBookService {
  // Get transactions by date range
 Future<List<BankTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await ApiService.getBankTransactions(start, end);
      print('API Response length: ${response.length}');

      return response.map((json) {
        // Create a safe copy with defaults for null values
        final safeJson = Map<String, dynamic>.from(json);

        // Ensure string fields are never null
        safeJson['account_name'] = safeJson['account_name'] ?? '';
        safeJson['bank_name'] = safeJson['bank_name'] ?? '';
        safeJson['description'] = safeJson['description'] ?? '';
        safeJson['reference'] = safeJson['reference'] ?? '';
        safeJson['cheque_number'] = safeJson['cheque_number'];

        // Ensure amount is a number
        if (safeJson['amount'] is String) {
          safeJson['amount'] = double.tryParse(safeJson['amount']) ?? 0.0;
        }

        return BankTransaction.fromMap(safeJson);
      }).toList();
    } catch (e) {
      print('Error fetching bank transactions: $e');
      return [];
    }
  }

  Map<String, dynamic> _convertNumbers(Map<String, dynamic> json) {
    final converted = Map<String, dynamic>.from(json);
    if (converted['amount'] is String) {
      converted['amount'] = double.tryParse(converted['amount']) ?? 0;
    }
    return converted;
  }

  // Get summary for date range - calculate from transactions
  Future<BankSummary> getSummaryForDateRange(
    DateTime start,
    DateTime end,
    Map<String, double> openingBalances,
  ) async {
    try {
      // Get transactions for this date range
      final transactions = await getTransactionsByDateRange(start, end);

      double totalDeposits = 0;
      double totalWithdrawals = 0;

      for (var t in transactions) {
        if (t.type == BankTransactionType.deposit) {
          totalDeposits += t.amount;
        } else if (t.type == BankTransactionType.withdrawal) {
          totalWithdrawals += t.amount;
        }
      }

      final netChange = totalDeposits - totalWithdrawals;
      final transactionCount = transactions.length;

      // Get opening balance from previous transactions
      final prevTransactions = await getTransactionsByDateRange(
        DateTime(2000, 1, 1),
        start,
      );

      double prevBalance = 0;
      for (var t in prevTransactions) {
        if (t.type == BankTransactionType.deposit) {
          prevBalance += t.amount;
        } else if (t.type == BankTransactionType.withdrawal) {
          prevBalance -= t.amount;
        }
      }

      final openingBalance = prevBalance;
      final closingBalance = openingBalance + netChange;

      return BankSummary(
        totalDeposits: totalDeposits,
        totalWithdrawals: totalWithdrawals,
        netChange: netChange,
        openingBalance: openingBalance,
        closingBalance: closingBalance,
        transactionCount: transactionCount,
        bankBalances: {},
      );
    } catch (e) {
      print('Error getting bank summary: $e');
      return BankSummary(
        totalDeposits: 0,
        totalWithdrawals: 0,
        netChange: 0,
        openingBalance: 0,
        closingBalance: 0,
        transactionCount: 0,
        bankBalances: {},
      );
    }
  }

  // Add transaction
  Future<BankTransaction> addTransaction(BankTransaction transaction) async {
    try {
      final response = await ApiService.addBankTransaction(
        date: transaction.date,
        type: transaction.type == BankTransactionType.deposit
            ? 'deposit'
            : (transaction.type == BankTransactionType.withdrawal
                  ? 'withdrawal'
                  : 'transfer'),
        amount: transaction.amount.abs(),
        accountName: transaction.accountName,
        bankName: transaction.bankName,
        description: transaction.description,
        reference: transaction.reference,
        userId: transaction.userId,
      );

      return BankTransaction(
        id: response['id'] as int?,
        date: transaction.date,
        type: transaction.type,
        amount: transaction.amount.abs(),
        accountName: transaction.accountName,
        bankName: transaction.bankName,
        chequeNumber: transaction.chequeNumber,
        description: transaction.description,
        reference: transaction.reference,
        userId: transaction.userId,
        createdAt: transaction.createdAt,
      );
    } catch (e) {
      print('Error adding bank transaction: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    try {
      await ApiService.deleteBankTransaction(id);
    } catch (e) {
      print('Error deleting bank transaction: $e');
      rethrow;
    }
  }

  // Get single transaction
  Future<BankTransaction?> getTransaction(int id) async {
    try {
      final response = await ApiService.getBankTransaction(id);
      if (response != null) {
        return BankTransaction.fromMap(_convertNumbers(response));
      }
      return null;
    } catch (e) {
      print('Error getting bank transaction: $e');
      return null;
    }
  }
}
