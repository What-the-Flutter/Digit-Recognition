import 'dart:convert';

class PerceptronConfig {
  final List<String> alphabet;

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
    required this.alphabet,
    required this.weights,
    required this.errorsInStatsPeriod,
    required this.inputsCount,
    required this.outputsCount,
    this.weightsNormalized = 0,
    this.teachingIterations = 0,
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
      teachingIterations,
      outputsCount,
      statsPeriod,
      inputsCount,
      alphabet,
      weights,
      errorsInStatsPeriod,
    ]);
  }
}
