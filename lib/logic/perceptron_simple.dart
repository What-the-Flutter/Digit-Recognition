import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';

class Perceptron {
  static const double convergenceStep = 0.1;
  static final Random random = Random();

  PerceptronConfig _config;

  List<List<double>> get weights => _config.weights;

  List<int> get errorsInStatsPeriod => _config.errorsInStatsPeriod;

  int get weightsNormalized => _config.weightsNormalized;

  int get teachingIterations => _config.teachingIterations;

  int get outputsCount => _config.outputsCount;

  int get statsPeriod => _config.statsPeriod;

  int get inputsCount => _config.inputsCount;

  Perceptron({required int inputsCount, int outputsCount = 10})
      :

        /// For every output neuron we initialize a list of weights coming from every input with
        /// values [-0.5, 0.5];
        _config = PerceptronConfig(
          inputsCount: inputsCount,
          weights: List.generate(
            outputsCount,
            (_) => List.generate(inputsCount, (_) => random.nextDouble() - 0.5),
          ),
          errorsInStatsPeriod: List.empty(growable: true),
        );

  int processInput(List<double> input, int? correct) {
    final outputNeurons = _getOutputNeuronsValues(input);

    final output = outputNeurons.indexOf(outputNeurons.reduce(max));

    //printOutput(outputNeurons, correct);

    if (correct != null) {
      _config.teachingIterations++;

      if (teachingIterations % statsPeriod == 1) {
        _config.errorsInStatsPeriod.add(0);
        debugPrint('\x1b[34m $errorsInStatsPeriod \x1b[0m');
      }

      if (output != correct) {
        _config.errorsInStatsPeriod.last++;

        final errorCorrect = 1 - outputNeurons[correct];
        final errorOutput = 0 - outputNeurons[output];

        /// Updating weights between inputs and correct output
        final localGradientCorrect =
            errorCorrect * outputNeurons[correct] * (1 - outputNeurons[correct]);
        for (int i = 0; i < inputsCount; i++) {
          weights[correct][i] =
              weights[correct][i] - convergenceStep * localGradientCorrect * input[i];
        }

        /// Updating weights between inputs and real (incorrect) output
        final localGradientOutput =
            errorOutput * outputNeurons[output] * (1 - outputNeurons[output]);
        for (int i = 0; i < inputsCount; i++) {
          weights[output][i] =
              weights[output][i] - convergenceStep * localGradientOutput * input[i];
        }

        //print('\x1b[34m AFTER WEIGHTS UPDATE: \x1b[0m');
        //printOutput(_getOutputNeuronsValues(input), correct);

        _config.weightsNormalized++;
        //return processInput(input, correct);
      }
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

  List<double> _getOutputNeuronsValues(List<double> input) {
    final List<double> outputNeurons = [];

    for (int i = 0; i < outputsCount; i++) {
      double sum = 0.0;
      for (int j = 0; j < inputsCount; j++) {
        sum += weights[i][j] * input[j];
      }
      outputNeurons.add(_getActivationFuncValue(sum));
    }
    //print('\x1b[36m outputNeurons $outputNeurons \x1b[0m');
    return outputNeurons;
  }

  double _getActivationFuncValue(double x) => 0.5 / (1 + exp(x));

  String get config => _config.toString();

  set config(String value) => _config = PerceptronConfig.fromString(value);
}

class PerceptronConfig {
  /// [weightsNormalized] represents weight normalizing iterations that where made;
  int weightsNormalized;

  /// [teachingIterations] represents how many times train method ([processInput] with null
  /// [correct] parameter) was called;
  int teachingIterations = 0;

  int outputsCount;
  int statsPeriod;
  int inputsCount;

  List<List<double>> weights;

  List<int> errorsInStatsPeriod;

  PerceptronConfig({
    required this.weights,
    required this.errorsInStatsPeriod,
    required this.inputsCount,
    this.weightsNormalized = 0,
    this.teachingIterations = 0,
    this.outputsCount = 10,
    this.statsPeriod = 25,
  });

  factory PerceptronConfig.fromString(String value) {
    final arrays = jsonDecode(value) as List<dynamic>;

    return PerceptronConfig(
      weightsNormalized: arrays[0] as int,
      teachingIterations: arrays[1] as int,
      outputsCount: arrays[2] as int,
      statsPeriod: arrays[3] as int,
      inputsCount: arrays[4] as int,
      weights: (arrays[5] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
          .toList(),
      errorsInStatsPeriod: (arrays[6] as List<dynamic>).map((e) => e as int).toList(),
    );
  }

  @override
  String toString() {
    return jsonEncode([
      weightsNormalized,
      teachingIterations,
      outputsCount,
      statsPeriod,
      inputsCount,
      weights,
      errorsInStatsPeriod,
    ]);
  }
}
