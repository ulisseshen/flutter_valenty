import 'package:ecommerce_example/models/order.dart';
import 'package:ecommerce_example/models/order_item.dart';
import 'package:ecommerce_example/ports/order_api_port.dart';

/// In-memory fake for OrderApiPort (replaces HTTP API).
///
/// Can be configured to succeed (building an Order from items) or fail
/// with a specified status code and message.
class FakeOrderApi implements OrderApiPort {
  bool _shouldFail = false;
  int _failStatusCode = 500;
  String _failMessage = 'Internal server error';

  void configureSuccess() {
    _shouldFail = false;
  }

  void configureFailure({required int statusCode, required String message}) {
    _shouldFail = true;
    _failStatusCode = statusCode;
    _failMessage = message;
  }

  @override
  Future<Order> placeOrder(List<OrderItem> items) async {
    if (_shouldFail) {
      throw OrderApiException(
        statusCode: _failStatusCode,
        message: _failMessage,
      );
    }

    final totalPrice =
        items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      items: items,
      totalPrice: totalPrice,
      status: 'confirmed',
    );
  }

  @override
  Future<Order> getOrder(String id) async {
    throw UnimplementedError('getOrder not needed for these scenarios');
  }
}

class OrderApiException implements Exception {
  const OrderApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'OrderApiException($statusCode): $message';
}
