import 'package:flutter/material.dart';
import 'package:stateful_widget/admin/admin_reports.dart';
import 'package:stateful_widget/admin/admin_organizations.dart';
import 'package:stateful_widget/widgets/admin_bottom_nav.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  int _navIndex = 1;

  /// Sample activity mix powering the donut visualization.
  static const _engagementData = [
    {'label': 'Comments', 'value': 28, 'color': Color(0xFF6B4C4C)},
    {'label': 'Messages', 'value': 38, 'color': Color(0xFF8D6B6B)},
    {'label': 'Marketplace', 'value': 15, 'color': Color(0xFFD32F2F)},
    {'label': 'Posts', 'value': 19, 'color': Color(0xFF8D0B15)},
  ];

  /// Headline KPI cards shown beneath the charts.
  static const _metricsData = [
    {
      'title': 'Total Posts',
      'value': '2,390',
      'subtitle': '+15% this month',
      'unit': '',
    },
    {
      'title': 'Avg. Session',
      'value': '12',
      'unit': 'm',
      'subtitle': 'Per user daily',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: AdminBottomNav(
          currentIndex: _navIndex,
          onItemTapped: (index) {
            setState(() {
              _navIndex = index;
            });
            _handleNavTap(index);
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildUserGrowthCard(),
                      const SizedBox(height: 20),
                      _buildEngagementCard(),
                      const SizedBox(height: 20),
                      ..._metricsData.map((metric) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMetricCard(metric),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Platform usage and engagement metrics',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly active users over time',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: LineChartPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildEngagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activity breakdown by feature',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildDonutChart(),
          const SizedBox(height: 16),
          _buildEngagementLegend(),
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    return Center(
      child: SizedBox(
        height: 200,
        width: 200,
        child: CustomPaint(
          painter: DonutChartPainter(),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildEngagementLegend() {
    return Column(
      children: _engagementData.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '${item['value']}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final unit = metric['unit'] as String? ?? '';
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  metric['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  metric['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handles admin bottom navigation transitions from analytics.
  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pop(context, 0);
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminReports()),
        ).then((result) {
          if (result != null) {
            setState(() {
              _navIndex = result as int;
            });
          }
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminOrganizations()),
        );
        break;
    }
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D0B15)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF8D0B15)
      ..strokeWidth = 4;

    // Y-axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final dataPoints = [60.0, 100.0, 130.0, 150.0, 170.0, 190.0];
    final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    final chartHeight = size.height - 40;
    final chartWidth = size.width - 40;
    final pointSpacing = chartWidth / (dataPoints.length - 1);
    final maxValue = 300.0;

    // Draw grid lines and Y-axis labels
    for (int i = 0; i <= 3; i++) {
      final y = chartHeight - (chartHeight / 3) * i;
      final value = (maxValue / 3) * i;

      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-35, y - 6));

      if (i > 0) {
        canvas.drawLine(
          Offset(0, y),
          Offset(chartWidth, y),
          Paint()
            ..color = Colors.grey[200]!
            ..strokeWidth = 0.5,
        );
      }
    }

    // Draw line chart
    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = pointSpacing * i;
      final y = chartHeight - (dataPoints[i] / maxValue) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = pointSpacing * i;
      final y = chartHeight - (dataPoints[i] / maxValue) * chartHeight;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    for (int i = 0; i < labels.length; i++) {
      final x = pointSpacing * i;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 8));
    }

    textPainter.text = TextSpan(
      text: 'USERS',
      style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(chartWidth - 35, -5));
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final innerRadius = radius - 35;

    final data = [
      {'label': 'Comments', 'value': 28, 'color': const Color(0xFF6B4C4C)},
      {'label': 'Messages', 'value': 38, 'color': const Color(0xFF8D6B6B)},
      {'label': 'Marketplace', 'value': 15, 'color': const Color(0xFFD32F2F)},
      {'label': 'Posts', 'value': 19, 'color': const Color(0xFF8D0B15)},
    ];

    final total = data.fold<int>(0, (sum, item) => sum + (item['value'] as int));
    var startAngle = -90.0;

    for (var item in data) {
      final value = item['value'] as int;
      final sweepAngle = (value / total) * 360;
      final color = item['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);

      final startRad = startAngle * 3.14159 / 180;
      final endRad = (startAngle + sweepAngle) * 3.14159 / 180;

      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startRad,
        sweepAngle * 3.14159 / 180,
        false,
      );

      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endRad,
        -sweepAngle * 3.14159 / 180,
        false,
      );

      path.close();
      canvas.drawPath(path, paint);

      startAngle += sweepAngle;
    }

    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => false;
}
