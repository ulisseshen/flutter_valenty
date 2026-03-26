import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/core/test_context.dart';
import 'package:valenty_dsl/src/builders/given_builder.dart';
import 'package:valenty_dsl/src/builders/when_builder.dart';
import 'package:valenty_dsl/src/builders/then_builder.dart';
import 'package:valenty_dsl/src/builders/and_then_builder.dart';
import 'package:valenty_dsl/src/builders/domain_object_builder.dart';
import 'package:valenty_dsl/src/builders/assertion_builder.dart';
import 'package:valenty_dsl/src/builders/feature_scenario.dart';
import 'package:valenty_dsl/src/runner/scenario_runner.dart';

// -- Domain model (would be in user's project) --

class Product {
  Product({required this.name, required this.unitPrice});
  final String name;
  final double unitPrice;
}

class Order {
  Order({
    required this.quantity,
    required this.basePrice,
    required this.success,
  });
  final int quantity;
  final double basePrice;
  final bool success;
}

// -- Generated builders (would be scaffolded by CLI) --

class TestOrderScenario extends FeatureScenario<TestOrderGivenBuilder> {
  TestOrderScenario(super.description);

  @override
  TestOrderGivenBuilder createGivenBuilder(
    ScenarioBuilder<NeedsWhen> scenario,
  ) {
    return TestOrderGivenBuilder(scenario);
  }
}

class TestOrderGivenBuilder extends GivenBuilder {
  TestOrderGivenBuilder(super.scenario);

  TestProductGivenBuilder product() {
    return TestProductGivenBuilder(scenario);
  }
}

class TestProductGivenBuilder extends DomainObjectBuilder<NeedsWhen> {
  TestProductGivenBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _name = 'Default Product';
  double _unitPrice = 0;

  TestProductGivenBuilder withName(String name) {
    _name = name;
    return this;
  }

  TestProductGivenBuilder withUnitPrice(double price) {
    _unitPrice = price;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('product', Product(name: _name, unitPrice: _unitPrice));
  }

  TestOrderWhenBuilder get when {
    final finalized = finalizeStep();
    final next = finalized.addStep<NeedsThen>(
      StepRecord(phase: StepPhase.when, action: (_) {}),
    );
    return TestOrderWhenBuilder(next);
  }

  TestOrderGivenBuilder get and {
    final finalized = finalizeStep();
    return TestOrderGivenBuilder(finalized);
  }
}

class TestOrderWhenBuilder extends WhenBuilder {
  TestOrderWhenBuilder(super.scenario);

  TestPlaceOrderBuilder placeOrder() {
    return TestPlaceOrderBuilder(scenario);
  }
}

class TestPlaceOrderBuilder extends DomainObjectBuilder<NeedsThen> {
  TestPlaceOrderBuilder(ScenarioBuilder<NeedsThen> scenario)
      : super(scenario, StepPhase.when);

  int _quantity = 1;

  TestPlaceOrderBuilder withQuantity(int quantity) {
    _quantity = quantity;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    final product = ctx.get<Product>('product');
    final basePrice = product.unitPrice * _quantity;
    ctx.set(
      'order',
      Order(
        quantity: _quantity,
        basePrice: basePrice,
        success: true,
      ),
    );
  }

  TestOrderThenBuilder get then {
    final finalized = finalizeStep();
    final next = finalized.addStep<ReadyToRun>(
      StepRecord(phase: StepPhase.then, action: (_) {}),
    );
    return TestOrderThenBuilder(next);
  }
}

class TestOrderThenBuilder extends ThenBuilder {
  TestOrderThenBuilder(super.scenario);

  TestOrderThenTerminal shouldSucceed() {
    final next = registerAssertion((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.success, isTrue);
    }, description: 'should succeed',);
    return TestOrderThenTerminal(next);
  }

  TestOrderAssertionBuilder order() {
    return TestOrderAssertionBuilder(scenario);
  }
}

class TestOrderThenTerminal {
  TestOrderThenTerminal(this.scenario);
  final ScenarioBuilder<ReadyToRun> scenario;

  TestOrderAndThenBuilder get and => TestOrderAndThenBuilder(scenario);
  void run() => ScenarioRunner.run(scenario);
}

class TestOrderAndThenBuilder extends AndThenBuilder {
  TestOrderAndThenBuilder(super.scenario);

