import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedSearchPlaceholder extends StatefulWidget {
  final List<String> texts;
  final TextStyle style;

  const AnimatedSearchPlaceholder({
    super.key,
    required this.texts,
    required this.style,
  });

  @override
  State<AnimatedSearchPlaceholder> createState() => _AnimatedSearchPlaceholderState();
}

class _AnimatedSearchPlaceholderState extends State<AnimatedSearchPlaceholder> {
  int _currentStringIndex = 0;
  String _currentText = "";
  int _charIndex = 0;
  bool _isTyping = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) return;

      final targetString = widget.texts[_currentStringIndex];

      setState(() {
        if (_isTyping) {
          if (_charIndex < targetString.length) {
            _charIndex++;
            _currentText = targetString.substring(0, _charIndex);
          } else {
            _isTyping = false;
            _timer?.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _startAnimation(); // Restart to backspace
              }
            });
          }
        } else {
          // Backspacing is slightly faster
          if (_charIndex > 0) {
            _charIndex--;
            _currentText = targetString.substring(0, _charIndex);
          } else {
            _isTyping = true;
            _currentStringIndex = (_currentStringIndex + 1) % widget.texts.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_currentText, style: widget.style),
        _BlinkingCursor(style: widget.style),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final TextStyle style;
  const _BlinkingCursor({required this.style});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('|', style: widget.style),
    );
  }
}
