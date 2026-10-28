# 045 — Integer money and category resolver primitives

**Priority:** P1 · **Effort:** M · **Status:** PHASE 1 DONE

## Changes

- `core/domain/money.dart`: exact `Money` value type in minor units with COP/USD parsing (`1.234,56` / `1,234.56`), decimal-string wire output, arithmetic, comparisons, and legacy JSON bridging.
- `features/categories/domain/services/category_resolver.dart`: case-insensitive active-name lookup for writes/imports, id→name resolution for display (including archived/deleted), and a stable grouping key.
- Full unit coverage for parsing, formatting, arithmetic, JSON shapes, and resolver fallbacks.

## Remaining phases

The specs (`SPEC-money-minor-units.md`, `SPEC-category-ids.md`) define the
entity/sync migrations. They stay separate, feature-by-feature increments so
each one keeps the gates green.
