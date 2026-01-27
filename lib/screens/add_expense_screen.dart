import 'package:flutter/material.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../domain/usecases/add_expense.dart';
import '../domain/usecases/update_expense.dart';
import '../presentation/widgets/expense_form_fields.dart';
import '../models/expense.dart';
import '../services/cloud_sync_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _addExpense = AddExpense(
    ExpenseRepositoryImpl(),
    CloudSyncService(),
  );
  final _updateExpense = UpdateExpense(
    ExpenseRepositoryImpl(),
    CloudSyncService(),
  );
  
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late final bool _isEditing;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.expense != null;

    if (_isEditing) {
      final expense = widget.expense!;
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedCategory = expense.category;
      _selectedDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      _selectedTime = TimeOfDay(
        hour: expense.date.hour,
        minute: expense.date.minute,
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
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

  Future<void> _selectTime() async {
    if (!mounted) return;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final expense = Expense(
      id: widget.expense?.id,
      description: _descriptionController.text.trim(),
      amount: double.parse(_amountController.text),
      date: dateTime,
      category: _selectedCategory,
    );

    try {
      if (_isEditing) {
        await _updateExpense.call(expense);
      } else {
        await _addExpense.call(expense);
      }
      final isSignedIn = _isEditing
          ? await _updateExpense.cloudSync.isSignedIn()
          : await _addExpense.cloudSync.isSignedIn();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? (isSignedIn
                      ? 'Expense updated and synced to cloud!'
                      : 'Expense updated successfully!')
                  : (isSignedIn
                      ? 'Expense added and synced to cloud!'
                      : 'Expense added successfully!'),
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
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ExpenseFormFields(
          formKey: _formKey,
          descriptionController: _descriptionController,
          amountController: _amountController,
          selectedCategory: _selectedCategory,
          categories: _categories,
          onCategoryChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onSelectDate: _selectDate,
          onSelectTime: _selectTime,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveExpense,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.save),
        label: Text(_isEditing ? 'Update Expense' : 'Save Expense'),
      ),
    );
  }
}
