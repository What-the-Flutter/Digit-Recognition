import 'dart:math';
import 'dart:typed_data';

import 'package:digit_recognition/presentation/pages/stats_page.dart';
import 'package:digit_recognition/presentation/text_styles.dart';
import 'package:digit_recognition/presentation/widgets/input_recognizer.dart';
import 'package:digit_recognition/presentation/widgets/weights_display.dart';
import 'package:digit_recognition/utils/files.dart';
import 'package:digit_recognition/utils/perceptron.dart';
import 'package:digit_recognition/utils/perceptron_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img_;

class MyHomePage extends StatefulWidget {
  static const int imageSize = 24;
  final PerceptronConfig config;

  const MyHomePage({required this.config, super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final Random _random = Random();
  late final Perceptron _perceptron = Perceptron(config: widget.config);
  late final List<String> _alphabet = widget.config.alphabet;

  Uint8List? _imageData;
  int? _result;
  bool _resultIsCorrect = true;

  late int _randomNumber = _random.nextInt(_alphabet.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Weights normalized: ${_perceptron.weightsNormalized} times',
                  style: style20.copyWith(color: Colors.blue),
                ),
                Text(
                  'Draw to teach: ${_alphabet[_randomNumber]}',
                  style: style25.copyWith(color: Colors.orangeAccent),
                ),
                InputRecognizer(
                  onTeach: (GlobalKey<State<StatefulWidget>> key) async {
                    _result = null;
                    final data = await _processImage(key);
                    _result = _perceptron.processInput(data, _randomNumber);
                    _resultIsCorrect = _result == _randomNumber;
                    _updateRandomNumber();
                  },
                  onDetermine: (GlobalKey<State<StatefulWidget>> key) async {
                    _result = null;
                    final data = await _processImage(key);
                    setState(() {
                      _result = _perceptron.processInput(data, null);
                      _resultIsCorrect = !_result!.isNegative;
                    });
                  },
                ),
                Container(
                  height: 100.0,
                  width: 100.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                  ),
                  child: _imageData == null
                      ? null
                      : Image.memory(
                          _imageData!,
                          fit: BoxFit.contain,
                        ),
                ),
                SizedBox(
                  height: 70.0,
                  child: _result == null
                      ? null
                      : Text(
                          'Result is ${_result!.isNegative ? 'undefined (probably ${_alphabet[-_result!]})' : _alphabet[_result!]}',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: style30.copyWith(
                            color: _resultIsCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Files.exportConfig(_perceptron.configString),
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
                      child: const Text('Export config'),
                    ),
                    ElevatedButton(
                      onPressed: _showStats,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.green),
                      ),
                      child: const Text('Show stats'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          WeightsDisplay(
            imageSize: MyHomePage.imageSize,
            perceptron: _perceptron,
          ),
        ],
      ),
    );
  }

  void _showStats() async {
    if (_perceptron.errorsInStatsPeriod.length > StatsPage.maxScale) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatsPage(
            statsPeriod: _perceptron.statsPeriod,
            data: _perceptron.errorsInStatsPeriod
                .sublist(0, _perceptron.errorsInStatsPeriod.length - 1)
                .map((errors) => (_perceptron.statsPeriod - errors).toDouble())
                .toList(),
          ),
        ),
      );
    }
  }

  void _updateRandomNumber() {
    setState(() => _randomNumber = _random.nextInt(_alphabet.length));
  }

  Future<List<double>> _processImage(GlobalKey key) async {
    setState(() => _imageData = null);
    final render = key.currentContext!.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
    final datax = await Files.processImage(render!, MyHomePage.imageSize);

    setState(() => _imageData = img_.encodePng(datax));

    final data = datax.buffer.asUint8List();
    final input = <double>[];

    for (var i = 0; i < MyHomePage.imageSize; i++) {
      for (var j = 0; j < MyHomePage.imageSize; j++) {
        final point = (data[(i * MyHomePage.imageSize + j) * 4 + 3] - 128) / 255;
        input.add(point);
      }
    }

    await Files.removeImagesAfterProcessing();
    return input;
  }
}
