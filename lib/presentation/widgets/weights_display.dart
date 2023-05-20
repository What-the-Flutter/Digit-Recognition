import 'package:digit_recognition/utils/perceptron.dart';
import 'package:flutter/material.dart';

class WeightsDisplay extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(vertical: 30.0);
  static const double _width = 100.0;

  final int imageSize;
  final Perceptron perceptron;

  const WeightsDisplay({required this.imageSize, required this.perceptron, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: MediaQuery.of(context).viewPadding,
      color: Colors.black26,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          width: _width,
          height: perceptron.outputsCount * (_width + imageSize * WeightsPainter.scale) / 2 +
              _padding.vertical,
          padding: _padding,
          child: CustomPaint(
            painter: WeightsPainter(
              imageSize: imageSize,
              perceptron: perceptron,
              weightsNormalized: perceptron.weightsNormalized,
            ),
          ),
        ),
      ),
    );
  }
}

class WeightsPainter extends CustomPainter {
  static const double scale = 2.0;

  final int imageSize;
  final Perceptron perceptron;
  final int weightsNormalized;

  WeightsPainter({
    required this.imageSize,
    required this.perceptron,
    required this.weightsNormalized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final horizontalOffset = (size.width - imageSize * scale) / 2;

    for (var k = 0; k < perceptron.outputsCount; k++) {
      final verticalOffset = (imageSize * scale + horizontalOffset) * k;
      for (var i = 0; i < imageSize; i++) {
        for (var j = 0; j < imageSize; j++) {
          final opacity = ((perceptron.weights[k][i * 24 + j]) * 255).toInt();
          canvas.drawRect(
            Rect.fromLTWH(
              horizontalOffset + scale * i.toDouble(),
              verticalOffset + scale * j.toDouble(),
              scale,
              scale,
            ),
            paint
              ..color = opacity.isNegative
                  ? Color.fromARGB(-opacity, 0, 0, 255)
                  : Color.fromARGB(opacity, 255, 0, 0),
          );

          final span = TextSpan(text: perceptron.alphabet[k]);
          final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
          tp.layout();
          tp.paint(canvas, Offset(horizontalOffset - 14, verticalOffset - 14));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeightsPainter oldDelegate) =>
      weightsNormalized != oldDelegate.weightsNormalized;
}
