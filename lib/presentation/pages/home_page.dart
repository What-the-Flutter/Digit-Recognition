import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:digit_recognition/presentation/widgets/weights_display.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img_;
import 'package:digit_recognition/logic/perceptron_simple.dart';
import 'package:digit_recognition/presentation/widgets/input_recognizer.dart';
import 'package:digit_recognition/presentation/pages/stats_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int _imageSize = 24;
  static final Random _random = Random();

  final Perceptron _perceptron = Perceptron(inputsCount: _imageSize * _imageSize);
  Uint8List? _imageData;
  int? _result;

  int _randomNumber = _random.nextInt(100) % 10;

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
                  style: const TextStyle(fontSize: 20, color: Colors.lightBlueAccent),
                ),
                Text(
                  'Draw to teach: $_randomNumber',
                  style: const TextStyle(fontSize: 25, color: Colors.orangeAccent),
                ),
                InputRecognizer(
                  onTeach: (GlobalKey<State<StatefulWidget>> key) async {
                    _result = null;
                    final data = await _processImage(key);
                    _result = _perceptron.processInput(data, _randomNumber);
                    _updateRandomNumber();
                  },
                  onDetermine: (GlobalKey<State<StatefulWidget>> key) async {
                    _result = null;
                    final data = await _processImage(key);
                    setState(() => _result = _perceptron.processInput(data, null));
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
                  height: 30.0,
                  child: _result == null
                      ? null
                      : Text(
                          'Result is $_result',
                          style: const TextStyle(fontSize: 30, color: Colors.green),
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _exportWeights,
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.orange)),
                      child: const Text('Export weights'),
                    ),
                    ElevatedButton(
                      onPressed: _importWeights,
                      style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                      child: const Text('Import weights'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _showStats,
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.lightGreenAccent)),
                  child: const Text('Show stats', style: TextStyle(color: Colors.black38)),
                ),
              ],
            ),
          ),
          WeightsDisplay(
            imageSize: _imageSize,
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

  void _importWeights() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      _perceptron.config = await file.readAsString();
    }
  }

  void _exportWeights() async {
    if (await Permission.storage.request().isGranted) {
      String dir = '${(await getExternalStorageDirectory())!.path}/weights.txt';
      File file = File(dir);
      await file.writeAsString(_perceptron.config);
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            bytes: file.readAsBytesSync(),
            length: await file.length(),
          ),
        ],
      );
    }
  }

  void _updateRandomNumber() {
    setState(() => _randomNumber = _random.nextInt(100) % 10);
  }

  Future<List<double>> _processImage(GlobalKey key) async {
    setState(() => _imageData = null);
    final render = key.currentContext!.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
    final img = await render!.toImage();

    final directory = (await getTemporaryDirectory()).path;
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    final imgFile = File('$directory/temp.png');
    await imgFile.writeAsBytes(pngBytes!);

    final image = img_.decodeImage(imgFile.readAsBytesSync());
    final resizedImage = img_.copyResize(image!, width: _imageSize, height: _imageSize);

    final newFile = File('$directory/temp-compressed.png');
    newFile.writeAsBytesSync(img_.encodePng(resizedImage));
    setState(() => _imageData = newFile.readAsBytesSync());

    final data = resizedImage.buffer.asUint8List();
    final input = <double>[];

    for (int i = 0; i < _imageSize; i++) {
      final str = <String>[];
      for (int j = 0; j < _imageSize; j++) {
        final point = data[(i * _imageSize + j) * 4 + 3] / 255;
        input.add(point);
        str.add(point == 0.0
            ? '\x1b[34m${point.toStringAsFixed(2)}\x1b[0m'
            : '\x1b[33m${point.toStringAsFixed(2)}\x1b[0m');
      }
    }

    await imgFile.delete();
    await newFile.delete();

    return input;
  }
}
