import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = 'Memproses...'}) {
    if (_entry != null) return; // prevent duplicate overlays
    _entry = OverlayEntry(
      builder: (ctx) => _LoadingOverlayWidget(message: message),
    );
    Overlay.of(context).insert(_entry!);
  }

  static void hide(BuildContext context) {
    _entry?.remove();
    _entry = null;
  }
}

class _LoadingOverlayWidget extends StatelessWidget {
  final String message;
  const _LoadingOverlayWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
