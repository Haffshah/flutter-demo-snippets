# Pigeon: type-safe Flutter to native calls

With a plain `MethodChannel` you coordinate channel and method names as strings in Dart, Swift and Kotlin.
A typo shows up at runtime as `MissingPluginException`. With Pigeon you write the API once in Dart and generate all three sides.

## The schema

[`pigeons/battery.dart`](pigeons/battery.dart) defines a `BatteryInfo` class and a `@HostApi()` called `BatteryApi`.

```bash
flutter pub get
dart run pigeon --input pigeons/battery.dart
```

Generated (and committed, so you can read them):

| File | Language |
|---|---|
| [`lib/battery_api.g.dart`](lib/battery_api.g.dart) | Dart client |
| [`ios/Classes/BatteryApi.g.swift`](ios/Classes/BatteryApi.g.swift) | Swift protocol |
| [`android/src/main/kotlin/dev/demo/BatteryApi.g.kt`](android/src/main/kotlin/dev/demo/BatteryApi.g.kt) | Kotlin interface |
| `test/test_api.g.dart` | Test helper for faking the native side |

## Use it from Dart

```dart
final level = await BatteryApi().getBatteryLevel(); // typed int, IDE autocomplete
```

[`lib/battery_service.dart`](lib/battery_service.dart) wraps it, and [`test/battery_service_test.dart`](test/battery_service_test.dart) tests that wrapper against a fake host.

```bash
flutter test
```

## Implement the native side

See [`BatteryApiImpl.swift.example`](ios/Classes/BatteryApiImpl.swift.example) and [`BatteryApiImpl.kt.example`](android/src/main/kotlin/dev/demo/BatteryApiImpl.kt.example).

## What is and isn't verified

- Verified: code generation runs, the Dart side analyzes, and the Dart tests pass.
- **Not verified:** the `.example` native files were not compiled or run on a device. They are starting points. This folder is also not a full plugin, so you will wire the registration into your own app.
- Pigeon's options and generated output change between versions. This was generated with Pigeon 22.x. Check the Pigeon docs for yours.

## When to still use MethodChannel

Pigeon fits request/response APIs with fixed shapes. For quick one-off calls or fully dynamic messages, a MethodChannel is fine. Use Pigeon when the API grows and the strings start to hurt.
