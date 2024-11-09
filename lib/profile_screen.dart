import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatefulWidget {
  final double averageMonthlySpends;

  const ProfileScreen({super.key, required this.averageMonthlySpends});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? username;
  String? email;

  String selectedTimeframe = 'Yearly';
  int selectedYear = DateTime.now().year;
  int? selectedMonth;

  List<PieChartSectionData> sentReceivedData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchChartData();
  }

  Future<void> _fetchUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      setState(() {
        username = snapshot.data()?['username'];
        email = snapshot.data()?['email'];
      });
    }
  }

  Future<void> _fetchChartData() async {
    setState(() => isLoading = true);

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DocumentReference userRef = _firestore.collection('users').doc(uid);
    Query query = _firestore.collection('expenses').where('userId', isEqualTo: userRef);

    if (selectedTimeframe == 'Yearly') {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(selectedYear, 1, 1)))
                   .where('date', isLessThan: Timestamp.fromDate(DateTime(selectedYear + 1, 1, 1)));
    } else if (selectedTimeframe == 'Monthly' && selectedMonth != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(selectedYear, selectedMonth!, 1)))
                   .where('date', isLessThan: Timestamp.fromDate(DateTime(selectedYear, selectedMonth! + 1, 1)));
    }

    try {
      final querySnapshot = await query.get();

      double totalSent = 0;
      double totalReceived = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data != null && data is Map<String, dynamic>) {
          final amount = (data['amount'] ?? 0).toDouble();
          final isReceived = data['isReceived'] ?? false;

          if (isReceived) {
            totalReceived += amount;
          } else {
            totalSent += amount;
          }
        }
      }

      setState(() {
        sentReceivedData = [
          if (totalSent > 0)
            PieChartSectionData(
              value: totalSent,
              color: Colors.red,
              title: '₹${totalSent.toStringAsFixed(2)}',
              radius: 100,
            ),
          if (totalReceived > 0)
            PieChartSectionData(
              value: totalReceived,
              color: Colors.green,
              title: '₹${totalReceived.toStringAsFixed(2)}',
              radius: 100,
            ),
          if (totalSent == 0 && totalReceived == 0)
            PieChartSectionData(
              value: 1,
              color: Colors.grey,
              title: 'No Data',
              radius: 100,
            ),
        ];
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching chart data: $e");
      setState(() => isLoading = false);
    }
  }

Widget _buildUserInfoTile() {
  return Card(
    color: Colors.yellow[50],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center( 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(
              'Username: ${username ?? 'N/A'}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${email ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatisticsFilters() {
    return Center(
      child: Column(
        children: [
          DropdownButton<String>(
            value: selectedTimeframe,
            style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
            items: ['Yearly', 'Monthly'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              selectedTimeframe = value!;
              selectedMonth = null;
              _fetchChartData();
            }),
          ),
          const SizedBox(height: 10),
          if (selectedTimeframe == 'Yearly')
            DropdownButton<int>(
              value: selectedYear,
              style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
              items: List.generate(10, (index) => DateTime.now().year - index)
                  .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedYear = value!;
                _fetchChartData();
              }),
            ),
          if (selectedTimeframe == 'Monthly')
            DropdownButton<int>(
              value: selectedMonth,
              style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
              items: List.generate(12, (index) => index + 1)
                  .map((month) => DropdownMenuItem(value: month, child: Text('$month')))
                  .toList(),
              onChanged: (value) => setState(() {
                selectedMonth = value;
                _fetchChartData();
              }),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.yellow[600],
        iconTheme: const IconThemeData(color: Colors.black),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserInfoTile(),
              const SizedBox(height: 20),
              _buildStatisticsFilters(),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.yellow[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Sent vs Received',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellow[800]),
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? Center(child: CircularProgressIndicator(color: Colors.yellow[800]))
                          : SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  sections: sentReceivedData,
                                  borderData: FlBorderData(show: false),
                                  centerSpaceRadius: 0,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 5),
                          const Text('Received'),
                          const SizedBox(width: 20),
                          Container(
                            width: 20,
                            height: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 5),
                          const Text('Sent'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}