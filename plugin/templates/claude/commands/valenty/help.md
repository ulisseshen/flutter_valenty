---
name: valenty:help
description: Show available Valenty commands and quick reference
---

Output the following reference. Do NOT add project-specific analysis or suggestions.

# Valenty Command Reference

**Valenty** — AI-powered testing for Flutter apps using the Modern Test Pyramid.

- **Component tests** validate what users see and do (`valentyTest`)
- **Unit tests** cover business rules and edge cases (`typedParameterizedTest`)

## Commands

| Command | Purpose |
|---------|---------|
| `/valenty:init` | Setup project: add valenty_test, scan features, generate first tests |
| `/valenty:test` | Write component tests (user scenarios) or unit tests (edge cases) |
| `/valenty:review` | Review test quality with 4 parallel agents |
| `/valenty:help` | This reference |

## Quick Start

```
/valenty:init
```

## Test Types

**Component test** — test what users see:
```dart
valentyTest('shows error when payment fails', ...);
```

**Unit test** — cover business rules:
```dart
typedParameterizedTest('calculates discount', [
  DiscountCase(price: 100, rate: 0.10, expected: 90),
], (c) => expect(applyDiscount(c.price, c.rate), equals(c.expected)));
```

## Credits

Built on the [Modern Test Pyramid](https://journal.optivem.com/p/modern-test-pyramid) by [Valentina Jemuovic](https://www.linkedin.com/in/valentinajemuovic/).

## Update

```bash
npx valenty-tester@latest
```
