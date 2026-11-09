import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_new_things/ui/core/utils/form_validators.dart';

class ExpenseFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;

  final bool isRecurring;
  final String recurrenceInterval;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onIntervalChanged;

  const ExpenseFormFields({
    super.key,
    required this.formKey,
    required this.descriptionController,
    required this.amountController,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.isRecurring,
    required this.recurrenceInterval,
    required this.onRecurringChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            validator: FormValidators.validateDescription(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: FormValidators.validateAmount(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('$selectedCategory-${categories.length}'),
            initialValue: categories.contains(selectedCategory)
                ? selectedCategory
                : (categories.isNotEmpty ? categories.first : null),
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: onSelectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time_outlined),
                    ),
                    child: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Recurring Subscription'),
            subtitle: const Text('Automatically record this expense periodically'),
            value: isRecurring,
            onChanged: onRecurringChanged,
            secondary: const Icon(Icons.autorenew_outlined),
          ),
          if (isRecurring) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: recurrenceInterval,
              decoration: const InputDecoration(
                labelText: 'Interval',
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) => onIntervalChanged(value!),
            ),
          ],
        ],
      ),
    );
  }
}

