import 'package:adaptive_stream_demo/adaptive_stream.dart';
import 'package:test/test.dart';

class FakeControls implements RtmpControls {
  final List<String> calls = [];

  @override
  void setVideoBitrate(int b) => calls.add('bitrate:$b');
  @override
  void setFps(int f) => calls.add('fps:$f');
  @override
  void setResolution(int h) => calls.add('height:$h');
}

void main() {
  late FakeControls controls;
  late AdaptiveStreamController c;

  setUp(() {
    controls = FakeControls();
    c = AdaptiveStreamController(controls, maxQueueDepth: 100, recoverAfter: 3);
  });

  test('starts at HD and changes nothing while the queue is fine', () {
    c.adjustBitrate(10);
    c.adjustBitrate(100); // exactly at the limit is not over it
    expect(c.current, StreamProfile.hd);
    expect(controls.calls, isEmpty);
  });

  test('queue over the limit drops to 200 kbps, 15 fps, 360p', () {
    c.adjustBitrate(101);
    expect(c.current, StreamProfile.sd);
    expect(controls.calls, ['bitrate:${200 * 1024}', 'fps:15', 'height:360']);
  });

  test('staying over the limit does not re-apply the same settings', () {
    c.adjustBitrate(500);
    c.adjustBitrate(600);
    c.adjustBitrate(700);
    expect(controls.calls.length, 3); // one drop only (3 setter calls)
  });

  test('recovers to HD only after several healthy checks in a row', () {
    c.adjustBitrate(500); // drop
    controls.calls.clear();

    c.adjustBitrate(10);
    c.adjustBitrate(10);
    expect(c.current, StreamProfile.sd, reason: 'not enough healthy checks yet');
    c.adjustBitrate(10);
    expect(c.current, StreamProfile.hd);
    expect(controls.calls, ['bitrate:${800 * 1024}', 'fps:30', 'height:720']);
  });

  test('a bad check in the middle resets the recovery count', () {
    c.adjustBitrate(500);
    c.adjustBitrate(10);
    c.adjustBitrate(10);
    c.adjustBitrate(300); // still over the limit: restart counting
    c.adjustBitrate(10);
    c.adjustBitrate(10);
    expect(c.current, StreamProfile.sd);
    c.adjustBitrate(10);
    expect(c.current, StreamProfile.hd);
  });

  test('queue between the two thresholds neither drops nor recovers (no flapping)', () {
    c.adjustBitrate(500);
    for (var i = 0; i < 10; i++) {
      c.adjustBitrate(70); // above recover (50), below max (100)
    }
    expect(c.current, StreamProfile.sd);
  });
}
