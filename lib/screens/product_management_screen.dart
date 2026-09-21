import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:zite_web_pos/services/product_service.dart';
import 'package:zite_web_pos/services/category_service.dart';
import 'package:zite_web_pos/services/unit_service.dart';
import 'package:zite_web_pos/services/bulk_upload_service.dart';
import 'package:zite_web_pos/services/api_service.dart'; // <-- ADDED for SKU generation
import 'package:zite_web_pos/models/product.dart';
import 'package:zite_web_pos/models/category.dart';
import 'package:zite_web_pos/models/unit.dart';
import 'package:zite_web_pos/utils/permissions.dart';
import 'package:zite_web_pos/screens/unauthorized_screen.dart';
import 'package:zite_web_pos/screens/bincard_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final UnitService _unitService = UnitService();

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Unit> _units = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<dynamic> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      return pickedFile;
    }
    return null;
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final products = await _productService.getAllProducts();
    final categories = await _categoryService.getAllCategories();
    final units = await _unitService.getAllUnits();

    setState(() {
      _products = products;
      _categories = categories;
      _units = units;
      _isLoading = false;
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.sku.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  // ==================== BULK UPLOAD METHODS ====================

  Future<void> _downloadTemplate() async {
    try {
      await BulkUploadService.downloadTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Upload Products'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Upload Excel (.xlsx) or CSV file'),
            SizedBox(height: 8),
            Text(
              'File must contain: name, sku, category, unit, cost_price, selling_price',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _bulkUpload();
            },
            icon: const Icon(Icons.upload),
            label: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkUpload() async {
    setState(() => _isLoading = true);

    try {
      final products = await BulkUploadService.pickAndParseFile();

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products found in file')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Import'),
          content: Text(
            'Found ${products.length} products. Do you want to import?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isLoading = false);
        return;
      }

      int successCount = 0;
      int errorCount = 0;

      for (var productData in products) {
        try {
          int? categoryId;
          if (productData['category'] != null &&
              productData['category'].toString().isNotEmpty) {
            final category = _categories.firstWhere(
              (c) =>
                  c.name.toLowerCase() ==
                  productData['category'].toString().toLowerCase(),
              orElse: () => Category(id: 0, name: '', isVatExempt: false),
            );
            categoryId = category.id > 0 ? category.id : null;
          }

          int? unitId;
          if (productData['unit'] != null &&
              productData['unit'].toString().isNotEmpty) {
            final unit = _units.firstWhere(
              (u) =>
                  u.name.toLowerCase() ==
                  productData['unit'].toString().toLowerCase(),
              orElse: () => Unit(
                id: 0,
                baseUnitId: 0,
                baseUnitName: '',
                name: '',
                symbol: '',
                conversionFactor: 1,
                isBaseUnit: false,
              ),
            );
            unitId = unit.id > 0 ? unit.id : null;
          }

          await _productService.addProduct(
            name: productData['name']?.toString() ?? '',
            sku: productData['sku']?.toString() ?? '',
            categoryId: categoryId,
            unitId: unitId,
            barcode: productData['barcode']?.toString(),
            costPrice:
                double.tryParse(productData['cost_price']?.toString() ?? '0') ??
                0,
            sellingPrice:
                double.tryParse(
                  productData['selling_price']?.toString() ?? '0',
                ) ??
                0,
            stockQuantity:
                double.tryParse(
                  productData['stock_quantity']?.toString() ?? '0',
                ) ??
                0,
            minStockLevel:
                double.tryParse(
                  productData['min_stock_level']?.toString() ?? '10',
                ) ??
                10,
            isVatExempt:
                productData['is_vat_exempt']?.toString().toLowerCase() ==
                'true',
          );
          successCount++;
        } catch (e) {
          errorCount++;
          print('Error importing ${productData['name']}: $e');
        }
      }

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported: $successCount success, $errorCount failed'),
          backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== PRODUCT CRUD METHODS ====================

  // Helper: auto-fill SKU when category is selected
  Future<void> _autoFillSku(
    TextEditingController skuController,
    int categoryId,
    String productName,
  ) async {
    print(
      '_autoFillSku: calling ApiService.getNextSku for categoryId=$categoryId, name=$productName',
    );
    final nextSku = await ApiService.getNextSku(categoryId, productName);
    print('_autoFillSku: received nextSku = "$nextSku"');
    if (nextSku.isNotEmpty) {
      skuController.text = nextSku;
      print('_autoFillSku: updated SKU field to "$nextSku"');
    } else {
      print('_autoFillSku: nextSku is empty, not updating');
    }
  }

    void _showAddProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    final markupController = TextEditingController();
    Category? selectedCategory;
    Unit? selectedUnit;
    bool isVatExempt = false;
    dynamic selectedImage;
    String? imagePreviewUrl;
    bool isSkuManuallyEdited = false;
    bool isMarkupManuallyEdited = false;
    bool isSellingPriceManuallyEdited = false;

    double resolveMarkup(Category? category) {
      if (category?.markupPercent != null) return category!.markupPercent!;
      return 30.0;
    }

    void recomputeSellingPrice() {
      if (isSellingPriceManuallyEdited) return;
      final cost = double.tryParse(costPriceController.text) ?? 0;
      final markup =
          double.tryParse(markupController.text) ??
          resolveMarkup(selectedCategory);
      final newSp = cost * (1 + markup / 100);
      sellingPriceController.text = newSp.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Product'),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCategoryDropdown(selectedCategory, (
                                value,
                              ) async {
                                setState(() => selectedCategory = value);
                                if (!isSkuManuallyEdited && value != null) {
                                  await _autoFillSku(
                                    skuController,
                                    value.id,
                                    nameController.text,
                                  );
                                }
                                if (!isMarkupManuallyEdited &&
                                    !isSellingPriceManuallyEdited) {
                                  recomputeSellingPrice();
                                }
                              }),
                              const SizedBox(height: 12),
                              _buildUnitDropdown(selectedUnit, (value) {
                                setState(() => selectedUnit = value);
                              }),
                              const SizedBox(height: 12),
                              _buildTextField(
                                nameController,
                                'Product Name *',
                                onChanged: (value) async {
                                  if (!isSkuManuallyEdited &&
                                      selectedCategory != null) {
                                    await _autoFillSku(
                                      skuController,
                                      selectedCategory!.id,
                                      value,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                skuController,
                                'SKU *',
                                onChanged: (_) => isSkuManuallyEdited = true,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(barcodeController, 'Barcode'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberTextField(
                                costPriceController,
                                'Cost Price (₦) *',
                                onChanged: (_) => recomputeSellingPrice(),
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                markupController,
                                'Markup % (optional)',
                                onChanged: (value) {
                                  isMarkupManuallyEdited = true;
                                  isSellingPriceManuallyEdited = false;
                                  recomputeSellingPrice();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                sellingPriceController,
                                'Selling Price (₦)',
                                onChanged: (_) {
                                  isSellingPriceManuallyEdited = true;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                stockController,
                                'Initial Stock',
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                minStockController,
                                'Min Stock Alert',
                              ),
                              const SizedBox(height: 12),
                              _buildVatCheckbox(isVatExempt, (value) {
                                setState(() => isVatExempt = value);
                              }),
                              if (selectedCategory != null &&
                                  selectedCategory!.isVatExempt)
                                _buildVatNote(
                                  'Category "${selectedCategory!.name}" is VAT exempt',
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? FutureBuilder(
                                              future: (selectedImage as XFile)
                                                  .readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                return _buildImagePlaceholder();
                                              },
                                            )
                                          : Image.file(
                                              File(
                                                (selectedImage as XFile).path,
                                              ),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildImagePlaceholder(),
                                            ),
                                    )
                                  : imagePreviewUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imagePreviewUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _buildImagePlaceholder(),
                                      ),
                                    )
                                  : _buildImagePlaceholder(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_library,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final image = await _pickImageFromGallery();
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = image;
                                        imagePreviewUrl = null;
                                      });
                                    }
                                  },
                                  tooltip: 'Choose from Gallery',
                                ),
                                if (selectedImage != null ||
                                    imagePreviewUrl != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedImage = null;
                                        imagePreviewUrl = null;
                                      });
                                    },
                                    tooltip: 'Remove Image',
                                  ),
                              ],
                            ),
                            const Text(
                              'Product Image',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        skuController.text.isEmpty ||
                        costPriceController.text.isEmpty) {
                      _showSnackBar('Please fill all required fields');
                      return;
                    }

                    String? imageUrl;
                    if (selectedImage != null) {
                      imageUrl = await _productService.uploadProductImage(
                        selectedImage!,
                      );
                    }

                    await _productService.addProduct(
                      name: nameController.text,
                      sku: skuController.text,
                      categoryId: selectedCategory?.id,
                      unitId: selectedUnit?.id,
                      barcode: barcodeController.text.isEmpty
                          ? null
                          : barcodeController.text,
                      costPrice: double.parse(costPriceController.text),
                      sellingPrice:
                          double.tryParse(sellingPriceController.text) ?? 0,
                      stockQuantity: double.tryParse(stockController.text) ?? 0,
                      minStockLevel:
                          double.tryParse(minStockController.text) ?? 0,
                      isVatExempt: isVatExempt,
                      imageUrl: imageUrl,
                      markupPercent: markupController.text.isEmpty
                          ? null
                          : double.tryParse(markupController.text),
                      markupIsManual: isSellingPriceManuallyEdited,
                    );
                    Navigator.pop(context);
                    _loadData();
                    _showSnackBar('Product added successfully');
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

    void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final skuController = TextEditingController(text: product.sku);
    final barcodeController = TextEditingController(
      text: product.barcode ?? '',
    );
    final costPriceController = TextEditingController(
      text: product.costPrice.toString(),
    );
    final sellingPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    final stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    final minStockController = TextEditingController(
      text: product.minStockLevel.toString(),
    );
    final markupController = TextEditingController(
      text: product.markupPercent != null
          ? product.markupPercent.toString()
          : '',
    );
    bool isVatExempt = product.isVatExempt;
    dynamic selectedImage;
    String? imagePreviewUrl = product.imageUrl;
    bool isSkuManuallyEdited = false;
    bool isMarkupManuallyEdited = product.markupPercent != null;
    bool isSellingPriceManuallyEdited = product.markupIsManual;

    Category? selectedCategory;
    if (product.categoryId != null && product.categoryId != 0) {
      try {
        selectedCategory = _categories.firstWhere(
          (c) => c.id == product.categoryId,
        );
      } catch (e) {
        selectedCategory = null;
      }
    }

    Unit? selectedUnit;
    if (product.unitId != null && product.unitId != 0) {
      try {
        selectedUnit = _units.firstWhere((u) => u.id == product.unitId);
      } catch (e) {
        selectedUnit = null;
      }
    }

    double resolveMarkup(Category? category) {
      if (category?.markupPercent != null) return category!.markupPercent!;
      return product.effectiveMarkupPercent > 0
          ? product.effectiveMarkupPercent
          : 30.0;
    }

    void recomputeSellingPrice() {
      if (isSellingPriceManuallyEdited) return;
      final cost = double.tryParse(costPriceController.text) ?? 0;
      final markup =
          double.tryParse(markupController.text) ??
          resolveMarkup(selectedCategory);
      final newSp = cost * (1 + markup / 100);
      sellingPriceController.text = newSp.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCategoryDropdown(selectedCategory, (
                                value,
                              ) async {
                                setState(() => selectedCategory = value);
                                if (!isSkuManuallyEdited && value != null) {
                                  await _autoFillSku(
                                    skuController,
                                    value.id,
                                    nameController.text,
                                  );
                                }
                                if (!isMarkupManuallyEdited &&
                                    !isSellingPriceManuallyEdited) {
                                  recomputeSellingPrice();
                                }
                              }),
                              const SizedBox(height: 12),
                              _buildUnitDropdown(selectedUnit, (value) {
                                setState(() => selectedUnit = value);
                              }),
                              const SizedBox(height: 12),
                              _buildTextField(
                                nameController,
                                'Product Name *',
                                onChanged: (value) async {
                                  if (!isSkuManuallyEdited &&
                                      selectedCategory != null) {
                                    await _autoFillSku(
                                      skuController,
                                      selectedCategory!.id,
                                      value,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                skuController,
                                'SKU *',
                                onChanged: (_) => isSkuManuallyEdited = true,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(barcodeController, 'Barcode'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNumberTextField(
                                costPriceController,
                                'Cost Price (₦) *',
                                onChanged: (_) => recomputeSellingPrice(),
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                markupController,
                                'Markup % (optional)',
                                onChanged: (value) {
                                  isMarkupManuallyEdited = true;
                                  isSellingPriceManuallyEdited = false;
                                  recomputeSellingPrice();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                sellingPriceController,
                                'Selling Price (₦)',
                                onChanged: (_) {
                                  isSellingPriceManuallyEdited = true;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                stockController,
                                'Stock Quantity',
                              ),
                              const SizedBox(height: 12),
                              _buildNumberTextField(
                                minStockController,
                                'Min Stock Alert',
                              ),
                              const SizedBox(height: 12),
                              _buildVatCheckbox(isVatExempt, (value) {
                                setState(() => isVatExempt = value);
                              }),
                              if (selectedCategory != null &&
                                  selectedCategory!.isVatExempt)
                                _buildVatNote(
                                  'Category "${selectedCategory!.name}" is VAT exempt',
                                ),
                              if (isVatExempt != product.isVatExempt)
                                _buildVatNote(
                                  isVatExempt
                                      ? 'Product will be VAT exempt (overrides category)'
                                      : 'Product will be VATable',
                                  isBlue: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? FutureBuilder(
                                              future: (selectedImage as XFile)
                                                  .readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                return _buildImagePlaceholder();
                                              },
                                            )
                                          : Image.file(
                                              File(
                                                (selectedImage as XFile).path,
                                              ),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildImagePlaceholder(),
                                            ),
                                    )
                                  : imagePreviewUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imagePreviewUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _buildImagePlaceholder(),
                                      ),
                                    )
                                  : _buildImagePlaceholder(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_library,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final image = await _pickImageFromGallery();
                                    if (image != null) {
                                      setState(() {
                                        selectedImage = image;
                                        imagePreviewUrl = null;
                                      });
                                    }
                                  },
                                  tooltip: 'Choose from Gallery',
                                ),
                                if (selectedImage != null ||
                                    imagePreviewUrl != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedImage = null;
                                        imagePreviewUrl = null;
                                      });
                                    },
                                    tooltip: 'Remove Image',
                                  ),
                              ],
                            ),
                            const Text(
                              'Product Image',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        skuController.text.isEmpty ||
                        costPriceController.text.isEmpty) {
                      _showSnackBar('Please fill all required fields');
                      return;
                    }

                    String? imageUrl;
                    if (selectedImage != null) {
                      imageUrl = await _productService.uploadProductImage(
                        selectedImage!,
                      );
                    }

                    await _productService.updateProduct(
                      id: product.id,
                      name: nameController.text,
                      sku: skuController.text,
                      categoryId: selectedCategory?.id,
                      unitId: selectedUnit?.id,
                      barcode: barcodeController.text.isEmpty
                          ? null
                          : barcodeController.text,
                      costPrice: double.parse(costPriceController.text),
                      sellingPrice:
                          double.tryParse(sellingPriceController.text) ??
                          product.sellingPrice,
                      stockQuantity:
                          double.tryParse(stockController.text) ??
                          product.stockQuantity,
                      minStockLevel:
                          double.tryParse(minStockController.text) ??
                          product.minStockLevel,
                      isVatExempt: isVatExempt,
                      imageUrl: imageUrl ?? imagePreviewUrl,
                      markupPercent: markupController.text.isEmpty
                          ? null
                          : double.tryParse(markupController.text),
                      markupIsManual: isSellingPriceManuallyEdited,
                    );
                    Navigator.pop(context);
                    _loadData();
                    _showSnackBar('Product updated successfully');
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

  void _showAdjustStockDialog(Product product) {
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${product.stockQuantity.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            _buildNumberTextField(stockController, 'Quantity to Add'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(stockController.text) ?? 0;
              if (qty <= 0) {
                _showSnackBar('Please enter a valid quantity');
                return;
              }
              await _productService.updateStock(product.id, qty);
              Navigator.pop(context);
              _loadData();
              _showSnackBar(
                'Added ${qty.toStringAsFixed(0)} to ${product.name}',
              );
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  // ==================== UI HELPER METHODS ====================

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberTextField(
    TextEditingController controller,
    String label, {
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildCategoryDropdown(
    Category? selected,
    Function(Category?) onChanged,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: DropdownButtonFormField<Category>(
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        hint: const Text('Select Category'),
        initialValue: selected,
        items: _categories.map((cat) {
          return DropdownMenuItem(
            value: cat,
            child: Text(cat.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUnitDropdown(Unit? selected, Function(Unit?) onChanged) {
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: DropdownButtonFormField<Unit>(
        decoration: const InputDecoration(
          labelText: 'Unit',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        menuMaxHeight: 200,
        hint: const Text('Select Unit'),
        initialValue: selected,
        items: _units.map((unit) {
          return DropdownMenuItem(
            value: unit,
            child: Text(
              '${unit.name} (${unit.symbol})',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildVatCheckbox(bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        const Text('VAT Exempt'),
      ],
    );
  }

  Widget _buildVatNote(String text, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isBlue ? Colors.blue.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Permissions.canManageProducts) {
      return const UnauthorizedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products', style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1e3a8a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showBulkUploadDialog,
            tooltip: 'Bulk Upload',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadTemplate,
            tooltip: 'Download Template',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF1e3a8a),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isLowStock =
                          product.stockQuantity < product.minStockLevel;
                      final unit = _units.firstWhere(
                        (u) => u.id == product.unitId,
                        orElse: () => Unit(
                          id: 0,
                          baseUnitId: 0,
                          baseUnitName: '',
                          name: '',
                          symbol: '',
                          conversionFactor: 1,
                          isBaseUnit: false,
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return _buildAvatar(product);
                                    },
                                  ),
                                )
                              : _buildAvatar(product),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SKU: ${product.sku} | Price: ₦${product.sellingPrice.toStringAsFixed(0)}${unit.symbol.isNotEmpty ? ' | Unit: ${unit.symbol}' : ''} | Stock: ${product.stockQuantity.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLowStock
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (product.isVatExempt)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'VAT Exempt',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.account_balance,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BincardScreen(product: product),
                                  ),
                                ),
                                tooltip: 'View Bincard',
                              ),
                              IconButton(
                                icon: const Icon(Icons.inventory, size: 20),
                                onPressed: () =>
                                    _showAdjustStockDialog(product),
                                tooltip: 'Adjust Stock',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showEditProductDialog(product),
                              ),
                            ],
                          ),
                          onTap: () => _showEditProductDialog(product),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Product product) {
    return CircleAvatar(
      backgroundColor: Colors.blue.shade100,
      child: Text(
        product.sku.substring(0, 1).toUpperCase(),
        style: const TextStyle(color: Colors.blue),
      ),
    );
  }
}
