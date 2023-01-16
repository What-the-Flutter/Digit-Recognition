import 'package:flutter/material.dart';
import 'package:digit_recognition/logic/perceptron_simple.dart';

class WeightsDisplay extends StatelessWidget {
  final int imageSize;
  final Perceptron perceptron;

  const WeightsDisplay({required this.imageSize, required this.perceptron, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      height: double.infinity,
      color: Colors.black26,
      child: CustomPaint(
        painter: WeightsPainter(
          imageSize: imageSize,
          perceptron: perceptron,
        ),
      ),
    );
  }
}

class WeightsPainter extends CustomPainter {
  static const double scale = 2.0;

  final int imageSize;
  final Perceptron perceptron;

  WeightsPainter({
    required this.imageSize,
    required this.perceptron,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final horizontalOffset = (size.width - imageSize * scale) / 2;

    for (int k = 0; k < perceptron.weights.length; k++) {
      final verticalOffset = (imageSize * scale + horizontalOffset) * k;
      for (int i = 0; i < imageSize; i++) {
        for (int j = 0; j < imageSize; j++) {
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
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeightsPainter oldDelegate) => true;
}
