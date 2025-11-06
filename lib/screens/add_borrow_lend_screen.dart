import 'package:flutter/material.dart';
import '../data/repositories/borrow_lend_repository_impl.dart';
import '../domain/usecases/add_borrow_lend.dart';
import '../presentation/widgets/borrow_lend_form_fields.dart';
import '../models/borrow_lend.dart';
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
  final _addBorrowLend = AddBorrowLend(
    BorrowLendRepositoryImpl(),
    CloudSyncService(),
  );

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
    if (!mounted) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = BorrowLend(
      personName: _personNameController.text.trim(),
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _selectedType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    try {
      await _addBorrowLend.call(transaction);
      final isSignedIn = await _addBorrowLend.cloudSync.isSignedIn();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSignedIn
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
    } catch (e) {
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
        Navigator.pop(context, true);
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
        child: BorrowLendFormFields(
          formKey: _formKey,
          personNameController: _personNameController,
          amountController: _amountController,
          descriptionController: _descriptionController,
          selectedType: _selectedType,
          onTypeChanged: (value) {
            setState(() {
              _selectedType = value;
            });
          },
          selectedDate: _selectedDate,
          onSelectDate: _selectDate,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTransaction,
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.save),
        label: const Text('Save Transaction'),
      ),
    );
  }
}
