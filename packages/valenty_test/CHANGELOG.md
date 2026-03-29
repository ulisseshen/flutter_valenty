# Changelog

## 0.2.1

- Fix Flutter SDK compatibility: relax test constraint back to ^1.25.0 (was ^1.31.0 which required test_api 0.7.11, incompatible with Flutter's pinned test_api 0.7.8)

## 0.2.0

- Rewrite README for zero-friction onboarding: complete working examples, architecture guide, troubleshooting, and AI agent instructions

## 0.1.3

- Add analyzer conflict troubleshooting to README

## 0.1.2

- Fix dependency conflict with riverpod_generator by requiring test ^1.31.0 (supports analyzer <13.0.0)

## 0.1.1

- Add mandatory AI setup instructions to README
- Fix repository and homepage URLs

## 0.1.0

- Initial release
- Phantom type system for compile-time safe Given→When→Then ordering
- Builder base classes: GivenBuilder, WhenBuilder, ThenBuilder, DomainObjectBuilder, AssertionBuilder
- ScenarioRunner integration with `package:test`
- Multi-channel testing support (UI, API, CLI)
- Test fixtures and matchers
- TestContext for state management across scenario steps
