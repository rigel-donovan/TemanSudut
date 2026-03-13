import 'package:flutter/material.dart';

enum PopupType { success, error, warning, info }

class PopupNotification {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    PopupType type = PopupType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry entry;

      entry = OverlayEntry(
        builder: (context) => _PopupOverlay(
          title: title,
          message: message,
          type: type,
          onDismiss: () {
            entry.remove();
          },
          duration: duration,
        ),
      );

      overlay.insert(entry);
    } catch (_) {
      debugPrint('PopupNotification: context no longer active, skipping.');
    }
  }
}

class _PopupOverlay extends StatefulWidget {
  final String title;
  final String message;
  final PopupType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _PopupOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto hide after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case PopupType.success:
        return Icons.check_circle_rounded;
      case PopupType.error:
        return Icons.error_rounded;
      case PopupType.warning:
        return Icons.warning_rounded;
      case PopupType.info:
        return Icons.info_rounded;
    }
  }

  List<Color> _getGradient() {
    switch (widget.type) {
      case PopupType.success:
        return [Color(0xFF00C853), Color(0xFF00E676)];
      case PopupType.error:
        return [Color(0xFFD50000), Color(0xFFFF1744)];
      case PopupType.warning:
        return [Color(0xFFFF6D00), Color(0xFFFFAB00)];
      case PopupType.info:
        return [Color(0xFF2962FF), Color(0xFF448AFF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradient(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getGradient()[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIcon(), color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.reverse().then((_) => widget.onDismiss());
                      },
                      child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
