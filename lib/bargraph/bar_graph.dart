import 'package:expense_tracker/bargraph/individual_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  void initializeBarData() {
    barsData = List.generate(
      widget.monthlySummary.length,
      (index) => IndividualBar(
        index,
        widget.monthlySummary[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    initializeBarData();
    return BarChart(
      BarChartData(
        groupsSpace: 1,
        minY: 0,
        maxY: 100,
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
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget getBottomTitles(double value, TitleMeta meta) {
    var textStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'J';
        break;
      case 1:
        text = 'F';
        break;
      case 2:
        text = 'M';
        break;
      case 3:
        text = 'A';
        break;
      case 4:
        text = 'M';
        break;
      case 5:
        text = 'J';
        break;
      case 6:
        text = 'J';
        break;
      case 7:
        text = 'A';
        break;
      case 8:
        text = 'S';
        break;
      case 9:
        text = 'O';
        break;
      case 10:
        text = 'N';
        break;
      case 11:
        text = 'D';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: textStyle),
    );
  }
}
