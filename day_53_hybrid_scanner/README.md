# Layered scan pipeline: local parse + AI fusion

A small, runnable Dart demo of the pipeline idea behind a coupon-screenshot scanner.
It uses fake OCR and a fake AI, so it needs **no keys, no network and no Flutter**.

```
image
  |
  0. cache hit?  ------------------------------> return cached result
  |
  1. OCR  ->  2. local parse (always runs, free)
  |
  2b. offline? --------------------------------> return local parse, AI never called
  |
  3. AI extraction  -> fuse: AI wins per field, local fills the gaps
  |
  4. fused confidence < 0.85 ? -> one high-res retry, keep the stronger result
  |
  5. AI failed or returned nothing ------------> return local parse
```

## Run it

```bash
dart pub get
dart test          # 9 tests, one per behaviour above
dart run bin/demo.dart
```

## What this shows (and what it doesn't)

- **The local parse always runs.** It is the baseline, the offline answer, and the safety net when the AI fails.
- **Fusion is per field.** The AI result wins, and local values fill only the fields the AI left empty.
- **Escalation is gated by confidence**, and capped at one retry.
- **Same image, same cost once.** A cache avoids repeating OCR and AI calls.
- The regexes and the confidence formula are **illustrative**, not the ones from a production app.
- Left out on purpose: rate limiting, credit/billing logic, image preprocessing, real OCR and real model calls.

In the original app the AI call goes through your own backend so no paid key ships in the app binary. Do the same in anything real.
