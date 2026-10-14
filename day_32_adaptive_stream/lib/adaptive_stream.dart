/// What your streaming plugin must let you change while live. Video only: nothing here touches audio,
/// so the audio track keeps its bandwidth when video is scaled down.
abstract class RtmpControls {
  void setVideoBitrate(int bitsPerSecond);
  void setFps(int fps);
  void setResolution(int heightPixels);
}

class StreamProfile {
  const StreamProfile({required this.name, required this.videoBitrate, required this.fps, required this.heightPixels});

  final String name;
  final int videoBitrate; // bits per second
  final int fps;
  final int heightPixels;

  /// 800 kbps (the carousel's "HD" label) and 720p. The 30 fps value is my assumption.
  static const hd = StreamProfile(name: 'HD', videoBitrate: 800 * 1024, fps: 30, heightPixels: 720);

  /// 200 kbps and 15 fps (the carousel's code) and 360p (from slide 4).
  static const sd = StreamProfile(name: 'SD', videoBitrate: 200 * 1024, fps: 15, heightPixels: 360);
}

/// The idea from slide 3: look at how much data is waiting to be sent. If the queue gets too deep the
/// network can't keep up, so lower the video quality.
///
/// The carousel's code only goes down. This version also recovers: after [recoverAfter] checks in a row
/// with a shallow queue it goes back up. Without that, one bad moment would leave the stream at low
/// quality forever.
class AdaptiveStreamController {
  AdaptiveStreamController(
    this.controls, {
    required this.maxQueueDepth,
    int? recoverQueueDepth,
    this.recoverAfter = 5,
  }) : recoverQueueDepth = recoverQueueDepth ?? maxQueueDepth ~/ 2;

  final RtmpControls controls;

  /// Above this the quality drops. The unit is whatever your plugin reports (packets, bytes, ...).
  final int maxQueueDepth;

  /// At or below this counts as "queue is healthy" for recovery.
  final int recoverQueueDepth;
  final int recoverAfter;

  StreamProfile _current = StreamProfile.hd;
  int _healthyChecks = 0;

  StreamProfile get current => _current;

  /// Call this regularly, for example once a second, with the current send-queue depth.
  void adjustBitrate(int queueDepth) {
    if (queueDepth > maxQueueDepth) {
      _healthyChecks = 0;
      if (_current != StreamProfile.sd) _apply(StreamProfile.sd);
      return;
    }
    if (queueDepth <= recoverQueueDepth && _current != StreamProfile.hd) {
      _healthyChecks++;
      if (_healthyChecks >= recoverAfter) {
        _healthyChecks = 0;
        _apply(StreamProfile.hd);
      }
    } else {
      _healthyChecks = 0; // in between: neither bad enough to drop nor healthy enough to recover
    }
  }

  void _apply(StreamProfile p) {
    controls.setVideoBitrate(p.videoBitrate);
    controls.setFps(p.fps);
    controls.setResolution(p.heightPixels);
    _current = p;
  }
}
