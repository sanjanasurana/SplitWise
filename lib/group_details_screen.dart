import 'package:flutter/material.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupName;
  final List<String> members;
  final Map<String, double> balances;

  const GroupDetailsScreen({
    Key? key,
    required this.groupName,
    required this.members,
    required this.balances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Balances:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final balance = balances[member] ?? 0.0;
                  return ListTile(
                    title: Text(member),
                    subtitle: Text(
                      balance >= 0
                          ? 'Receives: ₹${balance.toStringAsFixed(2)}'
                          : 'Owes: ₹${(-balance).toStringAsFixed(2)}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}