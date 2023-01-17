import 'dart:math';

import 'package:digit_recognition/logic/perceptron_config.dart';
import 'package:flutter/cupertino.dart';

class Perceptron {
  static const double convergenceStep = 0.1;
  static const double errorBorder = 0.9;
  static const double minLocalGradient = 0.05;

  static final Random random = Random();

  PerceptronConfig _config;

  List<String> get alphabet => _config.alphabet;

  List<List<double>> get weights => _config.weights;

  List<int> get errorsInStatsPeriod => _config.errorsInStatsPeriod;

  int get weightsNormalized => _config.weightsNormalized;

  int get teachingIterations => _config.teachingIterations;

  int get outputsCount => _config.outputsCount;

  int get statsPeriod => _config.statsPeriod;

  int get inputsCount => _config.inputsCount;

  Perceptron({required PerceptronConfig config}) : _config = config;

  int processInput(List<double> input, int? correctIndex) {
    final outputNeurons = _getOutputNeuronsValues(input);

    final maxOutput = outputNeurons.reduce(max);
    final outputIndex = outputNeurons.indexOf(maxOutput);

    //debugPrint('\x1b[32mmaxOutput $maxOutput \x1b[0m');
    // debugPrint('\x1b[32moutputNeurons $outputNeurons \x1b[0m');

    if (correctIndex != null) {
      //printOutput(outputNeurons, correctIndex);
    }

    if (correctIndex != null) {
      _config.teachingIterations++;

      if (teachingIterations % statsPeriod == 1) {
        _config.errorsInStatsPeriod.add(0);
        //debugPrint('\x1b[34m $errorsInStatsPeriod \x1b[0m');
      }
      final outputNeuronCorrect = outputNeurons[correctIndex];

      final correctOutputWeightsShouldBeCorrected =
          outputIndex != correctIndex || (outputIndex == correctIndex && maxOutput < errorBorder);

      final outputsNoCorrect = List.from(outputNeurons)..remove(outputNeuronCorrect);
      final otherOutputsWeightsShouldBeCorrected =
          outputsNoCorrect.any((element) => element > errorBorder) || outputIndex != correctIndex;

      if (correctOutputWeightsShouldBeCorrected) {
        //debugPrint('\x1b[35m correctOutputWeightsShouldBeCorrected true \x1b[0m');
        final errorCorrect = 1 - outputNeuronCorrect;
        //debugPrint('\x1b[35m errorCorrect $errorCorrect \x1b[0m');

        /// Updating weights between inputs and correct outputIndex
        final localGradientCorrect =
            max(errorCorrect * outputNeuronCorrect * (1 - outputNeuronCorrect), minLocalGradient);
        //debugPrint('\x1b[35m localGradientCorrect $localGradientCorrect \x1b[0m');

        for (int i = 0; i < inputsCount; i++) {
          weights[correctIndex][i] =
              weights[correctIndex][i] - convergenceStep * localGradientCorrect * input[i];
        }
      }

      if (otherOutputsWeightsShouldBeCorrected) {
        //debugPrint('\x1b[35m otherOutputsWeightsShouldBeCorrected true \x1b[0m');
        for (int i = 0; i < outputNeurons.length; i++) {
          if ((i == outputIndex && outputIndex != correctIndex) ||
              (i != correctIndex && outputNeurons[i] > errorBorder)) {
            final outputNeuron = outputNeurons[i];
            //print('\x1b[32m outputNeuron $outputNeuron \x1b[0m');
            /// Updating weights between inputs and real (incorrect) outputIndex
            final localGradientOutput =
                -max(outputNeuron * outputNeuron * (1 - outputNeuron), minLocalGradient);
            //print('\x1b[33m localGradientOutput $localGradientOutput \x1b[0m');
            // debugPrint(
            //   '\x1b[35m convergenceStep * localGradientOutput = ${convergenceStep * localGradientOutput} \x1b[0m',
            // );

            for (int j = 0; j < inputsCount; j++) {
              weights[i][j] = weights[i][j] - convergenceStep * localGradientOutput * input[j];
            }
          }
        }
      }

      if (correctOutputWeightsShouldBeCorrected || otherOutputsWeightsShouldBeCorrected) {
        _config.errorsInStatsPeriod.last++;

        //debugPrint('\x1b[34m AFTER WEIGHTS UPDATE: \x1b[0m');
        //printOutput(_getOutputNeuronsValues(input), correctIndex);
        _config.weightsNormalized++;
        processInput(input, correctIndex);
      }
    }

    return maxOutput >= errorBorder ? outputIndex : -outputIndex;
  }

  void printOutput(List<double> outputNeurons, int correct) {
    debugPrint(
        '\x1b[34m ================== CORRECT IS ${_config.alphabet[correct]} ================== \x1b[0m');
    final maxValue = outputNeurons.reduce(max);
    for (int i = 0; i < outputsCount; i++) {
      debugPrint(
        '${outputNeurons[i] == maxValue ? '\x1b[31m' : '\x1b[33m'}  ${_config.alphabet[i]} - '
        '${(outputNeurons[i] * 100).toInt()}% \x1b[0m',
      );
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

  double _getActivationFuncValue(double x) => 1 / (1 + exp(x));

  String get config => _config.toString();

  set config(String value) => _config = PerceptronConfig.fromString(value);
}
