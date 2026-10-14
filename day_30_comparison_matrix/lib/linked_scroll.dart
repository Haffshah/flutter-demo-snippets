import 'package:flutter/widgets.dart';

/// Two horizontal scroll controllers that always stay at the same offset.
///
/// Slide 4 of the carousel shows the idea: `_controllerA.addListener(() => _controllerB.jumpTo(_controllerA.offset))`.
/// That moves B when A scrolls. This version works in both directions. The [_syncing] flag stops the two
/// controllers from triggering each other in a loop.
class LinkedScrollControllers {
  LinkedScrollControllers() {
    a.addListener(() => _follow(from: a, to: b));
    b.addListener(() => _follow(from: b, to: a));
  }

  final ScrollController a = ScrollController();
  final ScrollController b = ScrollController();
  bool _syncing = false;

  void _follow({required ScrollController from, required ScrollController to}) {
    if (_syncing || !from.hasClients || !to.hasClients) return;
    final target = from.offset.clamp(0.0, to.position.maxScrollExtent);
    if ((to.offset - target).abs() < 0.5) return;
    _syncing = true;
    to.jumpTo(target);
    _syncing = false;
  }

  void dispose() {
    a.dispose();
    b.dispose();
  }
}
