import 'package:flutter/material.dart';
import 'dart:async';

class UnreadBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color color;

  const UnreadBadge({
    super.key,
    required this.count,
    required this.child,
    this.color = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -7,
          top: -7,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AsyncUnreadBadge extends StatefulWidget {
  final Future<int> Function() loadCount;
  final Widget child;
  final Duration refreshInterval;

  const AsyncUnreadBadge({
    super.key,
    required this.loadCount,
    required this.child,
    this.refreshInterval = const Duration(seconds: 15),
  });

  @override
  State<AsyncUnreadBadge> createState() => _AsyncUnreadBadgeState();
}

class _AsyncUnreadBadgeState extends State<AsyncUnreadBadge> {
  Timer? _timer;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _load());
  }

  @override
  void didUpdateWidget(covariant AsyncUnreadBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.loadCount != widget.loadCount) {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final count = await widget.loadCount();

    if (!mounted) {
      return;
    }

    if (count != _count) {
      setState(() {
        _count = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnreadBadge(count: _count, child: widget.child);
  }
}
