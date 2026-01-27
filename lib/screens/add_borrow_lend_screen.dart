import 'package:flutter/material.dart';
import '../data/repositories/borrow_lend_repository_impl.dart';
import '../domain/usecases/add_borrow_lend.dart';
import '../domain/usecases/update_borrow_lend.dart';
import '../presentation/widgets/borrow_lend_form_fields.dart';
import '../models/borrow_lend.dart';
import '../services/cloud_sync_service.dart';

class AddBorrowLendScreen extends StatefulWidget {
  final BorrowLend? transaction;

  const AddBorrowLendScreen({super.key, this.transaction});

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
  final _updateBorrowLend = UpdateBorrowLend(
    BorrowLendRepositoryImpl(),
    CloudSyncService(),
  );

  String _selectedType = 'borrow';
  DateTime _selectedDate = DateTime.now();
  late final bool _isEditing;

  @override
  void dispose() {
    _personNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaction != null;

    if (_isEditing) {
      final transaction = widget.transaction!;
      _personNameController.text = transaction.personName;
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.description ?? '';
      _selectedType = transaction.type;
      _selectedDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
    }
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
      id: widget.transaction?.id,
      personName: _personNameController.text.trim(),
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _selectedType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    try {
      if (_isEditing) {
        await _updateBorrowLend.call(transaction);
      } else {
        await _addBorrowLend.call(transaction);
      }
      final isSignedIn = _isEditing
          ? await _updateBorrowLend.cloudSync.isSignedIn()
          : await _addBorrowLend.cloudSync.isSignedIn();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? (isSignedIn
                      ? 'Transaction updated and synced to cloud!'
                      : 'Transaction updated successfully!')
                  : (isSignedIn
                      ? (_selectedType == 'borrow'
                          ? 'Borrowed money added and synced to cloud!'
                          : 'Lent money added and synced to cloud!')
                      : (_selectedType == 'borrow'
                          ? 'Borrowed money added!'
                          : 'Lent money added!')),
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
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
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
        label: Text(_isEditing ? 'Update Transaction' : 'Save Transaction'),
      ),
    );
  }
}
