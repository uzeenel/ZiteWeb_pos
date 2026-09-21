import 'package:flutter/material.dart';
import 'package:zite_web_pos/services/category_service.dart';
import 'package:zite_web_pos/models/category.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    final categories = await _categoryService.getAllCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final markupController = TextEditingController();

    bool isVatExempt = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('VAT Exempt'),
                    value: isVatExempt,
                    onChanged: (value) {
                      setState(() {
                        isVatExempt = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                                    const SizedBox(height: 8),
                  TextField(
                    controller: markupController,
                    decoration: const InputDecoration(
                      labelText: 'Markup % (optional)',
                      helperText: 'Leave blank to use global default',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter category name'),
                        ),
                      );
                      return;
                    }
                    await _categoryService.addCategory(
                      name: nameController.text,
                      description: descController.text.isEmpty
                          ? null
                          : descController.text,
                      isVatExempt: isVatExempt,
                      markupPercent: markupController.text.isEmpty
                          ? null
                          : double.tryParse(markupController.text),
                    );
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category added successfully'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(
      text: category.description ?? '',
    );
    bool isVatExempt = category.isVatExempt;
    final markupController = TextEditingController(
      text: category.markupPercent != null
          ? category.markupPercent.toString()
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('VAT Exempt'),
                    value: isVatExempt,
                    onChanged: (value) {
                      setState(() {
                        isVatExempt = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                    TextField(
                      controller: markupController,
                      decoration: const InputDecoration(
                        labelText: 'Markup % (optional)',
                        helperText: 'Leave blank to use global default',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter category name'),
                        ),
                      );
                      return;
                    }
                    await _categoryService.updateCategory(
                      id: category.id,
                      name: nameController.text,
                      description: descController.text.isEmpty
                          ? null
                          : descController.text,
                      isVatExempt: isVatExempt,
                      markupPercent: markupController.text.isEmpty
                          ? null
                          : double.tryParse(markupController.text),
                    );
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category updated successfully'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _categoryService.deleteCategory(category.id);
                Navigator.pop(context);
                _loadCategories();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${category.name} deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDetails(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category.description != null &&
                  category.description!.isNotEmpty)
                Text(category.description!),
              const SizedBox(height: 8),
                            Row(
                children: [
                  Icon(
                    category.isVatExempt ? Icons.receipt : Icons.category,
                    size: 16,
                    color: category.isVatExempt ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VAT Exempt: ${category.isVatExempt ? "Yes" : "No"}',
                    style: TextStyle(
                      color: category.isVatExempt ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: category.markupPercent != null
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.markupPercent != null
                        ? 'Markup: ${category.markupPercent!.toStringAsFixed(1)}%'
                        : 'Markup: Using global default',
                    style: TextStyle(
                      color: category.markupPercent != null
                          ? Colors.blue.shade700
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditCategoryDialog(category);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check permisions - Only Admin and Manager can access category management
    if (!Permissions.canManageCategories) {
      return const UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFF1e3a8a),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? const Center(
              child: Text('No categories found.\nTap + to add a category'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.isVatExempt
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        category.isVatExempt ? Icons.receipt : Icons.category,
                        color: category.isVatExempt
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.description != null)
                          Text(
                            category.description!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (category.markupPercent != null)
                          Text(
                            'Markup: ${category.markupPercent!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category.isVatExempt)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'VAT Exempt',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditCategoryDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _showDeleteDialog(category),
                          color: Colors.red,
                        ),
                      ],
                    ),
                    onTap: () => _showCategoryDetails(
                      category,
                    ), // Now calls details view
                  ),
                );
              },
            ),
    );
  }
}
