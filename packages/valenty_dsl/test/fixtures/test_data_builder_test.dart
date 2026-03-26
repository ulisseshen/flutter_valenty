import 'package:test/test.dart';
import 'package:valenty_dsl/src/fixtures/fixture_base.dart';
import 'package:valenty_dsl/src/fixtures/test_data_builder.dart';

class _User {
  _User({required this.name, required this.age});
  final String name;
  final int age;
}

class _UserFixture extends FixtureBase<_User> {
  @override
  _User create() => _User(name: 'Default User', age: 25);
}

class _UserBuilder extends TestDataBuilder<_User> {
  String _name = 'Default';
  int _age = 25;

  _UserBuilder withName(String name) {
    _name = name;
    return this;
  }

  _UserBuilder withAge(int age) {
    _age = age;
    return this;
  }

  @override
  _User build() => _User(name: _name, age: _age);

  @override
  void reset() {
    _name = 'Default';
    _age = 25;
  }
}

void main() {
  group('FixtureBase', () {
    late _UserFixture fixture;

    setUp(() {
      fixture = _UserFixture();
    });

    test('create returns a default instance', () {
      final user = fixture.create();
      expect(user.name, 'Default User');
      expect(user.age, 25);
    });

    test('createMany returns the requested number of instances', () {
      final users = fixture.createMany(3);
      expect(users.length, 3);
      for (final user in users) {
        expect(user.name, 'Default User');
      }
    });

    test('createMany with zero returns empty list', () {
      expect(fixture.createMany(0), isEmpty);
    });
  });

  group('TestDataBuilder', () {
    late _UserBuilder builder;

    setUp(() {
      builder = _UserBuilder();
    });

    test('build creates instance with defaults', () {
      final user = builder.build();
      expect(user.name, 'Default');
      expect(user.age, 25);
    });

    test('build creates instance with custom values', () {
      final user = builder.withName('Alice').withAge(30).build();
      expect(user.name, 'Alice');
      expect(user.age, 30);
    });

    test('reset restores default values', () {
      builder.withName('Alice').withAge(30);
      builder.reset();
      final user = builder.build();
      expect(user.name, 'Default');
      expect(user.age, 25);
    });
  });
}
