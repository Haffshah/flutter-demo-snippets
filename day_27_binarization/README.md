# Adaptive binarization: gray page to 1-bit

A photo of a page is mostly shades of gray, with uneven light and shadows. Turning it into pure black and white has two parts: deciding which pixels are ink, then storing 1 bit per pixel instead of 8.

| File | What it does |
|---|---|
| [`lib/binarize.dart`](lib/binarize.dart) | `globalThreshold`, `adaptiveThreshold` (integral image, Bradley/Roth style) and `packBits` |
| [`test/binarize_test.dart`](test/binarize_test.dart) | 7 tests, including a shadowed-page case |

```bash
dart pub get
dart test
```

## Why adaptive

A single cutoff (`globalThreshold`) treats a shadowed part of the page as ink (in the test page, none of the paper in the shadowed right edge stays white). `adaptiveThreshold` compares each pixel with the average of the area around it, so paper stays white even in shadow and ink stays black even where the page is bright. The first two tests build a synthetic page that fades from bright to shadowed and show both outcomes.

## Bit packing

`packBits` stores 1 bit per pixel, so the packed pixel data is 1/8 the size of the 8-bit gray data it came from (rows are padded to whole bytes). That is only the pixel data. The size of a finished file depends on the format you save it in.

## What is NOT here

- **No PDF export, no camera, no ML Kit, no OCR.** This is the thresholding step only. The Reel talks about PDFs and a size reduction, but no file-size result is claimed here: it depends on the image, the format and the compressor, so measure it on your own scans.
- **Input is an 8-bit grayscale buffer.** Convert from RGB first, and load images with the package of your choice.
- `windowSize` (15) and `sensitivity` (0.15) are starting values. Tune them for your documents.
- It is pure Dart, so it will be slow on large photos on a phone. For production, run it in an isolate or use a native or GPU implementation.
