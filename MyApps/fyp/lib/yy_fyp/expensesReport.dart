import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class ExpensesReport extends StatefulWidget {
  final Map<String, dynamic> budgetData;
  final List<dynamic> expenses;

  const ExpensesReport({
    Key? key,
    required this.budgetData,
    required this.expenses,
  }) : super(key: key);

  @override
  _ExpensesReportState createState() => _ExpensesReportState();
}

class _ExpensesReportState extends State<ExpensesReport> {
  bool _isLoading = false;
  String _selectedTimeframe = 'All';
  List<String> _timeframes = ['All', 'This Week', 'This Month'];
  Map<String, double> _categoryTotals = {};
  List<dynamic> _filteredExpenses = [];
  double _totalSpent = 0;
  double _averageExpense = 0;
  String? _largestCategory;
  String? _largestExpense;
  Map<String, List<double>> _dailySpending = {};

  @override
  void initState() {
    super.initState();
    _generateReport(_selectedTimeframe);
  }

  void _generateReport(String timeframe) {
    setState(() {
      _isLoading = true;
    });

    // Filter expenses based on timeframe
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    _filteredExpenses = widget.expenses.where((expense) {
      DateTime expenseDate;
      if (expense['date'] is String) {
        expenseDate = DateTime.parse(expense['date']);
      } else {
        expenseDate = DateTime.fromMillisecondsSinceEpoch(expense['date']);
      }

      if (timeframe == 'This Week') {
        return expenseDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } else if (timeframe == 'This Month') {
        return expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1)));
      } else {
        return true; // All expenses
      }
    }).toList();

    // Sort expenses by date (newest first)
    _filteredExpenses.sort((a, b) {
      DateTime dateA, dateB;
      if (a['date'] is String) {
        dateA = DateTime.parse(a['date']);
      } else {
        dateA = DateTime.fromMillisecondsSinceEpoch(a['date']);
      }
      
      if (b['date'] is String) {
        dateB = DateTime.parse(b['date']);
      } else {
        dateB = DateTime.fromMillisecondsSinceEpoch(b['date']);
      }
      
      return dateB.compareTo(dateA);
    });

    // Calculate category totals
    _categoryTotals = {};
    for (var expense in _filteredExpenses) {
      final category = expense['category'];
      final amount = double.parse(expense['amount'].toString());
      
      if (_categoryTotals.containsKey(category)) {
        _categoryTotals[category] = _categoryTotals[category]! + amount;
      } else {
        _categoryTotals[category] = amount;
      }
    }

    // Calculate total spent
    _totalSpent = _categoryTotals.values.fold(0, (sum, value) => sum + value);

    // Calculate average expense
    _averageExpense = _filteredExpenses.isNotEmpty 
        ? _totalSpent / _filteredExpenses.length 
        : 0;

    // Find largest category
    _largestCategory = _categoryTotals.isEmpty 
        ? null 
        : _categoryTotals.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    // Find largest expense
    if (_filteredExpenses.isNotEmpty) {
      var largestExpense = _filteredExpenses.reduce(
        (a, b) => double.parse(a['amount'].toString()) > double.parse(b['amount'].toString()) ? a : b
      );
      _largestExpense = '${largestExpense['category']} - \$${double.parse(largestExpense['amount'].toString()).toStringAsFixed(2)}';
    } else {
      _largestExpense = null;
    }

    // Calculate daily spending
    _dailySpending = {};
    for (var expense in _filteredExpenses) {
      DateTime expenseDate;
      if (expense['date'] is String) {
        expenseDate = DateTime.parse(expense['date']);
      } else {
        expenseDate = DateTime.fromMillisecondsSinceEpoch(expense['date']);
      }
      
      final dateString = DateFormat('yyyy-MM-dd').format(expenseDate);
      final amount = double.parse(expense['amount'].toString());
      final category = expense['category'];
      
      if (!_dailySpending.containsKey(dateString)) {
        _dailySpending[dateString] = List.filled(_categoryTotals.keys.length, 0);
      }
      
      final categoryIndex = _categoryTotals.keys.toList().indexOf(category);
      if (categoryIndex >= 0) {
        _dailySpending[dateString]![categoryIndex] += amount;
      }
    }

    setState(() {
      _isLoading = false;
      _selectedTimeframe = timeframe;
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _shareReport() async {
    // Simulate sharing functionality
    setState(() {
      _isLoading = true;
    });

    // Report text generation
    final report = '''
EXPENSE REPORT
${widget.budgetData['tripName'] ?? 'Trip Budget'}
${_formatDate(widget.budgetData['startDate'])} - ${_formatDate(widget.budgetData['endDate'])}

Timeframe: $_selectedTimeframe
Total Budget: \$${widget.budgetData['totalBudget'].toStringAsFixed(2)}
Total Spent: \$${_totalSpent.toStringAsFixed(2)}
Remaining: \$${(widget.budgetData['totalBudget'] - _totalSpent).toStringAsFixed(2)}

CATEGORY BREAKDOWN:
${_categoryTotals.entries.map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

Average Expense: \$${_averageExpense.toStringAsFixed(2)}
Largest Category: ${_largestCategory ?? 'None'}
Largest Expense: ${_largestExpense ?? 'None'}
    ''';

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: report));
    
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Header
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.budgetData['tripName'] ?? 'Trip Budget',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _selectedTimeframe,
                                items: _timeframes.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    _generateReport(value);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatDate(widget.budgetData['startDate'])} - ${_formatDate(widget.budgetData['endDate'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Key Metrics
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Key Metrics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Total Spent',
                                  '\$${_totalSpent.toStringAsFixed(2)}',
                                  Icons.account_balance_wallet,
                                  _totalSpent > widget.budgetData['totalBudget'] ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricCard(
                                  'Remaining',
                                  '\$${(widget.budgetData['totalBudget'] - _totalSpent).toStringAsFixed(2)}',
                                  Icons.savings,
                                  _totalSpent > widget.budgetData['totalBudget'] ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Average Expense',
                                  '\$${_averageExpense.toStringAsFixed(2)}',
                                  Icons.bar_chart,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricCard(
                                  'Total Expenses',
                                  _filteredExpenses.length.toString(),
                                  Icons.receipt_long,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoCard(
                            'Largest Category',
                            _largestCategory ?? 'None',
                            Icons.category,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoCard(
                            'Largest Expense',
                            _largestExpense ?? 'None',
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category Breakdown
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_categoryTotals.isEmpty)
                            const Center(
                              child: Text(
                                'No expenses in this period',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            ...buildCategoryBars(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Expenses
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_filteredExpenses.isEmpty)
                            const Center(
                              child: Text(
                                'No expenses in this period',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(5, _filteredExpenses.length),
                              itemBuilder: (context, index) {
                                final expense = _filteredExpenses[index];
                                DateTime expenseDate;
                                if (expense['date'] is String) {
                                  expenseDate = DateTime.parse(expense['date']);
                                } else {
                                  expenseDate = DateTime.fromMillisecondsSinceEpoch(expense['date']);
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(expense['category']),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          DateFormat('MMM dd, yyyy').format(expenseDate),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '\$${double.parse(expense['amount'].toString()).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          if (_filteredExpenses.length > 5) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  // Navigate back to the expenses list
                                  Navigator.pop(context);
                                },
                                child: const Text('View All Expenses'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildCategoryBars() {
    // Get total for percentage calculations
    final total = _categoryTotals.values.fold(0.0, (a, b) => a + b);
    
    // Sort categories by amount (largest first)
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate a color for each category
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    return sortedCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = total > 0 ? (amount / total * 100) : 0;
      final color = colors[index % colors.length];
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category),
                Text(
                  '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? amount / total : 0,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}