import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:slide_switcher/slide_switcher.dart';

class StatsPage extends StatefulWidget {
  static const int maxScale = 4;
  final List<double> data;
  final int statsPeriod;

  const StatsPage({
    required this.data,
    required this.statsPeriod,
    super.key,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _switcherIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              alignment: Alignment.bottomCenter,
              height: 30 + MediaQuery.of(context).viewPadding.top,
              child: const Text(
                'Number of correct answers during training',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width *
                      (widget.data.length / 20).ceil() /
                      _switcherIndex,
                  child: LineChart(
                    painter: LineChartPainter(
                      lineChartContainer: LineChartTopContainer(
                        chartData: ChartData(
                          dataRows: [
                            widget.data
                                .slices(_switcherIndex)
                                .where((element) => element.length == _switcherIndex)
                                .map((element) => element.reduce((a, b) => a + b))
                                .toList(),
                          ],
                          dataRowsLegends: const [''],
                          chartOptions: const ChartOptions(),
                          xUserLabels: widget.data
                              .mapIndexed((ind, _) => ind + 1)
                              .slices(_switcherIndex)
                              .where((element) => element.length == _switcherIndex)
                              .map((element) => element.reduce(max))
                              .map((ind) => (ind * widget.statsPeriod).toString())
                              .toList(),
                        ),
                        xContainerLabelLayoutStrategy: null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SlideSwitcher(
              onSelect: (index) => setState(() => _switcherIndex = index + 1),
              containerHeight: 40,
              containerWight: 350,
              children: [
                Text('1x${widget.statsPeriod}'),
                Text('2x${widget.statsPeriod}'),
                Text('3x${widget.statsPeriod}'),
                Text('4x${widget.statsPeriod}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
