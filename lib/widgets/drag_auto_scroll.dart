import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps a scrollable [child] and auto-scrolls it when a drag hovers
/// within [edgeSize] pixels of the top or bottom edge.
///
/// Works by overlaying two thin [DragTarget<Object>] zones that reject all
/// drops (so actual DragTargets beneath remain unaffected) but fire
/// [onMove] while a draggable is hovering, which drives a periodic scroll
/// timer.
class DragAutoScrollView extends StatefulWidget {
  const DragAutoScrollView({
    super.key,
    required this.controller,
    required this.child,
    this.edgeSize = 80.0,
    this.scrollSpeed = 6.0,
  });

  final ScrollController controller;
  final Widget child;

  /// Height of the top/bottom trigger zones in logical pixels.
  final double edgeSize;

  /// Pixels scrolled per 16 ms frame while hovering in a zone.
  final double scrollSpeed;

  @override
  State<DragAutoScrollView> createState() => _DragAutoScrollViewState();
}

class _DragAutoScrollViewState extends State<DragAutoScrollView> {
  Timer? _timer;
  double _direction = 0; // -1 = up, +1 = down, 0 = stopped

  void _startScroll(double direction) {
    if (_direction == direction) return;
    _direction = direction;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final sc = widget.controller;
      if (!sc.hasClients) return;
      final next = (sc.offset + _direction * widget.scrollSpeed)
          .clamp(sc.position.minScrollExtent, sc.position.maxScrollExtent);
      sc.jumpTo(next);
    });
  }

  void _stopScroll() {
    if (_direction == 0) return;
    _direction = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _zone({required double direction}) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (_) => false,
      onMove: (_) => _startScroll(direction),
      onLeave: (_) => _stopScroll(),
      builder: (_, __, ___) => const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.edgeSize,
          child: _zone(direction: -1),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: widget.edgeSize,
          child: _zone(direction: 1),
        ),
      ],
    );
  }
}
