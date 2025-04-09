import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserActivityReport extends StatefulWidget {
  const UserActivityReport({Key? key}) : super(key: key);

  @override
  State<UserActivityReport> createState() => _UserActivityReportState();
}

class _UserActivityReportState extends State<UserActivityReport> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reportData;

  // Colors for charts
  final List<Color> _chartColors = [
    const Color(0xFF0088FE),
    const Color(0xFF00C49F),
    const Color(0xFFFFBB28),
    const Color(0xFFFF8042),
    const Color(0xFF8884D8),
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivityReport();
  }

  Future<void> _fetchActivityReport() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      // Make API request
      final response = await http.get(
        Uri.parse('http://172.20.10.3:3000/activityReport'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reportData = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to load data. Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activity Report'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchActivityReport,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
              : _buildReportContent(),
    );
  }

  Widget _buildReportContent() {
    final totalUsers = _reportData?['totalUsers'] ?? 0;
    final averages = _reportData?['averages'] ?? {};
    final userActivities = _reportData?['userActivities'] ?? [];

    return RefreshIndicator(
      onRefresh: _fetchActivityReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(totalUsers, averages),
            const SizedBox(height: 24),

            // User Activity Bar Chart
            _buildSectionTitle('User Activity Comparison'),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  userActivities.isEmpty
                      ? const Center(
                        child: Text('No user activity data available'),
                      )
                      : _buildBarChart(userActivities),
            ),
            const SizedBox(height: 24),

            // Average Activity Pie Chart
            _buildSectionTitle('Average Activity Distribution'),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildPieChart(averages),
            ),

            // User Activity Table
            const SizedBox(height: 24),
            _buildSectionTitle('Detailed User Activity'),
            _buildUserActivityTable(userActivities),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(int totalUsers, Map<String, dynamic> averages) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          'Total Users',
          totalUsers.toString(),
          Colors.blue[100]!,
          Colors.blue[800]!,
          Icons.people,
        ),
        _buildSummaryCard(
          'Avg. Itineraries',
          averages['itinerariesPerUser'] ?? '0',
          Colors.green[100]!,
          Colors.green[800]!,
          Icons.map,
        ),
        _buildSummaryCard(
          'Avg. Messages',
          averages['messagesPerUser'] ?? '0',
          Colors.orange[100]!,
          Colors.orange[800]!,
          Icons.message,
        ),
        _buildSummaryCard(
          'Avg. Reviews',
          averages['reviewsPerUser'] ?? '0',
          Colors.purple[100]!,
          Colors.purple[800]!,
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> userActivities) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(userActivities),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (touchedBarGroup) {
              return Colors.blueGrey.withOpacity(
                0.8,
              ); // This replaces tooltipBgColor
            },
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < userActivities.length) {
                  final email = userActivities[index]['email'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: 45 * 3.14159 / 180, // Convert degrees to radians
                      child: Text(
                        email.split('@')[0],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.black, fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          userActivities.length > 5
              ? 5
              : userActivities.length, // Limit to 5 users for readability
          (index) {
            final user = userActivities[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (user['itineraryCount'] ?? 0).toDouble(),
                  color: _chartColors[0],
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
                BarChartRodData(
                  toY: (user['messageCount'] ?? 0).toDouble(),
                  color: _chartColors[1],
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
                BarChartRodData(
                  toY: (user['reviewCount'] ?? 0).toDouble(),
                  color: _chartColors[2],
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _calculateMaxY(List<dynamic> userActivities) {
    double maxY = 0;
    for (final user in userActivities) {
      final itineraryCount = (user['itineraryCount'] ?? 0).toDouble();
      final messageCount = (user['messageCount'] ?? 0).toDouble();
      final reviewCount = (user['reviewCount'] ?? 0).toDouble();

      final max = [
        itineraryCount,
        messageCount,
        reviewCount,
      ].reduce((a, b) => a > b ? a : b);
      if (max > maxY) maxY = max;
    }
    return maxY * 1.2; // Add 20% padding
  }

  Widget _buildPieChart(Map<String, dynamic> averages) {
    final List<PieChartSectionData> sections = [];

    // Convert string values to doubles
    final itineraryValue =
        double.tryParse(averages['itinerariesPerUser'] ?? '0') ?? 0.0;
    final messageValue =
        double.tryParse(averages['messagesPerUser'] ?? '0') ?? 0.0;
    final reviewValue =
        double.tryParse(averages['reviewsPerUser'] ?? '0') ?? 0.0;

    // Only add non-zero values
    if (itineraryValue > 0) {
      sections.add(
        PieChartSectionData(
          color: _chartColors[0],
          value: itineraryValue,
          title: itineraryValue.toStringAsFixed(1),
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (messageValue > 0) {
      sections.add(
        PieChartSectionData(
          color: _chartColors[1],
          value: messageValue,
          title: messageValue.toStringAsFixed(1),
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (reviewValue > 0) {
      sections.add(
        PieChartSectionData(
          color: _chartColors[2],
          value: reviewValue,
          title: reviewValue.toStringAsFixed(1),
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add a dummy section if all values are zero
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Itineraries', _chartColors[0]),
              _buildLegendItem('Messages', _chartColors[1]),
              _buildLegendItem('Reviews', _chartColors[2]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityTable(List<dynamic> userActivities) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Itineraries')),
            DataColumn(label: Text('Messages')),
            DataColumn(label: Text('Reviews')),
          ],
          rows: List.generate(userActivities.length, (index) {
            final user = userActivities[index];
            return DataRow(
              cells: [
                DataCell(Text(user['email'].split('@')[0])),
                DataCell(Text('${user['itineraryCount'] ?? 0}')),
                DataCell(Text('${user['messageCount'] ?? 0}')),
                DataCell(Text('${user['reviewCount'] ?? 0}')),
              ],
            );
          }),
        ),
      ),
    );
  }
}
