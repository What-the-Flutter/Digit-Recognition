import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class InputRecognizer extends StatefulWidget {
  final Future<void> Function(GlobalKey key) onDetermine;
  final Future<void> Function(GlobalKey key) onTeach;

  const InputRecognizer({required this.onDetermine, required this.onTeach, super.key});

  @override
  State<InputRecognizer> createState() => _InputRecognizerState();
}

class _InputRecognizerState extends State<InputRecognizer> {
  final GlobalKey _key = GlobalKey();

  bool _teachingProcess = false;
  List<Path> _paths = [];
  double? _minXLocalPosition;
  double? _minYLocalPosition;
  double? _maxXLocalPosition;
  double? _maxYLocalPosition;

  @override
  Widget build(BuildContext context) {
    final size = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) * 0.5;
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onPanStart: (details) => onPanStart(details, size),
              onPanUpdate: (details) => onPanUpdate(details, size),
              child: Container(
                height: size,
                width: size,
                clipBehavior: Clip.hardEdge,
                decoration:
                    BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black)),
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: _key,
                    painter: SketchPainter(paths: _paths),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _clearCanvas,
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => _determine(size),
                    child: const Text('Determine', style: TextStyle(color: Colors.green)),
                  ),
                  TextButton(
                    onPressed: () => _teach(size),
                    child: const Text('Teach', style: TextStyle(color: Colors.orangeAccent)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_teachingProcess)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: Text('TEACHING...'),
              ),
            ),
          ),
      ],
    );
  }

  void _teach(double size) {
    if (_paths.isNotEmpty) {
      _teachingProcess = true;
      _refactorImage(size);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await widget.onTeach(_key);
          _teachingProcess = false;
          _clearCanvas();
        },
      );
    }
  }

  void _determine(double size) {
    if (_paths.isNotEmpty) {
      _refactorImage(size);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onDetermine(_key).whenComplete(_clearCanvas),
      );
    }
  }

  void _refactorImage(double size) {
    final newPaths = <Path>[];
    final xScale =
        size / (_maxXLocalPosition! - _minXLocalPosition! + 2 * size * SketchPainter.strokeFactor);
    final yScale =
        size / (_maxYLocalPosition! - _minYLocalPosition! + 2 * size * SketchPainter.strokeFactor);

    // xScale, 0, 0, 0,
    // 0, yScale, 0, 0,
    // 0, 0, 1, 0,
    // xOffset * xScale, yOffset * yScale, 0, 1,

    final transformMatrix = Float64List.fromList([
      xScale,
      0,
      0,
      0,
      0,
      yScale,
      0,
      0,
      0,
      0,
      1,
      0,
      (-_minXLocalPosition! + size * SketchPainter.strokeFactor / 2) * xScale,
      (-_minYLocalPosition! + size * SketchPainter.strokeFactor / 2) * yScale,
      0,
      1,
    ]);

    for (var path in _paths) {
      newPaths.add(path.transform(transformMatrix));
    }
    setState(() => _paths = newPaths);
  }

  void _clearCanvas() {
    _paths.clear();
    setState(() {
      _minXLocalPosition = null;
      _minYLocalPosition = null;
      _maxXLocalPosition = null;
      _maxYLocalPosition = null;
    });
  }

  void _setLocalPositions(double dx, double dy, double canvasSize) {
    _minXLocalPosition = _minXLocalPosition == null ? dx : min(max(dx, 0.0), _minXLocalPosition!);
    _minYLocalPosition = _minYLocalPosition == null ? dy : min(max(dy, 0.0), _minYLocalPosition!);
    _maxXLocalPosition =
        _maxXLocalPosition == null ? dx : max(min(dx, canvasSize), _maxXLocalPosition!);
    _maxYLocalPosition =
        _maxYLocalPosition == null ? dy : max(min(dy, canvasSize), _maxYLocalPosition!);
  }

  void onPanStart(DragStartDetails details, double canvasSize) {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    _setLocalPositions(dx, dy, canvasSize);
    setState(
      () => _paths.add(Path()..moveTo(dx, dy)),
    );
  }

  void onPanUpdate(DragUpdateDetails details, double canvasSize) {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    _setLocalPositions(dx, dy, canvasSize);
    setState(() => _paths.last.lineTo(dx, dy));
  }
}

class SketchPainter extends CustomPainter {
  static const double strokeFactor = 0.04;
  final List<Path> paths;

  SketchPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * strokeFactor;
    for (var path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) => true;
}
