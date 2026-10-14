# flutter-demo-snippets

Small, generic demos that go with the posts on [@_letsbuildapps](https://www.instagram.com/_letsbuildapps/).
Each folder is self-contained, has its own README, and contains only the part that matters for the post.
Find yours at [haffshah.github.io/portfolio/resources.html](https://haffshah.github.io/portfolio/resources.html).

Licensed under the [MIT License](LICENSE). These are written for learning and review. They are **not** copies of any production or client app,
contain no keys or credentials, and carry no warranty. Check them against the current docs for your SDK versions.

| Folder | Instagram post | What it is |
|---|---|---|
| [`day_01_math_solver`](day_01_math_solver) | [On-device math solving](https://www.instagram.com/p/DcJMd8fDEKm/) | Symbolic solver (arithmetic, linear, quadratic) with an LLM fallback router, 9 tests |
| [`day_02_chat_battery`](day_02_chat_battery) | [Why real-time chats drain battery](https://www.instagram.com/p/DcLuXtPDGB6/) | Adaptive WebSocket heartbeat and reconnect backoff with jitter, 10 tests |
| [`day_03_map_markers`](day_03_map_markers) | [Render 10,000+ map markers without lag](https://www.instagram.com/p/DcNmeaamXWp/) | Grid clustering in a background isolate, 10% padded viewport, one-pass canvas painter, 9 tests |
| [`day_06_offline_geofence`](day_06_offline_geofence) | [Offline geofence safety alerts](https://www.instagram.com/p/DcVYUIcjLbC/) | Ray casting, GeoJSON zones and enter/exit events, 7 tests |
| [`day_07_low_end_matching`](day_07_low_end_matching) | [Face matching on weak hardware](https://www.instagram.com/reel/DcXolElmbMu/) | Reusable frame buffers, cosine matching and Isolate offload (stand-in embedding, no ML model), 13 tests |
| [`day_17_local_router`](day_17_local_router) | [Stop paying OpenAI: on-device first](https://www.instagram.com/p/DcxKtWymW6b/) | Route simple AI tasks to a local model and complex ones to the cloud, 8 tests |
| [`day_24_thermal_print`](day_24_thermal_print) | [Bluetooth thermal printing](https://www.instagram.com/p/DdEli7wDJQm/) | ESC/POS bytes, safe column padding, 20-byte chunked writes, 10 tests |
| [`day_25_ocr_preprocess`](day_25_ocr_preprocess) | [Perspective correction and receipt parsing before OCR](https://www.instagram.com/reel/DdF-zuvjGck/) | Homography warp of a skewed card plus a receipt text parser, 11 tests |
| [`day_26_background_gps`](day_26_background_gps) | [Background GPS battery optimization](https://www.instagram.com/p/DdIqc9pDMHs/) | Speed-based polling policy and batched location uploads, 7 tests |
| [`day_27_binarization`](day_27_binarization) | [Adaptive binarization for scans](https://www.instagram.com/reel/DdLBm05DMMZ/) | Adaptive thresholding to 1-bit plus bit packing, 7 tests |
| [`day_30_comparison_matrix`](day_30_comparison_matrix) | [Mobile-first comparison matrix](https://www.instagram.com/p/DdSv86lDKlU/) | Pinned header, fixed labels and synced scrolling, 6 tests |
| [`day_31_pos_sync`](day_31_pos_sync) | [Offline POS sync engine](https://www.instagram.com/reel/DdVN5aKDDPF/) | Append-only SQLite ledger replayed in order, 6 tests |
| [`day_32_adaptive_stream`](day_32_adaptive_stream) | [Adaptive RTMP streaming](https://www.instagram.com/p/DdYAW6EGf7m/) | Drop video quality when the send queue backs up, then recover, 6 tests |
| [`day_36_agent_specs`](day_36_agent_specs) | [Give your AI coding agent a contract](https://www.instagram.com/reel/Ddh7nQljHkK/) | `AGENTS.md` template plus a boundary checker script, with tests |
| [`day_40_offline_sync`](day_40_offline_sync) | [Offline-first doesn't mean always offline](https://www.instagram.com/p/DdsSI5pDONB/) | Drift outbox, retries, idempotency keys, conflict strategies, 8 tests |
| [`day_42_pigeon`](day_42_pigeon) | [MethodChannel vs Pigeon](https://www.instagram.com/reel/Ddwylb4jGOp/) | Schema, generated Dart/Swift/Kotlin, Dart tests |
| [`day_45_cicd`](day_45_cicd) | [Flutter CI/CD: git tag to store](https://www.instagram.com/p/Dd5RDzmjLzo/) | GitHub Actions workflow + Fastlane lane (template, not run against a store account) |
| [`day_47_mason_brick`](day_47_mason_brick) | [Stop copy-pasting feature folders](https://www.instagram.com/reel/Dd-TvcmDBwd/) | Mason brick for a clean-architecture feature with BLoC and a test |
| [`day_49_uiscene_fix`](day_49_uiscene_fix) | [Fix the Flutter iOS startup crash (UIScene)](https://www.instagram.com/reel/DeDx7-KDJwP/) | Info.plist + AppDelegate migration, and an AI prompt |
| [`day_53_hybrid_scanner`](day_53_hybrid_scanner) | [Scanner pipeline: local parse + AI fusion](https://www.instagram.com/p/DeQVVaHjMmX/) | Runnable Dart demo with tests (no Flutter needed) |
| [`day_54_sliver_ui`](day_54_sliver_ui) | [App screens carousel](https://www.instagram.com/p/DeOFKPAGXB2/) | Pinned app bar + pinned search header + list, as a runnable Flutter example |
