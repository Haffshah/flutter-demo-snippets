# Bluetooth thermal printing: ESC/POS, column padding, chunked writes

Three small pieces from the carousel, as plain Dart you can test without a printer.

| File | What it does |
|---|---|
| [`lib/escpos.dart`](lib/escpos.dart) | The ESC/POS commands from the slide (`initializePrinter`, `alignCenter`, `charSizeDouble`), `padRow`, and a `ReceiptBuilder` |
| [`lib/chunked_writer.dart`](lib/chunked_writer.dart) | Splits bytes into 20-byte chunks and writes them with a 10 ms pause between chunks |
| [`test/thermal_print_test.dart`](test/thermal_print_test.dart) | 10 tests |

```bash
dart pub get
dart test
```

## Using the writer

```dart
final writer = ChunkedWriter((chunk) => myBluetoothPlugin.write(chunk));
await writer.send(ReceiptBuilder().title('MY SHOP').row('ITEM A', r'$42.00').build());
```

`write` is whatever your Bluetooth plugin uses to send bytes. The 20-byte size and 10 ms pause are the values from the carousel. **Tune them for your printer.** Some printers accept bigger chunks.

## One fix to the slide's code

The slide's `padRow` does `' ' * (32 - left.length - right.length)`. In Dart a negative repeat count throws, so a long item name would crash the receipt. `padRow` here keeps a space and shortens the left text.

## What is NOT here

- **Charset handling.** The carousel mentions non-ASCII characters printing as garbage. Fixing that needs printer code pages, which depends on your printer model. Here, non-ASCII characters are simply replaced with `?`.
- **Bluetooth itself.** No plugin is included, and nothing here was run on a real printer.
- `alignLeft`, `charSizeNormal` and `lineFeed` are standard ESC/POS commands I added to undo the centering and double size. They weren't on the slide.
