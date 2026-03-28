import 'package:valenty_test/valenty_test.dart';

import '../when/order_when_builder.dart';
import 'order_given_builder.dart';

/// Builder for setting up a Coupon in the Given phase.
///
/// Available methods:
/// - `.withCode(String)` — set coupon code
/// - `.withDiscount(double)` — set discount percentage (0.0 to 1.0)
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class CouponGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CouponGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _code = 'DEFAULT';
  double _discount = 0;

  CouponGivenBuilder withCode(String code) {
    _code = code;
    return this;
  }

  CouponGivenBuilder withDiscount(double discount) {
    _discount = discount;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('couponCode', _code);
    ctx.set('couponDiscount', _discount);
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
