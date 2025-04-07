import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'expensesDetails.dart';
import '../screens/currentUser.dart';

class ExpensesList extends StatefulWidget {
  final String userId;

  const ExpensesList({Key? key, required this.userId}) : super(key: key);

  @override
  _ExpensesListState createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  List<dynamic> budgets = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:3000'; // Replace with your actual API URL
  String? errorMessage;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = Currentuser.getUserId(); // Retrieve stored userId
    if (userId == null) {
      setState(() {
        errorMessage = "⚠️ User not logged in.";
        isLoading = false;
      });
    } else {
      fetchBudgets();
    }
  }

  Future<void> fetchBudgets() async {
  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.get(
    Uri.parse('$baseUrl/budget/user/$userId'), // Use the class variable, not widget.userId
    headers: {'Content-Type': 'application/json'},
  );

    print("Fetch response status: ${response.statusCode}");
    print("Fetch response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        budgets = data['data'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load budgets');
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _calculateProgress(dynamic budget) {
    if (budget['totalBudget'] == 0) return '0%';
    
    double totalExpenses = 0;
    if (budget['expenses'] != null) {
      for (var expense in budget['expenses']) {
        totalExpenses += double.parse(expense['amount'].toString());
      }
    }
    
    double percentage = (totalExpenses / budget['totalBudget']) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  double _calculateProgressValue(dynamic budget) {
    if (budget['totalBudget'] == 0) return 0;
    
    double totalExpenses = 0;
    if (budget['expenses'] != null) {
      for (var expense in budget['expenses']) {
        totalExpenses += double.parse(expense['amount'].toString());
      }
    }
    
    double value = totalExpenses / budget['totalBudget'];
    return value > 1 ? 1 : value; // Cap at 1 for UI purposes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travel Budgets'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new budget for your trip',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchBudgets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpensesDetails(
                                  budgetId: budget['_id'],
                                  userId: widget.userId,
                                ),
                              ),
                            );
                            if (result == true) {
                              fetchBudgets();
                            }
                          },
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
                                        budget['tripName'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${budget['totalBudget'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_formatDate(budget['startDate'])} - ${_formatDate(budget['endDate'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _calculateProgressValue(budget),
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _calculateProgressValue(budget) > 0.9 ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _calculateProgress(budget),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _calculateProgressValue(budget) > 0.9 ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateBudgetDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateBudgetDialog() {
    final formKey = GlobalKey<FormState>();
    final tripNameController = TextEditingController();
    final totalBudgetController = TextEditingController();
    final String? currentUserId = Currentuser.getUserId();
    print("Current User ID: $currentUserId");
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Budget'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tripNameController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a trip name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: totalBudgetController,
                    decoration: const InputDecoration(
                      labelText: 'Total Budget (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a budget amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Start Date:'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('End Date:'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Add these debugging lines
                    final requestBody = json.encode({
                      'tripName': tripNameController.text,
                      "userId": Currentuser.getUserId(),
                      'startDate': startDate.toIso8601String(),
                      'endDate': endDate.toIso8601String(),
                      'totalBudget': double.parse(totalBudgetController.text),
                    });
                    print("Request body: $requestBody");
                    
                    // Use the requestBody variable in your post request
                    final response = await http.post(
                      Uri.parse('$baseUrl/budget'),
                      headers: {'Content-Type': 'application/json'},
                      body: requestBody,
                    );

                    // Add response debugging
                    print("Response status: ${response.statusCode}");
                    print("Response body: ${response.body}");

                    if (response.statusCode == 201) {
                      Navigator.pop(context);
                      fetchBudgets();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Budget created successfully')),
                      );
                    } else {
                      throw Exception('Failed to create budget: ${response.body}');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}