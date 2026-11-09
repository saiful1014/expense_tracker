import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/ui/core/utils/expense_utils.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<Map<String, dynamic>> _customCategoriesWithId = [];
  bool _isLoading = true;

  static const List<String> _builtInCategories = [
    'Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final controller = context.read<ExpenseViewModel>();
    final categories = await controller.getCustomCategoriesWithId();
    if (mounted) {
      setState(() {
        _customCategoriesWithId = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Custom Category',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Groceries, Education...',
              prefixIcon: Icon(Icons.label_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Category name cannot be empty';
              }
              final name = value.trim();
              if (_builtInCategories.any((c) => c.toLowerCase() == name.toLowerCase())) {
                return 'This is already a built-in category';
              }
              if (_customCategoriesWithId.any(
                  (c) => (c['name'] as String).toLowerCase() == name.toLowerCase())) {
                return 'This category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final categoryName = textController.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final controller = context.read<ExpenseViewModel>();
                Navigator.pop(context);
                try {
                  await controller.addCustomCategory(categoryName);
                  await _loadCategories();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Category "$categoryName" added'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to add category: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    textController.dispose();
  }

  Future<void> _showEditCategoryDialog(int id, String currentName) async {
    final textController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Category',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Category name cannot be empty';
              }
              final name = value.trim();
              if (name.toLowerCase() == currentName.toLowerCase()) {
                return null; // Same name is fine
              }
              if (_builtInCategories.any((c) => c.toLowerCase() == name.toLowerCase())) {
                return 'This is already a built-in category';
              }
              if (_customCategoriesWithId.any(
                  (c) => (c['name'] as String).toLowerCase() == name.toLowerCase())) {
                return 'This category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newName = textController.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                final controller = context.read<ExpenseViewModel>();
                Navigator.pop(context);
                try {
                  await controller.updateCustomCategory(id, currentName, newName);
                  await _loadCategories();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Category renamed to "$newName"'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to update category: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();
  }

  Future<void> _showDeleteCategoryDialog(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Category',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\n\n'
          'Any expenses with this category will be moved to "Others".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final controller = context.read<ExpenseViewModel>();
        await controller.deleteCustomCategory(id, name);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "$name" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete category: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Built-in Categories Section
                Text(
                  'Built-in Categories',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ..._builtInCategories.map((category) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ExpenseUtils.getCategoryColor(category).withValues(alpha: 0.15),
                      child: Icon(
                        ExpenseUtils.getCategoryIcon(category),
                        color: ExpenseUtils.getCategoryColor(category),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    trailing: Text(
                      'Built-in',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 24),

                // Custom Categories Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom Categories',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_customCategoriesWithId.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.label_off_outlined,
                            size: 48,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No custom categories yet',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add" to create one',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._customCategoriesWithId.map((categoryMap) {
                    final id = categoryMap['id'] as int;
                    final name = categoryMap['name'] as String;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ExpenseUtils.getCategoryColor(name).withValues(alpha: 0.15),
                          child: Icon(
                            ExpenseUtils.getCategoryIcon(name),
                            color: ExpenseUtils.getCategoryColor(name),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit',
                              onPressed: () => _showEditCategoryDialog(id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _showDeleteCategoryDialog(id, name),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
