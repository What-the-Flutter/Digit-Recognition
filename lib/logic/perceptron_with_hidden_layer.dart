import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';

class PerceptronWithHiddenLayers {
  static const int outputsCount = 10;
  static const double convergenceStep = 1;
  static final Random random = Random();

  final int inputsCount;
  final int hiddenLayers;

  /// For [weights1] first index is hidden layer index, second is input index;
  List<List<double>> weights1;

  /// For [weights2] first index is output index, second is hidden layer index;
  List<List<double>> weights2;

  int iterations = 0;

  PerceptronWithHiddenLayers({required this.inputsCount, required this.hiddenLayers})
      :

        /// For every neuron from hidden layer we initialize a list of weights coming from every
        /// input with values [-0.5, 0.5];
        weights1 = List.generate(
          hiddenLayers,
          (_) => List.generate(inputsCount, (_) => random.nextDouble() - 0.5),
        ),

        /// For every output neuron we initialize a list of weights coming from every hidden layer
        /// neuron with values [-0.5, 0.5];
        weights2 = List.generate(
          outputsCount,
          (_) => List.generate(hiddenLayers, (_) => random.nextDouble() - 0.5),
        );

  int teachNetwork(List<double> input, int correct) {
    iterations++;

    final hiddenLayersNeurons = _getHiddenLayerNeuronsValues(input);

    final outputNeurons = _getOutputNeuronsValues(hiddenLayersNeurons);

    final output = outputNeurons.indexOf(outputNeurons.reduce(max));

    //printOutput(outputNeurons, correct);

    if (output != correct) {
      final errorCorrect = 1 - outputNeurons[correct];
      final errorOutput = 0 - outputNeurons[output];

      /// Updating weights between hidden neurons and correct output
      final localGradientCorrect =
          errorCorrect * outputNeurons[correct] * (1 - outputNeurons[correct]);
      for (int i = 0; i < hiddenLayers; i++) {
        weights2[correct][i] =
            weights2[correct][i] - convergenceStep * localGradientCorrect * hiddenLayersNeurons[i];
      }

      /// Updating weights between hidden neurons and real (incorrect) output
      final localGradientOutput = errorOutput * outputNeurons[output] * (1 - outputNeurons[output]);
      for (int i = 0; i < hiddenLayers; i++) {
        weights2[output][i] =
            weights2[output][i] - convergenceStep * localGradientOutput * hiddenLayersNeurons[i];
      }

      /// Updating weights between inputs and hidden neurons
      for (int i = 0; i < hiddenLayers; i++) {
        // i = hidden neuron number
        final omega =
            localGradientCorrect * weights2[correct][i] + localGradientOutput * weights2[output][i];
        final localGradient = omega * hiddenLayersNeurons[i] * (1 - hiddenLayersNeurons[i]);
        for (int j = 0; j < inputsCount; j++) {
          // j = input number
          weights1[i][j] = weights1[i][j] - convergenceStep * localGradient * input[j];
        }
      }
      //print('\x1b[34m AFTER WEIGHTS UPDATE: \x1b[0m');
      //printOutput(_getOutputNeuronsValues(_getHiddenLayerNeuronsValues(input)), correct);
      return teachNetwork(input, correct);
    }

    return output;
  }

  void printOutput(List<double> outputNeurons, int correct) {
    debugPrint('\x1b[34m ================== CORRECT IS $correct ================== \x1b[0m');
    final maxValue = outputNeurons.reduce(max);
    for (int i = 0; i < outputsCount; i++) {
      if (outputNeurons[i] == maxValue) {
        debugPrint('\x1b[31m $i - 100% \x1b[0m');
      } else {
        debugPrint('\x1b[33m $i - ${(outputNeurons[i] * 100) ~/ maxValue}% \x1b[0m');
      }
    }
    debugPrint('\x1b[35m ================================================== \x1b[0m');
  }

  List<double> _getOutputNeuronsValues(List<double> hiddenLayersNeurons) {
    final List<double> outputNeurons = [];

    for (int i = 0; i < outputsCount; i++) {
      double sum = 0.0;
      for (int j = 0; j < hiddenLayers; j++) {
        sum += weights2[i][j] * hiddenLayersNeurons[j];
      }
      outputNeurons.add(_getActivationFuncValue(sum));
    }
    //print('\x1b[36m outputNeurons $outputNeurons \x1b[0m');
    return outputNeurons;
  }

  List<double> _getHiddenLayerNeuronsValues(List<double> input) {
    final List<double> hiddenLayersNeurons = [];

    for (int i = 0; i < hiddenLayers; i++) {
      double sum = 0.0;
      for (int j = 0; j < inputsCount; j++) {
        sum += weights1[i][j] * input[j];
      }
      hiddenLayersNeurons.add(_getActivationFuncValue(sum));
    }

    return hiddenLayersNeurons;
  }

  double _getActivationFuncValue(double x) => 0.5 / (1 + exp(x));

  String get weights => jsonEncode([iterations, weights1, weights2]);

  set weights(String value) {
    final arrays = jsonDecode(value) as List<dynamic>;
    iterations = arrays[0] as int;
    weights1 = (arrays[1] as List<dynamic>)
        .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
        .toList();
    weights2 = (arrays[2] as List<dynamic>)
        .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
        .toList();
  }
}
