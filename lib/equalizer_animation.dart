import 'package:flutter/material.dart';

class EqualizerAnimation extends StatefulWidget {
  const EqualizerAnimation({super.key});

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bar1, _bar2, _bar3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..repeat(reverse: true);

    _bar1 = Tween<double>(begin: 10, end: 25).animate(_controller);
    _bar2 = Tween<double>(begin: 5, end: 30).animate(_controller);
    _bar3 = Tween<double>(begin: 15, end: 20).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBar(height: _bar1),
        const SizedBox(width: 2),
        AnimatedBar(height: _bar2),
        const SizedBox(width: 2),
        AnimatedBar(height: _bar3),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedBar extends AnimatedWidget {
  const AnimatedBar({super.key, required Animation<double> height}) : super(listenable: height);
  Animation<double> get height => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height.value,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
