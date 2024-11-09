import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MonthlyGoalScreen extends StatefulWidget {
  const MonthlyGoalScreen({super.key});

  @override
  _MonthlyGoalScreenState createState() => _MonthlyGoalScreenState();
}

class _MonthlyGoalScreenState extends State<MonthlyGoalScreen> {
  double _monthlyGoal = 0.0;
  double _currentSpending = 0.0;
  final TextEditingController _goalController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _previousMonthsData = [];

  @override
  void initState() {
    super.initState();
    _fetchMonthlyGoal();
    _fetchCurrentSpending();
    _fetchPastMonthsData();
  }

  Future<void> _fetchMonthlyGoal() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        String currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
        double goal = userDoc['monthlyGoal'][currentMonthKey] ?? 2000.0;
        setState(() {
          _monthlyGoal = goal;
        });
      }
    }
  }

  Future<void> _fetchCurrentSpending() async {
  User? currentUser = _auth.currentUser;
  if (currentUser != null) {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final expensesSnapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: _firestore.doc('users/${currentUser.uid}'))
        .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
        .where('date', isLessThanOrEqualTo: lastDayOfMonth)
        .get();

    double totalSpent = 0.0;
    for (var doc in expensesSnapshot.docs) {
      bool isReceived = doc['isReceived'] ?? false;
      double amount = doc['amount'] ?? 0.0;
      if (isReceived) {
        totalSpent -= amount;
      } else {
        totalSpent += amount;
      }
    }

    setState(() {
      _currentSpending = totalSpent;
    });
  }
}

  Future<void> _fetchPastMonthsData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> pastMonths = [];

      for (int i = 1; i <= 2; i++) {
        DateTime monthDate = DateTime(now.year, now.month - i, 1);
        DateTime firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
        DateTime lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

        final expensesSnapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: _firestore.doc('users/${currentUser.uid}'))
            .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
            .where('date', isLessThanOrEqualTo: lastDayOfMonth)
            .get();

        double totalSpent = 0.0;
        for (var doc in expensesSnapshot.docs) {
          totalSpent += doc['amount'] ?? 0.0;
        }

        double goal = await _getMonthlyGoalForMonth(monthDate);
        double spendingProgress = totalSpent / goal;
        
        pastMonths.add({
          'month': DateFormat('MMMM yyyy').format(monthDate),
          'goal': goal,
          'spent': totalSpent,
          'percent': (spendingProgress * 100).toStringAsFixed(1),
        });
      }

      setState(() {
        _previousMonthsData = pastMonths;
      });
    }
  }

  Future<double> _getMonthlyGoalForMonth(DateTime monthDate) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        var monthlyGoalData = userDoc['monthlyGoal'] ?? {};
        return monthlyGoalData[DateFormat('yyyy-MM').format(monthDate)] ?? _monthlyGoal;
      }
    }
    return _monthlyGoal;
  }

  Future<void> _saveMonthlyGoal(double goal) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
      await _firestore.collection('users').doc(currentUser.uid).update({
        'monthlyGoal.$currentMonthKey': goal,
      });
      setState(() {
        _monthlyGoal = goal;
      });
      _fetchPastMonthsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double spendingProgress = _currentSpending / _monthlyGoal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Goal'),
        backgroundColor: Colors.yellow[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track Your Monthly Spending Goal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Goal:', style: TextStyle(fontSize: 18)),
                  Text('₹${_monthlyGoal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spent so far:', style: TextStyle(fontSize: 18)),
                  Text('₹${_currentSpending.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: spendingProgress <= 1 ? spendingProgress : 1,
                  color: spendingProgress > 1 ? Colors.red : Colors.green,
                  backgroundColor: Colors.yellow[100],
                  minHeight: 15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(spendingProgress * 100).toStringAsFixed(1)}% of your goal used',
                style: TextStyle(
                  fontSize: 16,
                  color: spendingProgress > 1 ? Colors.red : Colors.black,
                  fontWeight: spendingProgress > 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _showSetGoalDialog,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Set/Update Monthly Goal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  backgroundColor: Colors.yellow[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.yellow[200],
                  elevation: 6,
                ),
              ),
              const SizedBox(height: 30),
              Column(
                children: _previousMonthsData.map((monthData) {
                  double spendingProgressPastMonth =
                      monthData['spent'] / monthData['goal'];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthData['month'],
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Goal:', style: TextStyle(fontSize: 16)),
                              Text(
                                '₹${monthData['goal'].toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Spent:', style: TextStyle(fontSize: 16)),
                              Text(
                                '₹${monthData['spent'].toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: spendingProgressPastMonth <= 1
                                  ? spendingProgressPastMonth
                                  : 1,
                              color: spendingProgressPastMonth > 1
                                  ? Colors.red
                                  : Colors.green,
                              backgroundColor: Colors.yellow[100],
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${monthData['percent']}% of goal used',
                            style: TextStyle(
                              fontSize: 14,
                              color: spendingProgressPastMonth > 1
                                  ? Colors.red
                                  : Colors.black,
                              fontWeight: spendingProgressPastMonth > 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetGoalDialog() {
    _goalController.text = _monthlyGoal.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Monthly Goal'),
          content: TextField(
            controller: _goalController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: "Enter new monthly goal"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () {
                double newGoal = double.tryParse(_goalController.text) ?? 0.0;
                _saveMonthlyGoal(newGoal);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }
}
