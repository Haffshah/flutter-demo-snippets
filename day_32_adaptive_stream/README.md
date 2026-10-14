# Adaptive RTMP quality: drop video quality when the send queue backs up

<p align="center"><a href="https://www.instagram.com/p/DdYAW6EGf7m/"><img src="docs/instagram_post.jpg" alt="Cover of the Day 32 Instagram carousel by @_letsbuildapps" width="320"></a></p>

> The original carousel on Instagram: [Day 32, @_letsbuildapps](https://www.instagram.com/p/DdYAW6EGf7m/)

On a weak or unstable connection a fixed bitrate fills the outgoing buffer, and the stream times out. The carousel's fix: watch the send-queue depth and scale the **video** down when it gets too deep.

| From the carousel | In this demo |
|---|---|
| `adjustBitrate(queueDepth)`: over the limit, set 200 kbps and 15 fps | [`lib/adaptive_stream.dart`](lib/adaptive_stream.dart) |
| Scale from 720p down to 360p | `StreamProfile.hd` and `StreamProfile.sd` |
| Protect the audio track above all | `RtmpControls` only exposes video settings, so audio is never changed |

```bash
dart pub get
dart test    # 6 tests
```

## Use it

Implement `RtmpControls` on top of your RTMP plugin, then call `adjustBitrate` about once a second with the plugin's send-queue depth:

```dart
final controller = AdaptiveStreamController(MyRtmpControls(), maxQueueDepth: 200);
Timer.periodic(const Duration(seconds: 1), (_) => controller.adjustBitrate(rtmp.queueDepth));
```

## What I added to the carousel's code

- **Recovery.** The slide's code only lowers quality. This version goes back to HD after a few healthy checks in a row, with a gap between the drop and recover thresholds so it doesn't flap.
- **A 30 fps HD value** and the `StreamProfile` structure. The slides don't give an HD frame rate.

## What is NOT here

- **No RTMP, camera or encoder.** You need a plugin whose bitrate, frame rate and resolution you can change live, and that can report queue depth. Not every plugin can.
- **No thresholds for your network.** `maxQueueDepth` has no default on purpose: its unit depends on your plugin. Tune it by testing on a poor connection.
- **No uptime, bandwidth or "zero buffer" figures.** The carousel quotes percentages. This demo doesn't measure or claim any.
