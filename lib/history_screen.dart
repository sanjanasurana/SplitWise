import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<Transaction> transactions = [
    Transaction(description: 'Pentagon Brunch', amount: 130.00, date: 'Oct 30', type: TransactionType.sent),
    Transaction(description: 'Grocery Shopping', amount: 190.00, date: 'Oct 28', type: TransactionType.sent),
    Transaction(description: 'Diwali Shopping', amount: 500.00, date: 'Oct 27', type: TransactionType.received),
    Transaction(description: 'Cafe', amount: 200.00, date: 'Oct 25', type: TransactionType.sent),
    Transaction(description: 'Diwali Gift', amount: 300.00, date: 'Oct 20', type: TransactionType.received),
  ];

   HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.yellow[600],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return TransactionRecord(transaction: transaction);
        },
      ),
    );
  }
}

enum TransactionType { sent, received }

class Transaction {
  final String description;
  final double amount;
  final String date;
  final TransactionType type;

  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}

class TransactionRecord extends StatelessWidget {
  final Transaction transaction;

  const TransactionRecord({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                transaction.description,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: transaction.type == TransactionType.received ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                transaction.type == TransactionType.received ? Icons.arrow_downward : Icons.arrow_upward,
                color: transaction.type == TransactionType.received ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
