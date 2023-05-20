import 'dart:math';

import 'package:digit_recognition/utils/perceptron_config.dart';

class Perceptron {
  /// [_convergenceStep] - The convergence step, is selected manually by the developer.
  /// In most cases the following values are used: 0.1, 0.01, 0.001;
  /// ----------------------------------------------------------------------------------------------
  /// [_convergenceStep] - Шаг сходимости, подбирается самостоятельно, вручную самим разработчиком.
  /// В самом простом случае используют следующие значения: 0.1, 0.01, 0.001;
  static const double _convergenceStep = 0.1;

  /// [_outputFittingCriterion] - The fit criterion for the output. If the output value of the
  /// neuron is less than this value then such an output cannot be considered correct;
  /// ----------------------------------------------------------------------------------------------
  /// [_outputFittingCriterion] - Критерий согласия выхода. Если значение выхода нейрона меньше
  /// этого значения то такой выход не может считаться корректным;
  static const double _outputFittingCriterion = 0.9;

  /// [_minLocalGradient] - The minimum value of the local gradient. Sometimes a local gradient is
  /// very small, making weights difficult to adjust, so we use this variable;
  /// ----------------------------------------------------------------------------------------------
  /// [_minLocalGradient] - Минимальное значение локального градиента. Иногда локальный градиент
  /// принимает очень маленькие значение, из-за чего веса практически не корректируются, поэтому мы
  /// используем эту переменную;
  static const double _minLocalGradient = 0.05;

  static final Random random = Random();

  final PerceptronConfig _config;

  String get configString => _config.toString();

  /// For [alphabet] check out [PerceptronConfig.alphabet];
  /// ----------------------------------------------------------------------------------------------
  /// О [alphabet] читайте в [PerceptronConfig.alphabet];
  List<String> get alphabet => _config.alphabet;

  /// For [weights] check out [PerceptronConfig.weights];
  /// ----------------------------------------------------------------------------------------------
  /// О [weights] читайте в [PerceptronConfig.weights];
  List<List<double>> get weights => _config.weights;

  /// For [errorsInStatsPeriod] check out [PerceptronConfig.errorsInStatsPeriod];
  /// ----------------------------------------------------------------------------------------------
  /// О [errorsInStatsPeriod] читайте в [PerceptronConfig.errorsInStatsPeriod];
  List<int> get errorsInStatsPeriod => _config.errorsInStatsPeriod;

  /// For [weightsNormalized] check out [PerceptronConfig.weightsNormalized];
  /// ----------------------------------------------------------------------------------------------
  /// О [weightsNormalized] читайте в [PerceptronConfig.weightsNormalized];
  int get weightsNormalized => _config.weightsNormalized;

  /// For [teachingIterations] check out [PerceptronConfig.teachingIterations];
  /// ----------------------------------------------------------------------------------------------
  /// О [teachingIterations] читайте в [PerceptronConfig.trainingIterations];
  int get teachingIterations => _config.trainingIterations;

  /// For [outputsCount] check out [PerceptronConfig.outputsCount];
  /// ----------------------------------------------------------------------------------------------
  /// О [outputsCount] читайте в [PerceptronConfig.outputsCount];
  int get outputsCount => _config.outputsCount;

  /// For [statsPeriod] check out [PerceptronConfig.statsPeriod];
  /// ----------------------------------------------------------------------------------------------
  /// О [statsPeriod] читайте в [PerceptronConfig.statsPeriod];
  int get statsPeriod => _config.statsPeriod;

  /// For [inputsCount] check out [PerceptronConfig.inputsCount];
  /// ----------------------------------------------------------------------------------------------
  /// О [inputsCount] читайте в [PerceptronConfig.inputsCount];
  int get inputsCount => _config.inputsCount;

  Perceptron({required PerceptronConfig config}) : _config = config;

