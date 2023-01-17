import 'dart:convert';

class PerceptronConfig {
  final List<String> alphabet;

  /// [weightsNormalized] - Amount of weight normalizing iterations that where made;
  /// ----------------------------------------------------------------------------------------------
  /// [weightsNormalized] - Количество раз, когда проводился процесс нормализации весов;#
  int weightsNormalized;

  /// [trainingIterations] - Amount of train method ([Perceptron.processInput] with null [correct]
  /// parameter) calls;
  /// ----------------------------------------------------------------------------------------------
  /// [trainingIterations] - Количество вызовов метода обучения сети ([Perceptron.processInput] с
  /// null значением параметра [correct]);
  int trainingIterations = 0;

  /// [statsPeriod] - Period for collecting statistics;
  /// ----------------------------------------------------------------------------------------------
  /// [statsPeriod] - Период для сбора статистики;
  int statsPeriod;

  /// [inputsCount] - Size of the input data array, for a 24x24 image this value = 576;
  /// ----------------------------------------------------------------------------------------------
  /// [inputsCount] - Размерность входного массива данных, для изображения 24х24 это значение = 576;
  int inputsCount;

  /// [outputsCount] - Number of output neurons;
  /// ----------------------------------------------------------------------------------------------
  /// [outputsCount] - Количество выходных нейронов;
  int outputsCount;

  /// [weights] - An array of weights between each input element and each output neuron;
  /// If the input is an array of 10 elements and the output is 10 neurons, [weights] will contain
  /// 100 elements;
  /// ----------------------------------------------------------------------------------------------
  /// [weights] - Массив весов между каждым входным элементом и каждым выходным нейроном;
  /// Если на входе массив из 10 элементов а на выходе 10 нейронов [weights] будет содержать 100
  /// значений;
  List<List<double>> weights;

  /// [errorsInStatsPeriod] - Array of error statistics during the training process;
  /// If [statsPeriod] is equal to k, then the elements in [errorsInStatsPeriod] can take values
  /// from 0 up to k, where 0 means that the perceptron made no errors in the selected period,
  /// and k means that all perceptron's responses were not correct;
  /// ----------------------------------------------------------------------------------------------
  /// [errorsInStatsPeriod] - Массив статистики ошибок в процессе обучения;
  /// Если [statsPeriod] равен k, то элементы в [errorsInStatsPeriod] могут принимать значения от 0
  /// до k, где 0 означает, что в выбранном периоде персептрон не совершил ошибок, а k - что все
  /// ответы персептрона были не верны;
  List<int> errorsInStatsPeriod;

  PerceptronConfig({
    required this.alphabet,
    required this.weights,
    required this.errorsInStatsPeriod,
    required this.inputsCount,
    required this.outputsCount,
    this.weightsNormalized = 0,
    this.trainingIterations = 0,
    this.statsPeriod = 25,
  });

  factory PerceptronConfig.fromString(String value) {
    final arrays = jsonDecode(value) as List<dynamic>;
    return PerceptronConfig(
      weightsNormalized: arrays[0] as int,
      trainingIterations: arrays[1] as int,
      outputsCount: arrays[2] as int,
      statsPeriod: arrays[3] as int,
      inputsCount: arrays[4] as int,
      alphabet: (arrays[5] as List<dynamic>).map((e) => e as String).toList(),
      weights: (arrays[6] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as double).toList())
          .toList(),
      errorsInStatsPeriod: (arrays[7] as List<dynamic>).map((e) => e as int).toList(),
    );
  }

  @override
  String toString() {
    return jsonEncode([
      weightsNormalized,
      trainingIterations,
      outputsCount,
      statsPeriod,
      inputsCount,
      alphabet,
      weights,
      errorsInStatsPeriod,
    ]);
  }
}
