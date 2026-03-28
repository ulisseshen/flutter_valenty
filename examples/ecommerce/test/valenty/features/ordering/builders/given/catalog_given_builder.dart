import 'package:ecommerce_example/models/product.dart';
import 'package:valenty_test/valenty_test.dart';

import '../when/ordering_when_builder.dart';
import 'ordering_given_builder.dart';

/// Builder for adding a product to the fake catalog in the Given phase.
///
/// Available methods:
/// - `.withProduct({id, name, unitPrice})` — add a product
/// - `.withProducts(List<Product>)` — add multiple products
/// - `.when` — transition to When phase
/// - `.and` — add more domain objects
class CatalogGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  CatalogGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  final List<Product> _products = [];

  CatalogGivenBuilder withProduct({
    required String id,
    required String name,
    required double unitPrice,
    String sku = '',
  }) {
    _products.add(Product(id: id, name: name, unitPrice: unitPrice, sku: sku));
    return this;
  }

  CatalogGivenBuilder withProducts(List<Product> products) {
    _products.addAll(products);
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    // Accumulate products across multiple catalog() calls
    final existing = ctx.has('catalogProducts')
        ? ctx.get<List<Product>>('catalogProducts')
        : <Product>[];
    ctx.set('catalogProducts', [...existing, ..._products]);
  }

  /// Transition to When phase.
  OrderingWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return OrderingWhenBuilder(next);
  }

  /// Add another domain object to the Given phase.
  OrderingGivenBuilder get and {
    final finalized = finalizeStep();
    return OrderingGivenBuilder(finalized);
  }
}
