import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/units.dart';
import '../../climate/domain/climate_profile.dart';

/// WX-01 "Your climate" monthly chart: average high and low lines over
/// precipitation bars for twelve months.
///
/// fl_chart has no combined line and bar chart, so two charts share one frame.
/// Both reserve the same axis space, so their month columns line up. Touch is
/// disabled on both.
class ClimateChart extends StatelessWidget {
  const ClimateChart({
    super.key,
    required this.profile,
    required this.metric,
    required this.currentMonth,
  });

  static const double _height = 150;
  static const double _axisReserved = 36;
  static const int _steps = 3;
  static const double _labelReserved = 24;
  static const double _barWidth = AppSpacing.sm;
  static const double _dotRadius = AppSpacing.xs;
  static const double _gridStroke = 1;
  static const List<String> _monthLetters = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  /// Twelve months, index 0 = January.
  final ClimateProfile profile;

  /// True shows °C and mm. False shows °F and inches.
  final bool metric;

  /// Current month, 1 for January through 12 for December. Marks the dot on
  /// the high line and the matching month letter.
  final int currentMonth;

  static const Color _rainColor = AppColors.tileSky;

  static TextStyle get _axisLabel =>
      AppText.caption.copyWith(color: AppColors.soil600);

  static TextStyle get _currentLabel => AppText.caption.copyWith(
    color: AppColors.soil900,
    fontWeight: FontWeight.w700,
  );

  /// A white-centred ring on the current month's point.
  static FlDotData _currentDot(Color color, int current) => FlDotData(
    checkToShowDot: (spot, barData) => spot.x.round() == current,
    getDotPainter: (spot, xPercentage, barData, index) => FlDotCirclePainter(
      color: AppColors.white,
      strokeColor: color,
      strokeWidth: AppBorders.width,
      radius: _dotRadius,
    ),
  );

  double _temp(double fahrenheit) =>
      metric ? fahrenheitToCelsiusDisplay(fahrenheit).toDouble() : fahrenheit;

  double _precip(double inches) =>
      metric ? inchesToMillimetersDisplay(inches) : inches;

  @override
  Widget build(BuildContext context) {
    final months = profile.months;
    final current = currentMonth - 1;
    final highs = [
      for (var i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), _temp(months[i].avgHighF)),
    ];
    final lows = [
      for (var i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), _temp(months[i].avgLowF)),
    ];
    // Three equal steps on both axes, so the labels (four per side) and the
    // gridlines line up in either unit.
    final temps = [
      for (final p in [...highs, ...lows]) p.y,
    ];
    final lowest = temps.reduce(math.min);
    final highest = temps.reduce(math.max);
    var tempStep = 5.0;
    while ((lowest / tempStep).floor() * tempStep + _steps * tempStep <
        highest) {
      tempStep += 5;
    }
    final minTemp = (lowest / tempStep).floor() * tempStep;
    final maxTemp = minTemp + _steps * tempStep;
    final wettest = months.map((m) => _precip(m.precipIn)).reduce(math.max);
    final rainQuantum = metric ? 10.0 : 1.0;
    final rainStep = math.max(
      rainQuantum,
      (wettest / _steps / rainQuantum).ceil() * rainQuantum,
    );
    final maxRain = rainStep * _steps;
    final rain = [
      for (var i = 0; i < months.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _precip(months[i].precipIn),
              color: _rainColor,
              width: _barWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.xs),
              ),
            ),
          ],
        ),
    ];

    // Line x positions are (i + 0.5) / 12 across the plot. The bar groups
    // with spaceAround land at the same fractions, so the two align.
    final lineChart = LineChartData(
      minY: minTemp,
      maxY: maxTemp,
      minX: -0.5,
      maxX: months.length - 0.5,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: tempStep,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.stone200, strokeWidth: _gridStroke),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisReserved,
            interval: tempStep,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                '${value.round()}°',
                style: _axisLabel,
                softWrap: false,
              ),
            ),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisReserved,
            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _labelReserved,
            interval: 1,
            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: highs,
          color: AppColors.heat,
          barWidth: AppBorders.width,
          dotData: _currentDot(AppColors.heat, current),
        ),
        LineChartBarData(
          spots: lows,
          color: AppColors.frost,
          barWidth: AppBorders.width,
          dotData: _currentDot(AppColors.frost, current),
        ),
      ],
    );

    final barChart = BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: rain,
      minY: 0,
      maxY: maxRain,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisReserved,
            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisReserved,
            interval: rainStep,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text('${value.round()}', style: _axisLabel),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _labelReserved,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  _monthLetters[index],
                  style: index == current ? _currentLabel : _axisLabel,
                ),
              );
            },
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendItem(color: AppColors.heat, label: 'Avg high', line: true),
            _LegendItem(color: AppColors.frost, label: 'Avg low', line: true),
            _LegendItem(color: _rainColor, label: 'Rain'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(child: BarChart(barChart)),
              Positioned.fill(child: LineChart(lineChart)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.line = false,
  });

  final Color color;
  final String label;

  /// A short rule for the line series; a square for the bars.
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(line ? 2 : AppRadii.chip / 2),
          ),
          child: SizedBox(
            width: AppSpacing.lg - 2,
            height: line ? 3 : AppSpacing.lg - 2,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppText.bodySm.copyWith(color: AppColors.soil600)),
      ],
    );
  }
}
