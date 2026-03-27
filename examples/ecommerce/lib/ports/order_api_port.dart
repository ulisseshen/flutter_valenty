import '../models/order.dart';
import '../models/order_item.dart';

/// Port for placing and retrieving orders (backed by HTTP API).
abstract class OrderApiPort {
  Future<Order> placeOrder(List<OrderItem> items);
  Future<Order> getOrder(String id);
}
