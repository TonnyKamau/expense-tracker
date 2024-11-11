import 'package:expensetracker/bargraph/individual_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class MyBarGraph extends StatefulWidget {
  final List<double> monthlySummary;
  final int startMonth;

  const MyBarGraph({
    super.key,
    required this.monthlySummary,
    required this.startMonth,
  });

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  List<IndividualBar> barsData = [];
  final NumberFormat numberFormat = NumberFormat.compact();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) => scrollEnd());
  }

  void initializeBarData() {
    barsData = List.generate(
      widget.monthlySummary.length,
      (index) => IndividualBar(
        index,
        widget.monthlySummary[index],
      ),
    );
  }

  double calculateUpperLimit(NumberFormat numberFormat) {
    double upperLimit = 500;
    widget.monthlySummary.sort();
    upperLimit = widget.monthlySummary.last * 1.05;
    if (upperLimit < 500) {
      return 500;
    }
    return upperLimit;
  }

  final ScrollController _scrollController = ScrollController();
  void scrollEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeBarData();
    double barWidth = 20.0;
    double spaceBetweenBars = 15.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SizedBox(
          width: barWidth * barsData.length +
              spaceBetweenBars * (barsData.length - 1),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: calculateUpperLimit(numberFormat),
              gridData: const FlGridData(
                show: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: getBottomTitles,
                    reservedSize: 24.0,
                  ),
                ),
              ),
              barGroups: barsData
                  .map(
                    (data) => BarChartGroupData(
                      x: data.x,
                      barRods: [
                        BarChartRodData(
                          toY: data.y,
                          width: barWidth,
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: calculateUpperLimit(numberFormat),
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
              alignment: BarChartAlignment.end,
              groupsSpace: spaceBetweenBars,
            ),
          ),
        ),
      ),
    );
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    var textStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    int monthIndex = ((widget.startMonth - 1 + value.toInt()) % 12).toInt();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(months[monthIndex], style: textStyle),
    );
  }
}