  TestOrderAssertionBuilder order() {
    return TestOrderAssertionBuilder(scenario);
  }
}

class TestOrderAssertionBuilder extends AssertionBuilder {
  TestOrderAssertionBuilder(super.scenario);

  TestOrderAssertionBuilder hasBasePrice(double expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.basePrice, equals(expected));
    });
    return this;
  }

  TestOrderAssertionBuilder hasQuantity(int expected) {
    addAssertionStep((ctx) {
      final order = ctx.get<Order>('order');
      expect(order.quantity, equals(expected));
    });
    return this;
  }

  TestOrderAndThenBuilder get and => TestOrderAndThenBuilder(currentScenario);
  void run() => ScenarioRunner.run(currentScenario);
}

// -- Tests --

void main() {
  group('Typed Fluent DSL Integration', () {
    test(
        'full chain: given.product().withX().when.placeOrder().withX().then.shouldSucceed()',
        () async {
      // Build the scenario using typed fluent DSL
      final terminal = TestOrderScenario('should calculate base price')
          .given
          .product()
          .withName('Widget')
          .withUnitPrice(20.00)
          .when
          .placeOrder()
          .withQuantity(5)
          .then
          .shouldSucceed();

      // Execute directly (without registering a test) for validation
      await ScenarioRunner.execute(terminal.scenario);
    });

    test('full chain with assertion builder: .then.order().hasBasePrice()',
        () async {
      final assertionBuilder =
          TestOrderScenario('should have correct base price')
              .given
              .product()
              .withUnitPrice(20.00)
              .when
              .placeOrder()
              .withQuantity(5)
              .then
              .order()
              .hasBasePrice(100.00)
              .hasQuantity(5);

      await ScenarioRunner.execute(assertionBuilder.currentScenario);
    });

    test('chain with .and for additional assertions', () async {
      final terminal =
          TestOrderScenario('should succeed and have correct price')
              .given
              .product()
              .withUnitPrice(20.00)
              .when
              .placeOrder()
              .withQuantity(5)
              .then
              .shouldSucceed();

      final assertionBuilder =
          terminal.and.order().hasBasePrice(100.00).hasQuantity(5);

      await ScenarioRunner.execute(assertionBuilder.currentScenario);
    });

    test('context flows from given through when to then', () async {
      final scenario = ScenarioBuilder.create('context flow test')
          .addStep<NeedsWhen>(StepRecord(
            phase: StepPhase.given,
            action: (ctx) =>
                ctx.set('product', Product(name: 'Test', unitPrice: 10.00)),
          ),)
          .addStep<NeedsThen>(StepRecord(
            phase: StepPhase.when,
            action: (ctx) {
              final product = ctx.get<Product>('product');
              ctx.set(
                'order',
                Order(
                  quantity: 3,
                  basePrice: product.unitPrice * 3,
                  success: true,
                ),
              );
            },
          ),)
          .addStep<ReadyToRun>(StepRecord(
            phase: StepPhase.then,
            action: (ctx) {
              final order = ctx.get<Order>('order');
              expect(order.basePrice, 30.00);
            },
          ),);

      await ScenarioRunner.execute(scenario);
    });

    // COMPILE-TIME SAFETY DOCUMENTATION:
    // The following lines would NOT compile, demonstrating type safety:
    //
    // 1. Cannot call .when before .given:
    //    TestOrderScenario('bad').when  // ERROR: no 'when' on FeatureScenario
    //
    // 2. Cannot call .then before .when:
    //    TestOrderScenario('bad').given.product().then
    //    // ERROR: no 'then' on ProductGivenBuilder (only .when and .and)
    //
    // 3. Cannot call .run() before .then:
    //    TestOrderScenario('bad').given.product().withUnitPrice(20).run()
    //    // ERROR: no 'run' on ProductGivenBuilder
    //
    // 4. IDE shows only valid methods at each point:
    //    After .given  -> product()               (domain objects)
    //    After .withX  -> .withY(), .when, .and   (more config or transition)
    //    After .when   -> placeOrder()            (use cases)
    //    After .then   -> shouldSucceed(), order() (assertions)
    //    After .hasX   -> .hasY(), .and, .run()   (more assertions or finish)
  });
}
