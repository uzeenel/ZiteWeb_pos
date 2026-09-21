// lib/services/stock_movement_service.dart
import 'package:zite_web_pos/models/stock_movement.dart';
import 'package:zite_web_pos/services/api_service.dart';

class StockMovementService {
  // No need for _api instance - use ApiService directly

  Future<List<StockMovement>> getMovementsByProduct(int productId) async {
    try {
      print('Fetching movements for product ID: $productId');
      final response = await ApiService.getProductBincard(productId);
      print('API response: ${response.length} movements');
      for (var m in response) {
        print(
          '  - ${m['date']}: ${m['movement_type']} ${m['quantity']} (${m['reference']})',
        );
      }
      return response.map((m) => StockMovement.fromMap(m)).toList();
    } catch (e) {
      print('Error fetching stock movements: $e');
      return [];
    }
  }

  Future<List<StockMovement>> getMovementsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      print(
        '🔍 Fetching movements from ${start.toIso8601String()} to ${end.toIso8601String()}',
      );
      final response = await ApiService.getStockMovements(
        start: start,
        end: end,
      );
      print('🔍 Got ${response.length} movements');
      return response.map((m) => StockMovement.fromMap(m)).toList();
    } catch (e) {
      print('Error fetching stock movements by date: $e');
      return [];
    }
  }

  Future<List<StockMovement>> getMovementsByReference(String reference) async {
    try {
      final response = await ApiService.getStockMovements(reference: reference);
      return response.map((m) => StockMovement.fromMap(m)).toList();
    } catch (e) {
      print('Error fetching stock movements by reference: $e');
      return [];
    }
  }

  Future<StockMovement?> recordManualAdjustment({
    required int productId,
    required double quantity,
    required String reason,
    String? invoiceNumber,
  }) async {
    try {
      final response = await ApiService.recordStockMovement(
        productId: productId,
        reference: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
        movementType: quantity > 0 ? 'IN' : 'OUT',
        quantity: quantity.abs(),
        notes: reason,
        invoiceNumber: invoiceNumber,
      );
      return StockMovement.fromMap(response);
    } catch (e) {
      print('Error recording manual adjustment: $e');
      return null;
    }
  }
}
