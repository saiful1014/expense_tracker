import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/domain/usecases/add_borrow_lend.dart';
import 'package:test_new_things/domain/usecases/update_borrow_lend.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/borrow_lend_form_fields.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';

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
  late final AddBorrowLend _addBorrowLend;
  late final UpdateBorrowLend _updateBorrowLend;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repository = context.read<BorrowLendRepository>();
      final cloudSync = context.read<CloudSyncService>();
      _addBorrowLend = AddBorrowLend(repository, cloudSync);
      _updateBorrowLend = UpdateBorrowLend(repository, cloudSync);
      _initialized = true;
    }
  }

  String _selectedType = 'borrow';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedDueDate;
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
      _selectedDueDate = transaction.dueDate;
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

  Future<void> _selectDueDate() async {
    if (!mounted) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Select Due Date',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  bool _isSaving = false;

  Future<void> _saveTransaction() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final transaction = BorrowLend(
      id: widget.transaction?.id,
      personName: _personNameController.text.trim(),
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      date: _selectedDate,
      completed: widget.transaction?.completed ?? false,
      repayments: widget.transaction?.repayments ?? const [],
      dueDate: _selectedDueDate,
    );

    try {
      if (_isEditing) {
        await _updateBorrowLend.call(transaction);
      } else {
        await _addBorrowLend.call(transaction);
      }

      final hasInternet = await ConnectivityService.instance.hasInternetConnection();
      final isSignedIn = _isEditing
          ? await _updateBorrowLend.cloudSync.isSignedIn()
          : await _addBorrowLend.cloudSync.isSignedIn();
      
      if (mounted) {
        context.pop(true);

        final String message;
        if (isSignedIn && hasInternet) {
          message = _isEditing
              ? 'Transaction updated and synced to cloud!'
              : 'Transaction added and synced to cloud!';
        } else if (isSignedIn && !hasInternet) {
          message = _isEditing
              ? 'Transaction updated locally. Will sync when online.'
              : 'Transaction added locally. Will sync when online.';
        } else {
          message = _isEditing
              ? (_selectedType == 'borrow'
                  ? 'Borrowed money updated successfully!'
                  : 'Lent money updated successfully!')
              : (_selectedType == 'borrow'
                  ? 'Borrowed money added successfully!'
                  : 'Lent money added successfully!');
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
            content: Text('Failed to save transaction: ${e.toString()}'),
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
          selectedDueDate: _selectedDueDate,
          onSelectDueDate: _selectDueDate,
          onClearDueDate: _clearDueDate,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveTransaction,
        backgroundColor: _isSaving ? Colors.grey : Colors.purple.shade700,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving
            ? 'Saving...'
            : (_isEditing ? 'Update Transaction' : 'Save Transaction')),
      ),
    );
  }
}
