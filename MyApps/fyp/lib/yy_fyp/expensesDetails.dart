import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../screens/currentUser.dart';
import 'package:fyp/yy_fyp/expensesReport.dart';

class ExpensesDetails extends StatefulWidget {
  final String budgetId;
  final String userId;

  const ExpensesDetails({
    Key? key,
    required this.budgetId,
    required this.userId,
  }) : super(key: key);

  @override
  _ExpensesDetailsState createState() => _ExpensesDetailsState();
}

class _ExpensesDetailsState extends State<ExpensesDetails> {
  bool isLoading = true;
  Map<String, dynamic> budgetData = {};
  List<dynamic> expenses = [];
  List<dynamic> paidBookings = [];
  final String baseUrl = 'http://10.0.2.2:3000'; // Replace with your actual API URL
  
  // Expense categories
  final List<String> categories = [
    'Food',
    'Transport',
    'Hotel',
    'Activities',
    'Shopping',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    fetchBudgetDetails();
    fetchUserPaidBookings();
  }

  // Add this helper method to your class
Future<http.Response> _httpRequest(String method, String url, {Map<String, dynamic>? body}) async {
  http.Response response;
  final headers = {'Content-Type': 'application/json'};
  
  print('⬆️ $method request to: $url');
  if (body != null) print('Body: ${json.encode(body)}');
  
  switch (method) {
    case 'GET':
      response = await http.get(Uri.parse(url), headers: headers);
      break;
    case 'POST':
      response = await http.post(Uri.parse(url), headers: headers, body: body != null ? json.encode(body) : null);
      break;
    case 'PUT':
      response = await http.put(Uri.parse(url), headers: headers, body: body != null ? json.encode(body) : null);
      break;
    case 'DELETE':
      response = await http.delete(Uri.parse(url), headers: headers);
      break;
    default:
      throw Exception('Unsupported HTTP method');
  }
  
  print('⬇️ Response status: ${response.statusCode}');
  print('Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
  
  return response;
}

  Future<void> fetchBudgetDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budget/${widget.budgetId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          budgetData = data['data'];
          expenses = budgetData['expenses'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load budget details');
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

  Future<void> fetchUserPaidBookings() async {
    try {
      final userId = Currentuser.getUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/paid/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          paidBookings = data['data'];
        });
      } else {
        throw Exception('Failed to load paid bookings');
      }
    } catch (e) {
      print('Error fetching paid bookings: ${e.toString()}');
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateFromTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return _formatDate(timestamp);
    } else {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  double _calculateTotalSpent() {
    double total = 0;
    for (var expense in expenses) {
      total += double.parse(expense['amount'].toString());
    }
    return total;
  }

  Map<String, double> _calculateCategoryTotals() {
    Map<String, double> categoryTotals = {};
    
    for (var expense in expenses) {
      final category = expense['category'];
      final amount = double.parse(expense['amount'].toString());
      
      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }
    
    return categoryTotals;
  }

  Future<void> _addExpense() async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = categories.first;
    DateTime selectedDate = DateTime.now();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            print('Building add expense dialog with category: $selectedCategory');
            print('Categories list: $categories');
            return AlertDialog(
              title: const Text('Add Expense'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (\$)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
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
                          const Text('Date:'),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            child: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                        final response = await _httpRequest('POST', '$baseUrl/budget/${widget.budgetId}/expense', body: {
                          'category': selectedCategory,
                          'amount': double.parse(amountController.text),
                          'date': selectedDate.toIso8601String(),
                          'notes': notesController.text,
                        });

                        if (response.statusCode == 201) {
                          Navigator.pop(context);
                          fetchBudgetDetails();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense added successfully')),
                          );
                        } else {
                          throw Exception('Failed to add expense: ${response.body}');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editExpense(dynamic expense) async {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController(text: expense['amount'].toString());
  final notesController = TextEditingController(text: expense['notes'] ?? '');

  print('🛠️ Editing expense: $expense');

  String originalCategory = expense['category'];
  String selectedCategory = originalCategory;

  print('Original category from expense: $originalCategory');
  print('Available categories: $categories');

  for (String category in categories) {
    if (category.toLowerCase() == originalCategory.toLowerCase()) {
      selectedCategory = category;
      break;
    }
  }

  if (!categories.contains(selectedCategory)) {
    selectedCategory = categories.first;
    print('⚠️ No matching category. Defaulting to: $selectedCategory');
  }

  print('✔️ Selected category after normalization: $selectedCategory');

  DateTime selectedDate;
  try {
    selectedDate = DateTime.parse(expense['date']);
  } catch (e) {
    print('❌ Error parsing date: $e');
    selectedDate = DateTime.now();
  }

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          print('📦 Building edit expense dialog for: $selectedCategory');
          return AlertDialog(
            title: const Text('Edit Expense'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((String category) {
                        print('🔽 Dropdown item: $category (selected: $selectedCategory)');
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          print('📌 Category changed to: $value');
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\$)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
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
                        const Text('Date:'),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                    final cleanBudgetId = widget.budgetId.toString().trim();
                    final cleanExpenseId = expense['_id'].toString().trim();

                    final body = {
                      'category': selectedCategory,
                      'amount': double.parse(amountController.text),
                      'date': selectedDate.toIso8601String(),
                      'notes': notesController.text,
                    };

                    final url = '$baseUrl/budget/$cleanBudgetId/expense/$cleanExpenseId';
                    print('⬆️ PUT request to: $url');
                    print('📤 Body: $body');

                    try {
                      final response = await http.put(
                        Uri.parse(url),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode(body),
                      );

                      print('⬇️ Response status: ${response.statusCode}');
                      print('⬇️ Response body: ${response.body}');

                      if (response.statusCode == 200) {
                        Navigator.pop(context);
                        fetchBudgetDetails();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense updated successfully')),
                        );
                      } else {
                        throw Exception('Failed to update expense: ${response.body}');
                      }
                    } catch (e) {
                      print('❌ PUT request error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _deleteExpense(String expenseId) async {
  print('Attempting to delete expense with ID: $expenseId');
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                // Make sure the URL matches exactly what your backend expects
                final url = '$baseUrl/budget/${widget.budgetId}/expense/$expenseId';
                print('Delete URL: $url');
                
                // Use the DELETE method
                final response = await http.delete(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                );

                print('Delete response status: ${response.statusCode}');
                print('Delete response body: ${response.body}');

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  fetchBudgetDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted successfully')),
                  );
                } else {
                  // Check if there's an error message in the response
                  Map<String, dynamic> responseData = {};
                  try {
                    responseData = json.decode(response.body);
                  } catch (e) {
                    // Not valid JSON, ignore
                  }
                  
                  String errorMsg = responseData['message'] ?? 'Failed to delete expense';
                  throw Exception('$errorMsg (Status: ${response.statusCode})');
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

  Future<void> _linkPaidBooking() async {
    print('Available paid bookings: ${paidBookings.length}');

    if (paidBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paid bookings available to link')),
      );
      return;
    }

    // Print the linked bookings data
    print('Current linked bookings: ${budgetData['linkedBookings']}');

    // Filter out only paid bookings that haven't been linked yet
    List<dynamic> availableBookings = [];
    for (var booking in paidBookings) {
      bool alreadyLinked = false;
      if (budgetData.containsKey('linkedBookings')) {
        for (var linkedBooking in budgetData['linkedBookings'] ?? []) {
          if (linkedBooking['paidId'] == booking['_id']) {
            alreadyLinked = true;
            break;
          }
        }
      }
      if (!alreadyLinked) {
        availableBookings.add(booking);
      }
    }

    if (availableBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your paid bookings are already linked')),
      );
      return;
    }

    Map<String, dynamic>? selectedBooking;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Link Hotel Booking'),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableBookings.length,
                  itemBuilder: (context, index) {
                    final booking = availableBookings[index];
                    return RadioListTile<Map<String, dynamic>>(
                      title: Text(booking['hotelName']),
                      subtitle: Text('\$${booking['price'].toStringAsFixed(2)} - ${booking['dateRange']}'),
                      value: booking,
                      groupValue: selectedBooking,
                      onChanged: (value) {
                        setState(() {
                          selectedBooking = value;
                        });
                      },
                    );
                  },
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
                  onPressed: selectedBooking == null ? null : () async {
                    try {
                      final response = await _httpRequest('POST', '$baseUrl/budget/${widget.budgetId}/link-paid',
                        body: {
                          'paidId': selectedBooking!['_id'],
                        });

                      if (response.statusCode == 200) {
                        Navigator.pop(context);
                        fetchBudgetDetails();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hotel booking linked successfully')),
                        );
                        
                        // Add an expense for the hotel booking
                        // final bookingDate = DateTime.now();
                        // final expenseResponse = await http.post(
                        //   Uri.parse('$baseUrl/budget/${widget.budgetId}/expense'),
                        //   headers: {'Content-Type': 'application/json'},
                        //   body: json.encode({
                        //     'category': 'Hotel',
                        //     'amount': selectedBooking!['price'],
                        //     'date': bookingDate.toIso8601String(),
                        //     'notes': 'Hotel: ${selectedBooking!['hotelName']} (Auto-added from bookings)',
                        //   }),
                        // );
                        
                        // if (expenseResponse.statusCode == 201) {
                        //   fetchBudgetDetails();
                        // }
                      } else {
                        throw Exception('Failed to link booking: ${response.body}');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Link Hotel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySummary() {
    final categoryTotals = _calculateCategoryTotals();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...categoryTotals.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_calculateTotalSpent().toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedBookings() {
    if (budgetData['linkedBookings'] == null || budgetData['linkedBookings'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Linked Hotel Bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgetData['linkedBookings'].length,
              itemBuilder: (context, index) {
                final linkedBooking = budgetData['linkedBookings'][index];
                final booking = paidBookings.firstWhere(
                  (element) => element['_id'] == linkedBooking['paidId'],
                  orElse: () => {'hotelName': 'Unknown', 'price': 0, 'dateRange': ''},
                );
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['hotelName'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(booking['dateRange']),
                          ],
                        ),
                      ),
                      Text(
                        '\$${booking['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        backgroundColor: Colors.blue,
        actions: [
          // Make the report button more prominent
          IconButton(
            icon: const Icon(Icons.summarize, size: 28), // Larger icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesReport(
                    budgetData: budgetData,
                    expenses: expenses,
                  ),
                ),
              );
            },
            tooltip: 'Generate Report',
          ),
          IconButton(
            icon: const Icon(Icons.hotel),
            onPressed: _linkPaidBooking,
            tooltip: 'Link Hotel Booking',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchBudgetDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Budget Header
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
                                    budgetData['tripName'] ?? 'Trip Budget',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${budgetData['totalBudget']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatDate(budgetData['startDate'])} - ${_formatDate(budgetData['endDate'])}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Budget Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: budgetData['totalBudget'] > 0
                                  ? (_calculateTotalSpent() / budgetData['totalBudget']).clamp(0.0, 1.0)
                                  : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _calculateTotalSpent() > budgetData['totalBudget'] ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent: \$${_calculateTotalSpent().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _calculateTotalSpent() > budgetData['totalBudget'] ? Colors.red : null,
                                  ),
                                ),
                                Text(
                                  'Remaining: \$${(budgetData['totalBudget'] - _calculateTotalSpent()).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _calculateTotalSpent() > budgetData['totalBudget'] ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Summary Card
                    _buildCategorySummary(),
                    
                    // Linked Hotel Bookings Card
                    _buildLinkedBookings(),
                    
                    const SizedBox(height: 16),
                    
                    // Expenses List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${expenses.length} ${expenses.length == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Expenses List
                    expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 24),
                                Icon(Icons.receipt_long, size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first expense by clicking the + button',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(expense['category']),
                                      Text(
                                        '\$${double.parse(expense['amount'].toString()).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatDateFromTimestamp(expense['date'])),
                                      if (expense['notes'] != null && expense['notes'].isNotEmpty)
                                        Text(
                                          expense['notes'],
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _editExpense(expense),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteExpense(expense['_id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}