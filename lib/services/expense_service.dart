import 'package:pos_system/models/expense.dart';
import 'package:pos_system/services/api_service.dart';

class ExpenseService {
  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    try {
      final response = await ApiService.getExpenses();
      return response.map((json) => Expense.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching expenses from API: $e');
      return [];
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await ApiService.getExpensesByDateRange(start, end);
      return response.map((json) => Expense.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching expenses by date range from API: $e');
      return [];
    }
  }

  // Get summary for date range
  Future<ExpenseSummary> getSummaryForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await getExpensesByDateRange(start, end);

      double totalExpenses = 0;
      Map<ExpenseCategory, double> categoryTotals = {};

      for (var expense in expenses) {
        totalExpenses += expense.amount;
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      return ExpenseSummary(
        totalExpenses: totalExpenses,
        totalByCategory: totalExpenses,
        transactionCount: expenses.length,
        categoryTotals: categoryTotals,
      );
    } catch (e) {
      print('Error getting expense summary: $e');
      return ExpenseSummary(
        totalExpenses: 0.0,
        totalByCategory: 0.0,
        transactionCount: 0,
        categoryTotals: {},
      );
    }
  }

  // Get expense by ID
  Future<Expense?> getExpenseById(int id) async {
    try {
      final response = await ApiService.getExpenseById(id);
      if (response.isNotEmpty) {
        return Expense.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching expense by ID from API: $e');
      return null;
    }
  }

  // Add expense
  Future<Expense> addExpense(Expense expense) async {
    try {
      final response = await ApiService.addExpense(expense.toMap());
      return Expense.fromMap(response);
    } catch (e) {
      print('Error adding expense via API: $e');
      rethrow;
    }
  }

  // Update expense
  Future<bool> updateExpense(Expense expense) async {
    try {
      await ApiService.updateExpense(expense.id!, expense.toMap());
      return true;
    } catch (e) {
      print('Error updating expense via API: $e');
      return false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int id) async {
    try {
      await ApiService.deleteExpense(id);
      return true;
    } catch (e) {
      print('Error deleting expense via API: $e');
      return false;
    }
  }

  // Get expense summary
  Future<Map<String, double>> getExpenseSummary() async {
    try {
      return await ApiService.getExpenseSummary();
    } catch (e) {
      print('Error fetching expense summary from API: $e');
      return {};
    }
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory() async {
    try {
      return await ApiService.getExpensesByCategory();
    } catch (e) {
      print('Error fetching expenses by category from API: $e');
      return {};
    }
  }
}
