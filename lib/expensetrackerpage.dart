import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({Key? key}) : super(key: key);

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isReceived = false;

  double totalSent = 0;
  double totalReceived = 0;


  void initState(){
    super.initState();
    _calculateTotalSentReceived();
  }
  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      DateTime? parsedDate;
      if (_dateController.text.isNotEmpty) {
        parsedDate = DateFormat.yMMMd().parse(_dateController.text);
      }

      await _firestore.collection('expenses').add({
        'amount': double.parse(_amountController.text),
        'category': _categoryController.text,
        'date': Timestamp.fromDate(parsedDate ?? DateTime.now()),
        'isReceived': _isReceived,
        'userId': _firestore.doc('users/${currentUser.uid}'),
      });

      _amountController.clear();
      _categoryController.clear();
      _dateController.clear();
      _calculateTotalSentReceived();
    }
  }

  Future<void> _editExpense(String expenseId, Map<String, dynamic> data) async {
  _amountController.text = data['amount'].toString();
  _categoryController.text = data['category'];
  _dateController.text = DateFormat.yMMMd().format((data['date'] as Timestamp).toDate());
  _isReceived = data['isReceived'];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Edit Expense'),
      content: SingleChildScrollView( 
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: _buildExpenseForm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _clearFields();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[600],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            _updateExpense(expenseId);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  
  Future<void> _updateExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'amount': double.parse(_amountController.text),
      'category': _categoryController.text,
      'date': Timestamp.fromDate(DateFormat.yMMMd().parse(_dateController.text)),
      'isReceived': _isReceived,
    });

    _clearFields();
    _calculateTotalSentReceived();
  }

  Future<void> _deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
    _calculateTotalSentReceived();
  }

  Future<void> _showAddExpenseDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Add Expense'),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildExpenseForm(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearFields();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _addExpense();
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _amountController.clear();
    _categoryController.clear();
    _dateController.clear();
    _calculateTotalSentReceived();
  }

  Future<void> _calculateTotalSentReceived() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final snapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: _firestore.doc('users/${currentUser.uid}'))
        .get();

    double sent = 0;
    double received = 0;

    for (var expense in snapshot.docs) {
      final data = expense.data();
      if (data['isReceived']) {
        received += data['amount'];
      } else {
        sent += data['amount'];
      }
    }

    setState(() {
      totalSent = sent;
      totalReceived = received;
    });
  }

  Widget _buildExpenseForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
          readOnly: true,
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              _dateController.text = DateFormat.yMMMd().format(pickedDate);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transaction Type:'),
            DropdownButton<bool>(
              value: _isReceived,
              items: const [
                DropdownMenuItem(value: false, child: Text('Sent')),
                DropdownMenuItem(value: true, child: Text('Received')),
              ],
              onChanged: (value) {
                setState(() {
                  _isReceived = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.yellow[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Sent',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.red),
                      ),
                      Text(
                        '₹${totalSent.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Received',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.green),
                      ),
                      Text(
                        '₹${totalReceived.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        '₹${(totalReceived - totalSent).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: (totalReceived - totalSent) >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: _showAddExpenseDialog,
              child: const Text('Add Expense'),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildExpenseList()),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('expenses')
          .where('userId', isEqualTo: _firestore.doc('users/${_auth.currentUser?.uid}'))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data!.docs;

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final data = expense.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.purple),
                        onPressed: () => _editExpense(expense.id, data),
                        iconSize: 17,
                      ),
                      const SizedBox(height: 1),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExpense(expense.id),
                        iconSize: 17,
                      ),
                    ],
                  ),
                  const SizedBox(width: 0),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow.shade600),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['category'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                DateFormat.yMMMd().format((data['date'] as Timestamp).toDate()),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '₹${data['amount']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: data['isReceived'] ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                data['isReceived'] ? Icons.arrow_downward : Icons.arrow_upward,
                                color: data['isReceived'] ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