  int processInput(List<double> input, int? correctIndex) {
    /// Getting the values of each output neuron;
    /// --------------------------------------------------------------------------------------------
    /// Получаем значения на выходе каждого выходного нейрона;
    final outputNeurons = _getOutputNeuronsValues(input);

    /// Neuron with max output - response received from perceptron;
    /// --------------------------------------------------------------------------------------------
    /// Нейрон с максимальным выходом - ответ, полученный от персептрона;
    final maxOutput = outputNeurons.reduce(max);

    /// Since each output neuron corresponds to an element of the alphabet, then [outputIndex]
    /// corresponds to the index of the actual result in the alphabet;
    /// --------------------------------------------------------------------------------------------
    /// Так как каждый выходной нейрон соответствует элементу алфавита, то [outputIndex]
    /// соответствует индексу фактического результата в алфавите;
    final outputIndex = outputNeurons.indexOf(maxOutput);

    /// [correctIndex != null] in case the network is learning, i.e. correct perceptron's output is
    /// predefined;
    /// --------------------------------------------------------------------------------------------
    /// [correctIndex != null] в случае, если происходит обучение сети, то есть корректный выход
    /// персептрона предопределён;
    if (correctIndex != null) {
      _config.trainingIterations++;

      if (teachingIterations % statsPeriod == 1) {
        /// Adding a new error counter each time in the beginning of a new period;
        /// ----------------------------------------------------------------------------------------
        /// Добавляем новый счётчик ошибок каждый раз в начале нового периода;
        _config.errorsInStatsPeriod.add(0);
      }
      final outputNeuronCorrect = outputNeurons[correctIndex];

      /// The weights leading to the predetermined correct output neuron must be adjusted in
      /// two cases:
      ///
      /// 1) if the actual output value is not equal to the predefined one;
      ///
      /// 2) if the actual output is correct, but the output value of the actually correct neuron is
      /// less than [_outputFittingCriterion];
      /// ------------------------------------------------------------------------------------------
      /// Веса, ведущие к предопределённо верному выходному нейрону, должны быть скорректированы в
      /// двух случаях:
      ///
      /// 1) если фактическое значение на выходе не равно предопределённому;
      ///
      /// 2) если фактический выход верен, но значение на выходе фактически верного нейрона меньше
      /// [_outputFittingCriterion];
      final correctOutputWeightsShouldBeCorrected = outputIndex != correctIndex ||
          (outputIndex == correctIndex && maxOutput < _outputFittingCriterion);

      final outputsNoCorrect = List.from(outputNeurons)..remove(outputNeuronCorrect);

      /// Weights leading to other output neurons should be adjusted in
      /// two cases:
      ///
      /// 1) if the actual output value is not equal to the predefined one;
      ///
      /// 2) if at least one of these output neurons has an output value greater than
      /// [_outputFittingCriterion];
      /// ------------------------------------------------------------------------------------------
      /// Веса, ведущие к другим выходным нейронам, должны быть скорректированы в
      /// двух случаях:
      ///
      /// 1) если фактическое значение на выходе не равно предопределённому;
      ///
      /// 2) если хоть у одного из этих выходных нейронов значение на выходе больше
      /// [_outputFittingCriterion];
      final otherOutputsWeightsShouldBeCorrected = outputIndex != correctIndex ||
          outputsNoCorrect.any((element) => element > _outputFittingCriterion);

      if (correctOutputWeightsShouldBeCorrected) {
        /// Adjusting weights leading to a predetermined correct output neuron;
        /// ----------------------------------------------------------------------------------------
        /// Корректировка весов, ведущих к предопределённо верному выходному нейрону;
        final errorCorrect = 1 - outputNeuronCorrect;

        /// The gradient is equal to the product of the error and the derivative of the activation
        /// function. Since we use the logistic function: f'(x) = f(x)*(1 - f(x));
        /// ----------------------------------------------------------------------------------------
        /// Градиент равен произведению ошибки на производную от функции активации. Так как мы
        /// используем логистическую функцию: f'(x) = f(x)*(1 - f(x));
        final localGradientCorrect =
            max(errorCorrect * outputNeuronCorrect * (1 - outputNeuronCorrect), _minLocalGradient);

        for (var i = 0; i < inputsCount; i++) {
          weights[correctIndex][i] =
              weights[correctIndex][i] - _convergenceStep * localGradientCorrect * input[i];
        }
      }

      if (otherOutputsWeightsShouldBeCorrected) {
        /// Adjust weights leading to other output neurons;
        /// ----------------------------------------------------------------------------------------
        /// Корректировка весов, ведущих к другим выходным нейронам;
        for (var i = 0; i < outputNeurons.length; i++) {
          if ((i == outputIndex && outputIndex != correctIndex) ||
              (i != correctIndex && outputNeurons[i] > _outputFittingCriterion)) {
            final outputNeuron = outputNeurons[i];

            final errorOutput = 0 - outputNeuron;

            /// The gradient is equal to the product of the error and the derivative of the
            /// activation function. Since we use the logistic function: f'(x) = f(x)*(1 - f(x));
            /// ------------------------------------------------------------------------------------
            /// Градиент равен произведению ошибки на производную от функции активации. Так как мы
            /// используем логистическую функцию: f'(x) = f(x)*(1 - f(x));
            final localGradientOutput =
                min(errorOutput * outputNeuron * (1 - outputNeuron), -_minLocalGradient);

            for (var j = 0; j < inputsCount; j++) {
              weights[i][j] = weights[i][j] - _convergenceStep * localGradientOutput * input[j];
            }
          }
        }
      }

      if (correctOutputWeightsShouldBeCorrected || otherOutputsWeightsShouldBeCorrected) {
        _config.errorsInStatsPeriod.last++;
        _config.weightsNormalized++;

        /// After adjusting the weights, we can't be sure that the perceptron will correctly process
        /// the current input value, so it makes sense to recursively call [processInput] and adjust
        /// the weights again. The recursive calls will continue until the perceptron correctly
        /// processes the current input value;
        ///
        /// The recursive call can be removed, but then it will take more time to train the network;
        /// ----------------------------------------------------------------------------------------
        /// После корректировки весов не факт, что персептрон правильно обработает текущее входное
        /// значение, поэтому есть смысл рекурсивно вызвать метод обработки и ещё раз
        /// откорректировать веса. Рекурсивные вызовы продолжатся, пока персептрон не сможет
        /// правильно обработать текущее входное значение;
        ///
        /// Рекурсивный вызов вполне можно убрать, но тогда для обучения сети понадобится больше
        /// времени;
        processInput(input, correctIndex);
      }
    }

    /// Returning a negative index in case when the output value of the neuron is less than
    /// [_outputFittingCriterion];
    /// --------------------------------------------------------------------------------------------
    /// Возвращаем отрицательный индекс в случае, когда значение на выходе нейрона меньше
    /// [_outputFittingCriterion];
    return maxOutput >= _outputFittingCriterion ? outputIndex : -outputIndex;
  }

  List<double> _getOutputNeuronsValues(List<double> input) {
    final outputNeurons = <double>[];

    for (var i = 0; i < outputsCount; i++) {
      var sum = 0.0;
      for (var j = 0; j < inputsCount; j++) {
        sum += weights[i][j] * input[j];
      }
      outputNeurons.add(_getActivationFuncValue(sum));
    }
    return outputNeurons;
  }

  /// The neuron itself is an adder of input signals, which then passes the sum through a function
  /// called an activation function. The output value of this function is the output neuron value;
  ///
  /// In this case, we use the logistic function;
  /// ----------------------------------------------------------------------------------------------
  /// Сам по себе нейрон – это сумматор входных сигналов, который, затем, пропускает сумму через
  /// функцию, называемую функцией активации. Выходное значение этой функции и есть выходное
  /// значение нейрона;
  ///
  /// В данном случае мы используем логистическую функцию;
  double _getActivationFuncValue(double x) => 1 / (1 + exp(x));
}
