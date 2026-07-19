import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BorrowLendFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController personNameController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final DateTime selectedDate;
  final VoidCallback onSelectDate;

  const BorrowLendFormFields({
    super.key,
    required this.formKey,
    required this.personNameController,
    required this.amountController,
    required this.descriptionController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeChanged('borrow'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedType == 'borrow'
                            ? Colors.red.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedType == 'borrow'
                              ? Colors.red.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: selectedType == 'borrow'
                                ? Colors.red.shade700
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You Owe',
                            style: TextStyle(
                              fontWeight: selectedType == 'borrow'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedType == 'borrow'
                                  ? Colors.red.shade700
                                  : Colors.grey,
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
                    onTap: () => onTypeChanged('lend'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedType == 'lend'
                            ? Colors.green.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedType == 'lend'
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: selectedType == 'lend'
                                ? Colors.green.shade700
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Owed to You',
                            style: TextStyle(
                              fontWeight: selectedType == 'lend'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedType == 'lend'
                                  ? Colors.green.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: personNameController,
            decoration: const InputDecoration(
              labelText: 'Person Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a person name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onSelectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

