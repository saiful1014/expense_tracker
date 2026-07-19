import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/domain/usecases/add_expense.dart';
import 'package:test_new_things/domain/usecases/update_expense.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_form_fields.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';

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
  late final AddExpense _addExpense;
  late final UpdateExpense _updateExpense;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repository = context.read<ExpenseRepository>();
      final cloudSync = context.read<CloudSyncService>();
      _addExpense = AddExpense(repository, cloudSync);
      _updateExpense = UpdateExpense(repository, cloudSync);
      _initialized = true;
    }
  }
  
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late final bool _isEditing;
  bool _isRecurring = false;
  String _recurrenceInterval = 'monthly';

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
      _isRecurring = expense.isRecurring;
      _recurrenceInterval = expense.recurrenceInterval ?? 'monthly';
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

  bool _isSaving = false;

  Future<void> _saveExpense() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

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
      isRecurring: _isRecurring,
      recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
      lastProcessed: _isRecurring ? (widget.expense?.lastProcessed ?? DateTime.now()) : null,
    );

    try {
      if (_isEditing) {
        await _updateExpense.call(expense);
      } else {
        await _addExpense.call(expense);
      }

      final hasInternet = await ConnectivityService.instance.hasInternetConnection();
      final isSignedIn = _isEditing
          ? await _updateExpense.cloudSync.isSignedIn()
          : await _addExpense.cloudSync.isSignedIn();
      
      if (mounted) {
        context.pop(true);

        final String message;
        if (isSignedIn && hasInternet) {
          message = _isEditing
              ? 'Expense updated and synced to cloud!'
              : 'Expense added and synced to cloud!';
        } else if (isSignedIn && !hasInternet) {
          message = _isEditing
              ? 'Expense updated locally. Will sync when online.'
              : 'Expense added locally. Will sync when online.';
        } else {
          message = _isEditing
              ? 'Expense updated successfully!'
              : 'Expense added successfully!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          isRecurring: _isRecurring,
          recurrenceInterval: _recurrenceInterval,
          onRecurringChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
          onIntervalChanged: (value) {
            setState(() {
              _recurrenceInterval = value;
            });
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveExpense,
        backgroundColor: _isSaving ? Colors.grey : Colors.blue.shade700,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving
            ? 'Saving...'
            : (_isEditing ? 'Update Expense' : 'Save Expense')),
      ),
    );
  }
}
