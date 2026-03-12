import 'package:flutter/material.dart';

class SlideToFinish extends StatefulWidget {
  final VoidCallback onSlideSuccess;
  final String text;
  final bool isEnabled;

  const SlideToFinish({
    Key? key,
    required this.onSlideSuccess,
    this.text = 'Slide to Finish Order',
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<SlideToFinish> createState() => _SlideToFinishState();
}

class _SlideToFinishState extends State<SlideToFinish> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isSuccess = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double handleSize = 56.0;
        final double maxDrag = maxWidth - handleSize;

        return Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: Container(
            height: handleSize,
            width: maxWidth,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(handleSize / 2),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                // Background Text
                Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                if (_isSuccess)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(handleSize / 2),
                    ),
                  ),

                // Slidable Handle
                Positioned(
                  left: _dragValue * maxDrag,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (!widget.isEnabled || _isSuccess) return;
                      setState(() {
                        _dragValue += details.delta.dx / maxDrag;
                        _dragValue = _dragValue.clamp(0.0, 1.0);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (!widget.isEnabled || _isSuccess) return;
                      if (_dragValue > 0.8) {
                        setState(() {
                          _dragValue = 1.0;
                          _isSuccess = true;
                        });
                        widget.onSlideSuccess();
                        
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            setState(() {
                              _dragValue = 0.0;
                              _isSuccess = false;
                            });
                          }
                        });
                      } else {
                        setState(() {
                          _dragValue = 0.0;
                        });
                        _animationController.forward(from: 0.0);
                      }
                    },
                    child: Container(
                      width: handleSize,
                      height: handleSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
