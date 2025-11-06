import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/borrow_lend.dart';
import '../database/database_helper.dart';
import '../services/cloud_sync_service.dart';

class AddBorrowLendScreen extends StatefulWidget {
  const AddBorrowLendScreen({super.key});

  @override
  State<AddBorrowLendScreen> createState() => _AddBorrowLendScreenState();
}

class _AddBorrowLendScreenState extends State<AddBorrowLendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();

  String _selectedType = 'borrow';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = BorrowLend(
        personName: _personNameController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Save to local database (initially unsynced)
      final transactionId = await _dbHelper.insertBorrowLend(transaction);
      
      // Update transaction with the ID from database
      final savedTransaction = BorrowLend(
        id: transactionId,
        personName: transaction.personName,
        amount: transaction.amount,
        date: transaction.date,
        type: transaction.type,
        description: transaction.description,
        synced: false, // Initially unsynced
      );

      // Sync to cloud if signed in
      final isSignedIn = await _cloudSync.isSignedIn();
      bool syncSuccess = false;
      if (isSignedIn) {
        try {
          await _cloudSync.syncBorrowLendToCloud(savedTransaction);
          // Mark as synced in database
          await _dbHelper.markBorrowLendAsSynced(transactionId);
          syncSuccess = true;
        } catch (e) {
          debugPrint('Cloud sync error: $e');
          // Transaction remains unsynced, will be synced later when online
          if (mounted) {
            final errorMessage = e.toString().contains('No internet connection')
                ? 'No internet connection. Will sync when online.'
                : 'Failed to sync to cloud. Will sync when online.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSignedIn && syncSuccess
                  ? (_selectedType == 'borrow'
                      ? 'Borrowed money added and synced to cloud!'
                      : 'Lent money added and synced to cloud!')
                  : (_selectedType == 'borrow'
                      ? 'Borrowed money added!'
                      : 'Lent money added!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'borrow';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedType == 'borrow'
                                    ? Colors.red.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedType == 'borrow'
                                      ? Colors.red.shade400
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: _selectedType == 'borrow'
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You Owe',
                                    style: TextStyle(
                                      fontWeight: _selectedType == 'borrow'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedType == 'borrow'
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = 'lend';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedType == 'lend'
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedType == 'lend'
                                      ? Colors.green.shade400
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: _selectedType == 'lend'
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Owed to You',
                                    style: TextStyle(
                                      fontWeight: _selectedType == 'lend'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedType == 'lend'
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Person Name Field
              TextFormField(
                controller: _personNameController,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  hintText: 'Enter person name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter person name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Description Field (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a note',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

