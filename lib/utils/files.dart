import 'dart:io';
import 'dart:ui' as ui;

import 'package:digit_recognition/utils/perceptron_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img_;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';


abstract class Files {
  static Future<PerceptronConfig?> importConfig() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      try {
        final config = PerceptronConfig.fromString(await file.readAsString());
        return config;
      } catch (error) {
        debugPrint('\x1b[31m$error\x1b[0m');
      }
    }
    return null;
  }

  static void exportConfig(String configString) async {
    if (await Permission.storage.request().isGranted) {
      final dir = '${(await getExternalStorageDirectory())!.path}/config.txt';
      final file = File(dir);
      await file.writeAsString(configString);
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

  static Future<img_.Image> processImage(RenderRepaintBoundary render, int imageSize) async {
    final img = await render.toImage();

    final directory = (await getTemporaryDirectory()).path;
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    final imgFile = File('$directory/temp.png');
    await imgFile.writeAsBytes(pngBytes!);

    final image = img_.decodeImage(imgFile.readAsBytesSync());
    final resizedImage = img_.copyResize(image!, width: imageSize, height: imageSize);

    final newFile = File('$directory/temp-compressed.png');
    newFile.writeAsBytesSync(img_.encodePng(resizedImage));
    return resizedImage;
  }

  static Future<void> removeImagesAfterProcessing() async {
    final directory = (await getTemporaryDirectory()).path;
    final imgFile = File('$directory/temp.png');
    await imgFile.delete();
    final newFile = File('$directory/temp-compressed.png');
    await newFile.delete();
  }
}
