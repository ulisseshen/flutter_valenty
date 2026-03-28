import 'package:valenty_test/valenty_test.dart';

import '../../../../../../lib/models/product.dart';
import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

/// Builder for setting up a Product in the Given phase.
///
/// Available methods:
/// - `.withName(String)` — set product name
/// - `.withUnitPrice(double)` — set unit price
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class ProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  ProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'Default Product';
  double _unitPrice = 0;

  ProductGivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  ProductGivenBuilder withUnitPrice(double price) {
    _unitPrice = price;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
  }

  /// Transition to When phase.
  OrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  OrderGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderGivenBuilder(finalized);
  }
}
