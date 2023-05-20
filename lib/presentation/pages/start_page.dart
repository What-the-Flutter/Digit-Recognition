import 'dart:math';

import 'package:digit_recognition/presentation/pages/home_page.dart';
import 'package:digit_recognition/presentation/text_styles.dart';
import 'package:digit_recognition/utils/files.dart';
import 'package:digit_recognition/utils/perceptron_config.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final List<String> _alphabet = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0).copyWith(
                top: 12.0 + MediaQuery.of(context).viewPadding.top,
              ),
              child: _customConfig(),
            ),
          ),
          const Divider(thickness: 3.0),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text(
                    'Or import an existing one',
                    style: style30,
                  ),
                  Expanded(
                    child: Center(
                      child: _Button(
                        onTap: _importConfig,
                        disabled: false,
                        color: Colors.lightBlue,
                        title: 'Import configuration',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Create your own recognizer',
          style: style30,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: _Alphabet(
              elements: _alphabet,
              onDelete: (item) => setState(() => _alphabet.remove(item)),
            ),
          ),
        ),
        _Input(
          onAdd: (added) {
            if (!_alphabet.contains(added)) {
              setState(() => _alphabet.add(added));
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: _Button(
            onTap: _createConfig,
            disabled: _alphabet.length < 2,
            color: Colors.green,
            title: 'Train network!',
          ),
        ),
      ],
    );
  }

  void _createConfig() {
    const inputsCount = MyHomePage.imageSize * MyHomePage.imageSize;
    final outputsCount = _alphabet.length;
    final random = Random();

    /// For every output neuron we initialize a list of weights coming from every input with
    /// values [-0.5, 0.5];
    final config = PerceptronConfig(
      alphabet: _alphabet,
      inputsCount: inputsCount,
      outputsCount: outputsCount,
      weights: List.generate(
        outputsCount,
        (_) => List.generate(inputsCount, (_) => random.nextDouble() - 0.5),
      ),
      errorsInStatsPeriod: List.empty(growable: true),
    );

    _navigateWithConfig(config);
  }

  void _importConfig() async {
    final config = await Files.importConfig();
    if (config != null) {
      _navigateWithConfig(config);
    }
  }

  void _navigateWithConfig(PerceptronConfig config) {
    final newRoute = MaterialPageRoute(builder: (_) => MyHomePage(config: config));
    Navigator.of(context).pushAndRemoveUntil(newRoute, (route) => route == newRoute);
  }
}

class _Button extends StatelessWidget {
  final VoidCallback onTap;
  final bool disabled;
  final Color color;
  final String title;

  const _Button({
    required this.onTap,
    required this.disabled,
    required this.color,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 50.0,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey : color,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          title,
          style: style30white,
        ),
      ),
    );
  }
}

class _Alphabet extends StatelessWidget {
  final List<String> elements;
  final void Function(String) onDelete;

  const _Alphabet({
    required this.elements,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        itemCount: elements.length,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    elements[index],
                    style: style20,
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(elements[index]),
                  icon: const Icon(Icons.delete),
                )
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(thickness: 2.0),
      ),
    );
  }
}

class _Input extends StatefulWidget {
  final void Function(String) onAdd;

  const _Input({required this.onAdd});

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: TextField(
              style: style20,
              controller: _controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        FloatingActionButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onAdd(_controller.text);
              _controller.text = '';
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
