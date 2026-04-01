import 'package:pos_system/models/purchase_order.dart';
import 'package:pos_system/services/api_service.dart';

class PurchaseOrderService {
  // Get all purchase orders (returns List<Map<String, dynamic>> for list screens)
  Future<List<Map<String, dynamic>>> getAllPurchaseOrders() async {
    try {
      final response = await ApiService.getPurchaseOrders();
      return response;
    } catch (e) {
      print('Error fetching purchase orders from API: $e');
      return [];
    }
  }

  // Get purchase order details by ID (returns Map with 'order' and 'items')
  Future<Map<String, dynamic>> getPurchaseOrderDetails(int id) async {
    try {
      final response = await ApiService.getPurchaseOrderDetail(id);
      return {
        'order': response['purchaseOrder'] ?? {},
        'items': response['items'] ?? [],
      };
    } catch (e) {
      print('Error fetching purchase order detail from API: $e');
      return {'order': {}, 'items': []};
    }
  }

  // Get purchase order for receiving (alias for getPurchaseOrderDetails)
  Future<Map<String, dynamic>> getPurchaseOrderForReceiving(int id) async {
    return await getPurchaseOrderDetails(id);
  }

  // Get pending purchase orders
  Future<List<Map<String, dynamic>>> getPendingPurchaseOrders() async {
    try {
      final orders = await ApiService.getPurchaseOrders();
      return orders.where((o) => o['status'] == 'pending').toList();
    } catch (e) {
      print('Error fetching pending purchase orders: $e');
      return [];
    }
  }

  // Create purchase order
  Future<Map<String, dynamic>> createPurchaseOrder({
    required int vendorId,
    required List<Map<String, dynamic>> items,
    String? notes,
    int? createdBy,
    String? invoiceNumber, // Add invoice number parameter
  }) async {
    try {
      final poData = {
        'vendorId': vendorId,
        'items': items,
        'notes': notes,
        'createdBy': createdBy,
        'invoiceNumber': invoiceNumber, // Include invoice number if provided
      };

      final response = await ApiService.createPurchaseOrder(poData);
      return {'poNumber': response['po_number'], 'id': response['id']};
    } catch (e) {
      print('Error creating purchase order via API: $e');
      rethrow;
    }
  }

  // Create direct purchase order (for receive stock screen)
  Future<int> createDirectPurchaseOrder({
    required int vendorId,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? invoiceNumber, // Add invoice number parameter
  }) async {
    try {
      final result = await createPurchaseOrder(
        vendorId: vendorId,
        items: items,
        notes: notes,
        invoiceNumber: invoiceNumber, // Pass invoice number
      );
      return result['id'];
    } catch (e) {
      print('Error creating direct purchase order: $e');
      return -1;
    }
  }

  // Add item to direct purchase order
  Future<void> addDirectPurchaseItem({
    required int purchaseOrderId,
    required int productId,
    required double quantity,
    required double unitPrice,
  }) async {
    try {
      await ApiService.addPurchaseOrderItem(
        purchaseOrderId,
        productId,
        quantity,
        unitPrice,
      );
    } catch (e) {
      print('Error adding direct purchase item: $e');
      rethrow;
    }
  }

  // Update purchase order status
  Future<bool> updatePurchaseOrderStatus(int id, String status) async {
    try {
      await ApiService.updatePurchaseOrderStatus(id, status);
      return true;
    } catch (e) {
      print('Error updating purchase order status via API: $e');
      return false;
    }
  }

  // Receive purchase order items with optional invoice number
  Future<bool> receivePurchaseOrder(
    int poId,
    List<Map<String, dynamic>> receivedItems, {
    String? invoiceNumber, // Add optional invoice number parameter
  }) async {
    try {
      // Prepare the data to send to API
      final receiveData = {
        'items': receivedItems,
        'invoiceNumber': invoiceNumber, // Include invoice number if provided
      };

      await ApiService.receivePurchaseOrderItems(poId, receiveData);
      return true;
    } catch (e) {
      print('Error receiving items via API: $e');
      return false;
    }
  }

  // Cancel purchase order
  Future<bool> cancelPurchaseOrder(int id, String reason) async {
    try {
      await ApiService.cancelPurchaseOrder(id, reason);
      return true;
    } catch (e) {
      print('Error cancelling purchase order via API: $e');
      return false;
    }
  }

  // Get purchase orders by invoice number (for searching)
  Future<List<Map<String, dynamic>>> getPurchaseOrdersByInvoiceNumber(
    String invoiceNumber,
  ) async {
    try {
      final allOrders = await getAllPurchaseOrders();
      return allOrders
          .where(
            (order) =>
                order['invoice_number']?.toLowerCase() ==
                invoiceNumber.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('Error fetching purchase orders by invoice number: $e');
      return [];
    }
  }

  // Get purchase orders by vendor and date range
  Future<List<Map<String, dynamic>>> getPurchaseOrdersByVendorAndDate({
    required int vendorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allOrders = await getAllPurchaseOrders();
      return allOrders.where((order) {
        // Filter by vendor
        if (order['vendor_id'] != vendorId) return false;

        // Filter by date range if provided
        if (startDate != null && endDate != null) {
          final orderDate = DateTime.parse(order['order_date']);
          return orderDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              orderDate.isBefore(endDate.add(const Duration(days: 1)));
        }

        return true;
      }).toList();
    } catch (e) {
      print('Error fetching purchase orders by vendor and date: $e');
      return [];
    }
  }

  // Update purchase order with invoice number (for adding invoice after creation)
  Future<bool> updatePurchaseOrderInvoiceNumber(
    int poId,
    String invoiceNumber,
  ) async {
    try {
      await ApiService.updatePurchaseOrder(poId, {
        'invoice_number': invoiceNumber,
      });
      return true;
    } catch (e) {
      print('Error updating purchase order invoice number: $e');
      return false;
    }
  }

  // Get purchase order statistics
  Future<Map<String, dynamic>> getPurchaseOrderStatistics() async {
    try {
      final orders = await getAllPurchaseOrders();

      int totalOrders = orders.length;
      int pendingOrders = orders.where((o) => o['status'] == 'pending').length;
      int receivedOrders = orders
          .where((o) => o['status'] == 'received')
          .length;
      int cancelledOrders = orders
          .where((o) => o['status'] == 'cancelled')
          .length;

      double totalValue = 0;
      for (var order in orders) {
        totalValue += (order['total'] ?? 0).toDouble();
      }

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'receivedOrders': receivedOrders,
        'cancelledOrders': cancelledOrders,
        'totalValue': totalValue,
        'averageOrderValue': totalOrders > 0 ? totalValue / totalOrders : 0,
      };
    } catch (e) {
      print('Error getting purchase order statistics: $e');
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'receivedOrders': 0,
        'cancelledOrders': 0,
        'totalValue': 0,
        'averageOrderValue': 0,
      };
    }
  }
}
