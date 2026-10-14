# AGENTS.md contract for AI coding agents

An agent does not need a longer prompt. It needs a contract it can read, and a check it must pass.

| File | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Template: project context, hard boundaries, where things go, definition of done |
| [`tool/check_boundaries.dart`](tool/check_boundaries.dart) | Script that fails when a widget imports HTTP or `data` code, or `domain` imports Flutter |
| [`test/check_boundaries_test.dart`](test/check_boundaries_test.dart) | Tests for that script |

## Use it

1. Copy `AGENTS.md` to your project root and fill in the brackets. Many agents pick it up automatically.
2. Copy `tool/check_boundaries.dart` into your project. Run `dart run tool/check_boundaries.dart`.
3. Make "definition of done" part of the agent loop: it must run format, analyze, tests and the boundary check, and show the real output.

## Run the demo's own tests

```bash
dart pub get
dart test
```

## Limits

- The checker is a simple import scan. It only knows the folder names `presentation`, `domain` and `data`, and it treats `dart:io` as HTTP/IO. Adjust the lists to your project.
- It cannot prove an agent followed every rule. It catches one class of mistakes cheaply, and your review catches the rest.
