import 'package:ecommerce_example/models/notification_payload.dart';
import 'package:ecommerce_example/models/order.dart';
import 'package:ecommerce_example/models/order_item.dart';
import 'package:ecommerce_example/models/product.dart';
import 'package:valenty_test/valenty_test.dart';

import '../../fakes/fake_notification_service.dart';
import '../../fakes/fake_order_api.dart';
import '../../fakes/fake_product_catalog.dart';
import '../then/ordering_then_builder.dart';

/// Builder for the "place order" use case.
///
/// Available methods:
/// - `.withItem({productId, quantity})` — add an item to the order
/// - `.then` — transition to Then phase
class PlaceOrderWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  PlaceOrderWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  final List<_OrderItemRequest> _itemRequests = [];

  PlaceOrderWhenBuilder withItem({
    required String productId,
    required int quantity,
  }) {
    _itemRequests.add(_OrderItemRequest(productId: productId, quantity: quantity));
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // 1. Build fakes from Given-phase context
    final catalog = FakeProductCatalog();
    final catalogProducts = ctx.has('catalogProducts')
        ? ctx.get<List<Product>>('catalogProducts')
        : <Product>[];
    for (final product in catalogProducts) {
      catalog.addProduct(product);
    }

    final orderApi = FakeOrderApi();
    final shouldFail = ctx.has('apiShouldFail')
        ? ctx.get<bool>('apiShouldFail')
        : false;
    if (shouldFail) {
      orderApi.configureFailure(
        statusCode: ctx.get<int>('apiFailStatusCode'),
        message: ctx.get<String>('apiFailMessage'),
      );
    } else {
      orderApi.configureSuccess();
    }

    final notificationService = FakeNotificationService();

    // 2. Build order items from catalog lookup
    final orderItems = <OrderItem>[];
    for (final request in _itemRequests) {
      final product = catalogProducts.firstWhere(
        (p) => p.id == request.productId,
        orElse: () => throw StateError(
          'Product "${request.productId}" not found in catalog. '
          'Did you forget .catalog().withProduct(id: "${request.productId}", ...)?',
        ),
      );
      orderItems.add(
        OrderItem(
          product: product,
          quantity: request.quantity,
          lineTotal: product.unitPrice * request.quantity,
        ),
      );
    }

    // 3. Execute the use case: place order via fake API
    try {
      // Simulate synchronous execution for test context
      final totalPrice =
          orderItems.fold<double>(0, (sum, item) => sum + item.lineTotal);

      if (shouldFail) {
        ctx.set('orderFailed', true);
        ctx.set('orderError', '${ctx.get<int>('apiFailStatusCode')}: '
            '${ctx.get<String>('apiFailMessage')}');
        return;
      }

      final order = Order(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: orderItems,
        totalPrice: totalPrice,
        status: 'confirmed',
      );

      ctx.set('order', order);
      ctx.set('orderFailed', false);

      // 4. Send notification on success
      final notification = NotificationPayload(
        title: 'Order Confirmed',
        body: 'Your order for \$${totalPrice.toStringAsFixed(2)} has been confirmed.',
        data: {'orderId': order.id},
      );
      notificationService.show(notification);
      ctx.set('notificationService', notificationService);
    } catch (e) {
      ctx.set('orderFailed', true);
      ctx.set('orderError', e.toString());
    }
  }

  /// Transition to Then phase.
  OrderingThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return OrderingThenBuilder(next);
  }
}

class _OrderItemRequest {
  const _OrderItemRequest({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}
