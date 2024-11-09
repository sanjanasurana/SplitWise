import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<DateTime, double> _expenseDays = {};

  @override
  void initState() {
    super.initState();
    _fetchExpenseDays(_focusedDay);
  }

  Future<void> _fetchExpenseDays(DateTime month) async {
    Map<DateTime, double> expenseDays = {};

    QuerySnapshot querySnapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: DateTime(month.year, month.month))
        .where('date', isLessThan: DateTime(month.year, month.month + 1))
        .get();

    for (var doc in querySnapshot.docs) {
      DateTime expenseDate = (doc['date'] as Timestamp).toDate();
      double expenseAmount = doc['amount'].toDouble();

      DateTime formattedDate = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
      expenseDays[formattedDate] = (expenseDays[formattedDate] ?? 0) + expenseAmount;
    }

    setState(() {
      _expenseDays = expenseDays;
    });
  }

  Future<double> _calculateMonthlyExpense(DateTime month) async {
    double total = 0.0;
    QuerySnapshot querySnapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: DateTime(month.year, month.month))
        .where('date', isLessThan: DateTime(month.year, month.month + 1))
        .get();

    for (var doc in querySnapshot.docs) {
      double amount = doc['amount'];
      bool isReceived = doc['isReceived'];
      total += isReceived ? amount : -amount;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> _getTransactionsForDay(DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot querySnapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    return querySnapshot.docs.map((doc) => {
          'category': doc['category'],
          'amount': doc['amount'],
          'date': (doc['date'] as Timestamp).toDate(),
          'isReceived': doc['isReceived'],
        }).toList();
  }

  Future<List<Map<String, dynamic>>> _getTransactionsForMonth(DateTime month) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: DateTime(month.year, month.month))
        .where('date', isLessThan: DateTime(month.year, month.month + 1))
        .get();

    return querySnapshot.docs.map((doc) => {
          'category': doc['category'],
          'amount': doc['amount'],
          'date': (doc['date'] as Timestamp).toDate(),
          'isReceived': doc['isReceived'],
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Colors.yellow[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'en_US',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = null;
              });
              _fetchExpenseDays(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.yellow[200],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.yellow[600],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, _) {
                double expenseAmount = _expenseDays[DateTime(date.year, date.month, date.day)] ?? 0.0;

                if (expenseAmount > 0) {
                  double circleSize = (expenseAmount / 100.0).clamp(15.0, 40.0);

                  return Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<double>(
            future: _calculateMonthlyExpense(_focusedDay),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return _selectedDay != null
                  ? Text(
                      'Transactions on ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'Monthly Expense for ${_focusedDay.month}/${_focusedDay.year}: ₹${snapshot.data!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedDay != null
                ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getTransactionsForDay(_selectedDay!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final transactions = snapshot.data!;
                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionTile(transactions[index]);
                        },
                      );
                    },
                  )
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getTransactionsForMonth(_focusedDay),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final transactions = snapshot.data!;
                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          return _buildTransactionTile(transactions[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    bool isReceived = transaction['isReceived'];
    return ListTile(
      leading: Icon(
        isReceived ? Icons.arrow_downward : Icons.arrow_upward,
        color: isReceived ? Colors.green : Colors.red,
      ),
      title: Text(transaction['category']),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(transaction['date'])),
      trailing: Text(
        '₹${transaction['amount'].toStringAsFixed(2)}',
        style: TextStyle(
          color: isReceived ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}