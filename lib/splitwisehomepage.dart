// ignore_for_file: unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SplitwiseHomePage extends StatefulWidget {
  const SplitwiseHomePage({super.key});

  @override
  _SplitwiseHomePageState createState() => _SplitwiseHomePageState();
}

class AddExpenseDialog extends StatefulWidget {
  final String groupId;
  final List<String> members;
  const AddExpenseDialog({Key? key, required this.groupId, required this.members}) : super(key: key);

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPriceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> selectedMembers = [];
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingExpenses();
  }

  Future<void> _fetchExistingExpenses() async {
    try {
      final doc = await _firestore.collection('groups').doc(widget.groupId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('expenses')) {
          items = List<Map<String, dynamic>>.from(data['expenses']);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to fetch existing expenses: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addItem() {
  if (itemNameController.text.isNotEmpty && itemPriceController.text.isNotEmpty) {
    double price = double.tryParse(itemPriceController.text) ?? 0.0;
    
    if (price > 0 && selectedMembers.isNotEmpty) {
      double splitAmount = price / selectedMembers.length;

      items.add({
        'name': itemNameController.text,
        'price': price,
        'members': selectedMembers,
        'splitAmount': splitAmount,
      });

      setState(() {
        itemNameController.clear();
        itemPriceController.clear();
        selectedMembers = [];
      });
    } else {
      Fluttertoast.showToast(msg: "Enter valid item price and members");
    }
  }
}


  Future<void> _saveExpenses() async {
  try {
    await _firestore.collection('groups').doc(widget.groupId).update({
      'expenses': items,
    });
    Map<String, double> memberBalances = _calculateBalances();
    for (var member in memberBalances.keys) {
      await _firestore.collection('groups').doc(widget.groupId).update({
        'balances.$member': memberBalances[member],
      });
    }

    Fluttertoast.showToast(msg: "Expenses added successfully!");
    Navigator.of(context).pop();
  } catch (e) {
    Fluttertoast.showToast(msg: "Failed to save expenses: $e");
  }
}

Map<String, double> _calculateBalances() {
  Map<String, double> memberBalances = {};
  for (var item in items) {
    double splitAmount = item['splitAmount'];

    for (String member in item['members']) {
      if (memberBalances[member] == null) {
        memberBalances[member] = 0.0;
      }
      memberBalances[member] = memberBalances[member]! + splitAmount;
    }
  }
  return memberBalances;
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Center(
        child: Text(
          'Add Item to Split',
          style: TextStyle(
            color: Colors.yellow[800],
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: itemNameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.yellow[800]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: itemPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.yellow[800]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Members for this Item:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.members.map((member) {
                      return ChoiceChip(
                        label: Text(
                          member,
                          style: TextStyle(
                            color: selectedMembers.contains(member) ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: selectedMembers.contains(member),
                        selectedColor: Colors.yellow[800],
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedMembers.add(member)
                                : selectedMembers.remove(member);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800],
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _addItem,
                      child: const Text(
                        'Add Item',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const Divider(),
                  const Text(
                    'Items Added:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Column(
                    children: items.map((item) {
                      return ListTile(
                        title: Text(
                          item['name'],
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Price: \₹${item['price']} | Split among: ${item['members'].join(', ')} | Each pays: \₹${item['splitAmount'].toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                        tileColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        dense: true,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saveExpenses,
          child: const Text(
            'Save Expenses',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailsPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late Map<String, double> balances;
  late List<Map<String, dynamic>> expenses;

  @override
  void initState() {
    super.initState();
    balances = {};
    expenses = [];
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
          balances = Map<String, double>.from(data['balances'] ?? {});
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load group details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.yellow[600],
        elevation: 10,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No details available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildSectionTitle('Balances'),
                const SizedBox(height: 15),
                for (var entry in balances.entries)
                  _buildBalanceTile(entry.key, entry.value),
                const Divider(thickness: 1, color: Colors.grey),

                const SizedBox(height: 30),
                _buildSectionTitle('Expenses'),
                const SizedBox(height: 15),
                if (expenses.isEmpty)
                  const Center(child: Text('No expenses recorded.')),
                for (var expense in expenses)
                  _buildExpenseTile(expense),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.yellow[600],
        ),
      ),
    );
  }

  Widget _buildBalanceTile(String memberName, double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        title: Text(
          memberName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Balance: \₹${balance.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        tileColor: Colors.transparent,
      ),
    );
  }

  Widget _buildExpenseTile(Map<String, dynamic> expense) {
    final price = expense['price'] ?? 0.0;
    final splitAmount = expense['splitAmount'] ?? 0.0;
    final members = expense['members'] ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        title: Text(
          expense['name'],
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price: \₹${price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'Split among: ${members.join(', ')}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'Each pays: \₹${splitAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        tileColor: Colors.transparent,
      ),
    );
  }
}

class GroupEditPage extends StatefulWidget {
  final String groupId;

  const GroupEditPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupEditPageState createState() => _GroupEditPageState();
}

class _GroupEditPageState extends State<GroupEditPage> {
  late List<Map<String, dynamic>> expenses;
  late Map<String, double> balances;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
          balances = Map<String, double>.from(data['balances'] ?? {});
        });
      } else {
        setState(() {
          _errorMessage = 'Group not found.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load group details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGroupDetails() async {
  setState(() {
    _isLoading = true;
  });
  try {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'expenses': expenses,
      'balances': balances,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Group updated successfully')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update group: $e')));
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


    void _updateItem(int index, String name, double price, List<String> members) {
    setState(() {
      expenses[index]['name'] = name;
      expenses[index]['price'] = price;
      expenses[index]['members'] = members;
      expenses[index]['splitAmount'] = price / members.length;

      _recalculateBalances();
    });
    _saveGroupDetails();
  }

  void _recalculateBalances() {
  balances.clear();
  for (var expense in expenses) {
    double splitAmount = expense['splitAmount'];
    for (var member in expense['members']) {
      setState(() {
        balances[member] = (balances[member] ?? 0.0) + splitAmount;
      });
    }
  }
}

void _deleteItem(int index) async {
  try {
    var expenseToDelete = expenses[index];
    double splitAmount = expenseToDelete['splitAmount'] ?? 0.0;
    List<String> members = List<String>.from(expenseToDelete['members'] ?? []);

    setState(() {
      expenses.removeAt(index);
    });

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'expenses': FieldValue.arrayRemove([expenseToDelete]),
    });

    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'balances': {},
    });

    Map<String, double> balances = {};

    for (var expense in expenses) {
      double expenseSplitAmount = expense['splitAmount'] ?? 0.0;
      List<String> expenseMembers = List<String>.from(expense['members'] ?? []);

      for (var member in expenseMembers) {
        balances[member] = (balances[member] ?? 0.0) + expenseSplitAmount;
      }
    }

    for (var entry in balances.entries) {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'balances.${entry.key}': entry.value,
      });
    }

    Fluttertoast.showToast(msg: "Item deleted and balances updated successfully!");
  } catch (e) {
    Fluttertoast.showToast(msg: "Failed to delete item: $e");
  }
}

void _editItemDialog(int index) {
  final item = expenses[index];
  TextEditingController nameController = TextEditingController(text: item['name']);
  TextEditingController priceController = TextEditingController(text: item['price'].toString());
  List<String> selectedMembers = List<String>.from(item['members']);
  
  FirebaseFirestore.instance.collection('groups').doc(widget.groupId).get().then((groupSnapshot) {
    if (groupSnapshot.exists) {
      List<String> allMembers = List<String>.from(groupSnapshot.data()!['members']);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), 
            ),
            title: Text(
              'Edit Item',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[800], 
              ),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: Colors.black), 
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                Text(
                  'Select Members Involved:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.yellow[800],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: allMembers.map((member) {
                    return FilterChip(
                      label: Text(
                        member,
                        style: TextStyle(
                          color: Colors.yellow[800],
                        ),
                      ),
                      selected: selectedMembers.contains(member),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedMembers.add(member);
                          } else {
                            selectedMembers.remove(member);
                          }
                        });
                      },
                      selectedColor: Colors.yellow[600],
                      backgroundColor: Colors.yellow[50],
                      side: BorderSide(color: Colors.yellow[600]!), 
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameController.text;
                  final price = double.tryParse(priceController.text) ?? 0;
                  if (name.isNotEmpty && price > 0 && selectedMembers.isNotEmpty) {
                    _updateItem(index, name, price, selectedMembers);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields correctly')));
                  }
                },
                child: Text(
                  'Save Changes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Group members not found')));
    }
  });
}


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Group'),
        backgroundColor: Colors.yellow[600],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
              : expenses.isEmpty
                  ? Center(child: Text('No expenses added.'))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 5,
                          child: ListTile(
                            title: Text(expense['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price: \₹${expense['price'].toStringAsFixed(2)}'),
                                Text('Members: ${expense['members'].join(', ')}'),
                                Text('Each pays: \₹${expense['splitAmount'].toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editItemDialog(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _SplitwiseHomePageState extends State<SplitwiseHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _currentUserId = '';
  String _currentUserName = '';
  final List<String> _groups = [];
  final List<String> _groupId = [];
  final Map<String, List<String>> _groupMembers = {};
  final Map<String, List<Map<String, dynamic>>> _expenses = {};
  final Map<String, Map<String, double>> _memberBalances = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentUser();
    await _fetchUserGroups();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc['username'];
        });
      }
    }
  }

  Future<void> _fetchUserGroups() async {
    _groups.clear();
    _groupId.clear();
    _groupMembers.clear();
    _expenses.clear();
    _memberBalances.clear();
    if (_currentUserId.isEmpty) return;

    final userGroupsSnapshot = await _firestore
        .collection('groups')
        .where('members', arrayContains: _currentUserName)
        .get();

    setState(() {
      _groups.clear();
      for (var groupDoc in userGroupsSnapshot.docs) {
        _groups.add(groupDoc['group_name']);
        _groupId.add(groupDoc.id);
        _groupMembers[groupDoc.id] = List<String>.from(groupDoc['members']);
        _expenses[groupDoc.id] = List<Map<String, dynamic>>.from(groupDoc['expenses'] ?? []);
        _memberBalances[groupDoc.id] = Map<String, double>.from(groupDoc['balances'] ?? {});
      }
    });
  }

  Future<void> _createGroup() async {
    await showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(validateUser: _validateUser, saveGroupToDatabase: _saveGroupToDatabase,),
    );
    await _fetchUserGroups();
  }

  Future<bool> _validateUser(String username) async {
    final userSnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return userSnapshot.docs.isNotEmpty;
  }

  Future<void> _saveGroupToDatabase(String groupName, List<String> members) async {
    if (_currentUserId.isEmpty) return;

    DocumentReference groupRef = await _firestore.collection('groups').add({
      'group_name': groupName,
      'members': [...members, _currentUserName],
      'expenses': [],
      'balances': {for (var member in members) member: 0.0}
    });

    for (String member in members) {
      final userSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: member)
          .get();

      for (var userDoc in userSnapshot.docs) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'groups': FieldValue.arrayUnion([groupRef.id])
        });
      }
    }

    final currentUserDoc = await _firestore.collection('users').doc(_currentUserId).get();
    if (currentUserDoc.exists) {
      await _firestore.collection('users').doc(_currentUserId).update({
        'groups': FieldValue.arrayUnion([groupRef.id]),
      });
    }
  }

  double _calculateGroupTotal(String groupName) {
    return _expenses[groupName]?.fold(0.0, (sum, item) {
      double amount = item['amount'] ?? 0.0;
      return sum! + amount;
    }) ?? 0.0;
  }


  Future<void> _deleteGroup(String groupId) async {
    try {
      
      final groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
      if (groupSnapshot.exists) {
        List<String> members = List<String>.from(groupSnapshot['members']);
        for (String member in members) {
          final userSnapshot = await _firestore
              .collection('users')
              .where('username', isEqualTo: member)
              .get();
          for (var userDoc in userSnapshot.docs) {
            await _firestore.collection('users').doc(userDoc.id).update({
              'groups': FieldValue.arrayRemove([groupId])
            });
          }
        }
      }

      await _firestore.collection('groups').doc(groupId).delete();
      await _fetchUserGroups();

      Fluttertoast.showToast(
        msg: "Group deleted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete group: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
  
  Future<double> _getUserGroupBalance(String groupId) async {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String username = await _getUsernameFromUserId(userId);

  if (username.isEmpty) {
    return 0.0;
  }

  DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();

  if (groupDoc.exists) {
    Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
    Map<String, double> balances = Map<String, double>.from(data['balances'] ?? {});

    return balances[username] ?? 0.0;
  } else {
    return 0.0;
  }
}

  Future<String> _getUsernameFromUserId(String userId) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (userDoc.exists) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    return userData['username'] ?? '';
  }

  return '';
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitwise'),
        backgroundColor: Colors.yellow[600],
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 15),
              ),
              child: const Text('Create New Group'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Groups:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final groupName = _groups[index];
                  final groupId = _groupId[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 5,
                    child: ListTile(
                      title: Text(groupName),
                      subtitle: FutureBuilder<double>(
                        future: _getUserGroupBalance(groupId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData) {
                            return const Text('Total: \$0');
                          }
                          return Text('Total: \₹${snapshot.data?.toStringAsFixed(2)}');
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupEditPage(groupId: groupId),  // Pass groupId here
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AddExpenseDialog(groupId: groupId, members: _groupMembers[groupId]!),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteGroup(groupId),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailsPage(groupId: groupId, groupName: groupName),
                        ),
                      ),
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

class CreateGroupDialog extends StatefulWidget {
  final Function(String user) validateUser;
  final Function(String groupName, List<String> members) saveGroupToDatabase;
  const CreateGroupDialog({super.key, required this.validateUser, required this.saveGroupToDatabase,});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  TextEditingController groupName = TextEditingController();
          TextEditingController username = TextEditingController();
          List<String> members = [];
          bool userAdded = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Create New Group',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: groupName,
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: username,
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              ),
              onPressed: () async {
                bool isUserValid = await widget.validateUser(username.text);
                if (isUserValid) {
                  bool isUserAlreadyInGroup = members.contains(username.text);
                  if (!isUserAlreadyInGroup) {
                    setState(() {
                      members.add(username.text);
                      userAdded = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User has been added to the group!')),
                    );
                    setState(() {
                      username.clear();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User is already in the group!')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User does not exist!')),
                  );
                }
              },
              child: const Text('Add Member'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: members
                  .map((member) => Chip(
                        label: Text(member),
                        onDeleted: () {
                          setState(() {
                            members.remove(member);
                          });
                        },
                      ))
                  .toList(),
            ),
            if (userAdded)
            FutureBuilder(
              future: Future.delayed(const Duration(seconds: 3), () {
                setState(() {
                  userAdded = false; 
                });
              }),
              builder: (context, snapshot) {
                return Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'The user has been successfully added to the group.',
                    style: TextStyle(color: Colors.green),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.yellow[600]),
          onPressed: () async {
            if (groupName.text.isNotEmpty && members.isNotEmpty) {
              try {
                await widget.saveGroupToDatabase(groupName.text, members);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group created successfully!')),
                );
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating group: $e')),
                );
              }
            }
          },
          child: const Text('Create'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}