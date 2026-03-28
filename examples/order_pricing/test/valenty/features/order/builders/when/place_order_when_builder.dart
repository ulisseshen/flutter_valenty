import 'package:valenty_test/valenty_test.dart';

import '../../../../../../lib/models/order.dart';
import '../../../../../../lib/models/product.dart';
import '../then/order_then_builder.dart';

/// Builder for the "place order" use case.
///
/// Available methods:
/// - `.withQuantity(int)` — set order quantity
/// - `.then` — transition to Then phase
class PlaceOrderWhenBuilder extends DomainObjectBuilder<NeedsThen> {
  PlaceOrderWhenBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  PlaceOrderWhenBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final product = ctx.get<Product>('product');
    final discount = ctx.has('couponDiscount')
        ? ctx.get<double>('couponDiscount')
        : 0.0;
    final rawPrice = product.unitPrice * _quantity;
    final basePrice = rawPrice - (rawPrice * discount);

    ctx.set(
      'order',
      Order(
        quantity: _quantity,
        basePrice: basePrice,
        success: _quantity > 0,
      ),
    );
  }

  /// Transition to Then phase.
  OrderThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return OrderThenBuilder(next);
  }
}
