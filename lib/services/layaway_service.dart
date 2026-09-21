import 'package:zite_web_pos/models/layaway.dart';
import 'package:zite_web_pos/services/api_service.dart';

class LayawayService {
  Future<List<LayawayOrder>> getLayawayOrders() async {
    try {
      final response = await ApiService.getLayawayOrders();
      return response.map((json) => LayawayOrder.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching layaway orders: $e');
      return [];
    }
  }

  Future<LayawayOrder?> getLayawayOrder(int id) async {
    try {
      final response = await ApiService.getLayawayOrder(id);
      if (response != null) {
        return LayawayOrder.fromMap(response);
      }
      return null;
    } catch (e) {
      print('Error fetching layaway order: $e');
      return null;
    }
  }

  Future<List<LayawayPayment>> getLayawayPayments(int layawayId) async {
    try {
      final response = await ApiService.getLayawayPayments(layawayId);
      return response.map((json) => LayawayPayment.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching layaway payments: $e');
      return [];
    }
  }

  Future<void> recordPayment(
    int layawayId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      await ApiService.recordLayawayPayment(layawayId, amount, paymentMethod);
    } catch (e) {
      print('Error recording layaway payment: $e');
      rethrow;
    }
  }

  Future<void> completeLayaway(int layawayId) async {
    try {
      await ApiService.completeLayaway(layawayId);
    } catch (e) {
      print('Error completing layaway: $e');
      rethrow;
    }
  }

  Future<void> cancelLayaway(int layawayId) async {
    try {
      await ApiService.cancelLayaway(layawayId);
    } catch (e) {
      print('Error cancelling layaway: $e');
      rethrow;
    }
  }
}
