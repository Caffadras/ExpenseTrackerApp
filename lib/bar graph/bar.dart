import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'individual_bar.dart';

class MyBarGraph extends StatefulWidget {
  final List<double> monthlySummary;
  final int startMonth;

  const MyBarGraph({
    required this.monthlySummary,
    required this.startMonth,
    super.key,
  });

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  List<IndividualBar> barData = [];

  void initializeBarData() {
    barData = List.generate(
        widget.monthlySummary.length,
        (index) => IndividualBar(
              x: index,
              y: widget.monthlySummary[index],
            ));
  }

  double calculateMax() {
    double defaultMax = 500;
    widget.monthlySummary.sort();

    final calculatedMax = widget.monthlySummary.last * 1.05;
    return max(defaultMax, calculatedMax);
  }


  @override
  Widget build(BuildContext context) {
    initializeBarData();

    double barWidth = 20;
    double spaceBetweenBars = 15;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: SizedBox(
          width: barWidth * barData.length +
              spaceBetweenBars * (barData.length - 1),
          child: BarChart(
            BarChartData(
              minY: 10,
              maxY: calculateMax(),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getBottomTitles,
                      reservedSize: 24),
                ),
              ),
              barGroups: barData
                  .map((data) => BarChartGroupData(
                        x: data.x,
                        barRods: [
                          BarChartRodData(
                              toY: data.y,
                              width: barWidth,
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.grey.shade800,
                              backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: calculateMax(),
                                  color: Colors.grey.shade200))
                        ],
                      ))
                  .toList(),
              alignment: BarChartAlignment.center,
              groupsSpace: spaceBetweenBars,
            ),
          ),
        ),
      ),
    );
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    const textStyle = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text = gitFirstLetterOfTheMonth(value.toInt());

    return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          text,
          style: textStyle,
        ));
  }

  String gitFirstLetterOfTheMonth(int index) {
    return [
      "J",
      "F",
      "M",
      "A",
      "M",
      "J",
      "J",
      "A",
      "S",
      "O",
      "N",
      "D"
    ][index % 12];
  }
}
