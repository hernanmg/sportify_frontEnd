import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/board_stroke.dart';

/// Capa de dibujo sobre la cancha (coordenadas normalizadas 0–1).
class FieldDrawingOverlay extends StatefulWidget {
  final List<BoardStroke> strokes;
  final bool drawEnabled;
  final Color penColor;
  final double penWidth;
  final ValueChanged<List<BoardStroke>> onStrokesChanged;

  const FieldDrawingOverlay({
    super.key,
    required this.strokes,
    required this.drawEnabled,
    required this.onStrokesChanged,
    this.penColor = Colors.white,
    this.penWidth = 2.5,
  });

  @override
  State<FieldDrawingOverlay> createState() => _FieldDrawingOverlayState();
}

class _FieldDrawingOverlayState extends State<FieldDrawingOverlay> {
  List<Offset>? _current;

  void _notify(List<BoardStroke> next) => widget.onStrokesChanged(next);

  Offset? _normalize(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > box.size.width ||
        local.dy > box.size.height) {
      return null;
    }
    return Offset(
      (local.dx / box.size.width).clamp(0.0, 1.0),
      (local.dy / box.size.height).clamp(0.0, 1.0),
    );
  }

  void _onPanStart(DragStartDetails d, RenderBox box) {
    if (!widget.drawEnabled) return;
    final p = _normalize(d.globalPosition, box);
    if (p == null) return;
    setState(() => _current = [p]);
  }

  void _onPanUpdate(DragUpdateDetails d, RenderBox box) {
    if (!widget.drawEnabled || _current == null) return;
    final p = _normalize(d.globalPosition, box);
    if (p == null) return;
    setState(() => _current = [..._current!, p]);
  }

  void _onPanEnd() {
    if (_current == null || _current!.length < 2) {
      setState(() => _current = null);
      return;
    }
    final hex =
        '#${widget.penColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final stroke = BoardStroke(
      points: List.from(_current!),
      color: hex,
      width: widget.penWidth,
    );
    setState(() => _current = null);
    _notify([...widget.strokes, stroke]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: widget.drawEnabled
              ? (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) _onPanStart(d, box);
                }
              : null,
          onPanUpdate: widget.drawEnabled
              ? (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) _onPanUpdate(d, box);
                }
              : null,
          onPanEnd: widget.drawEnabled ? (_) => _onPanEnd() : null,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _StrokesPainter(
              strokes: widget.strokes,
              current: _current,
              currentColor: widget.penColor,
              currentWidth: widget.penWidth,
            ),
          ),
        );
      },
    );
  }
}

class _StrokesPainter extends CustomPainter {
  final List<BoardStroke> strokes;
  final List<Offset>? current;
  final Color currentColor;
  final double currentWidth;

  _StrokesPainter({
    required this.strokes,
    this.current,
    required this.currentColor,
    required this.currentWidth,
  });

  Color _parseColor(String hex, Color fallback) {
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) {
      final v = int.tryParse('FF$h', radix: 16);
      if (v != null) return Color(v);
    }
    if (h.length == 8) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return Color(v);
    }
    return fallback;
  }

  void _drawStroke(Canvas canvas, Size size, BoardStroke s) {
    if (s.points.length < 2) return;
    final paint = Paint()
      ..color = _parseColor(s.color, Colors.white)
      ..strokeWidth = s.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = s.points.first;
    path.moveTo(first.dx * size.width, first.dy * size.height);
    for (var i = 1; i < s.points.length; i++) {
      final p = s.points[i];
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _drawStroke(canvas, size, s);
    }
    if (current != null && current!.length >= 2) {
      _drawStroke(
        canvas,
        size,
        BoardStroke(
          points: current!,
          color: '#FFFFFFFF',
          width: currentWidth,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) =>
      old.strokes != strokes || old.current != current;
}
