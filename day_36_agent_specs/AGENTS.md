# AGENTS.md: contract for AI coding agents

Copy this into the root of your Flutter project and edit the parts in brackets.
Agents that read project rules (Claude Code, Cursor, Codex and others) will follow it far more reliably than a longer prompt.

## Project context

- App: [name and one-line purpose]
- Flutter: [version]. Dart: [version]. State management: BLoC.
- Layers: `presentation` (widgets, blocs) -> `domain` (entities, repository contracts) -> `data` (repository implementations, API clients).

## Hard boundaries (never break these)

- Widgets MUST NOT call HTTP clients or databases directly.
- State changes MUST go through a BLoC. No business logic in widgets.
- `domain` MUST NOT import Flutter, HTTP packages or any `data` code.
- `data` implements `domain` contracts. It is never imported by `presentation`.
- Every new feature MUST ship with at least one unit test.
- Never add or change dependencies in `pubspec.yaml` without asking.
- Never commit secrets, keystores or API keys.

## Where things go

| What | Where |
|---|---|
| Screens and widgets | `lib/features/<name>/presentation/` |
| Blocs, events, states | `lib/features/<name>/presentation/bloc/` |
| Entities and repository contracts | `lib/features/<name>/domain/` |
| API clients and repository implementations | `lib/features/<name>/data/` |
| Tests | `test/` mirroring `lib/` |

## Definition of done (run these before saying you are finished)

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart run tool/check_boundaries.dart
```

Report the actual output. If a command was not run, say so. Do not claim success without it.

## How to work

1. Read the existing feature closest to the one you are building and copy its structure.
2. Make the smallest change that satisfies the request.
3. If a rule above blocks the request, stop and ask instead of working around it.
