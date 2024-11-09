import 'package:flutter/material.dart';

class PastGroupsScreen extends StatelessWidget {
  PastGroupsScreen({super.key});
  final List<Map<String, String>> pastGroups = [
    {
      'groupName': 'Friends Gathering',
      'date': '2024-10-05',
    },
    {
      'groupName': 'Work Project Team',
      'date': '2024-09-15',
    },
    {
      'groupName': 'Family Trip',
      'date': '2024-08-20',
    },
    {
      'groupName': 'Book Club',
      'date': '2024-07-10',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Groups'),
        backgroundColor: Colors.yellow[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: pastGroups.length,
          itemBuilder: (context, index) {
            return _buildGroupTile(pastGroups[index]);
          },
        ),
      ),
    );
  }

  Widget _buildGroupTile(Map<String, String> group) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: ListTile(
        title: Text(
          group['groupName'] ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Date: ${group['date'] ?? ''}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          color: Colors.yellow[600],
          onPressed: () {
          },
        ),
      ),
    );
  }
}
