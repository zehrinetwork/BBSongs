import 'package:flutter/material.dart';

class EqualizerAnimation extends StatefulWidget {
  final bool isPaused;

  const EqualizerAnimation({super.key, this.isPaused = false});

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bar1;
  late Animation<double> _bar2;
  late Animation<double> _bar3;

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
  }

  void _initializeAnimations() {
    _bar1 = Tween<double>(begin: 6, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _bar2 = Tween<double>(begin: 10, end: 28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _bar3 = Tween<double>(begin: 7, end: 24).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }


  @override
  void didUpdateWidget(EqualizerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.isPaused ? 0.4 : 1.0,
      child: SizedBox(
        width: 24,
        height: 24,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBar(_bar1.value),
                _buildBar(_bar2.value),
                _buildBar(_bar3.value),
              ],
            );
          },
        ),
      ),
    );
  }
}
