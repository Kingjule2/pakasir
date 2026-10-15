import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../theme/app_colors.dart';

class AddProductDialog extends StatefulWidget {
  final ValueChanged<InventoryItem> onAdd;

  const AddProductDialog({super.key, required this.onAdd});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _totalQtyController = TextEditingController(text: '100');
  final _stockInController = TextEditingController(text: '80');
  final _priceController = TextEditingController(text: '150');
  final _costPriceController = TextEditingController(text: '95');

  String _category = 'Fashion';
  String _tag = 'Fast Moving';
  PriorityLevel _priority = PriorityLevel.high;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Name & SKU
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'e.g. Wireless Earbuds',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Name required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        hintText: 'e.g. SKU-420',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'SKU required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category & Tag Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Fashion', child: Text('Fashion')),
                        DropdownMenuItem(
                            value: 'Electronic', child: Text('Electronic')),
                        DropdownMenuItem(
                            value: 'Drinks', child: Text('Drinks')),
                        DropdownMenuItem(
                            value: 'Watch', child: Text('Watch')),
                        DropdownMenuItem(
                            value: 'Toys', child: Text('Toys')),
                        DropdownMenuItem(
                            value: 'Home', child: Text('Home')),
                      ],
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tag,
                      decoration: const InputDecoration(
                        labelText: 'AI Tag',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Fast Moving', child: Text('Fast Moving')),
                        DropdownMenuItem(
                            value: 'Discounted', child: Text('Discounted')),
                        DropdownMenuItem(
                            value: 'Low Demand', child: Text('Low Demand')),
                        DropdownMenuItem(
                            value: 'Dead Items', child: Text('Dead Items')),
                        DropdownMenuItem(
                            value: 'New Arrival', child: Text('New Arrival')),
                      ],
                      onChanged: (val) => setState(() => _tag = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quantities
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Qty',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => int.tryParse(val ?? '') == null
                          ? 'Invalid qty'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockInController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock In',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => int.tryParse(val ?? '') == null
                          ? 'Invalid stock'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Prices & Priority
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (\$)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PriorityLevel>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: PriorityLevel.high, child: Text('High')),
                        DropdownMenuItem(
                            value: PriorityLevel.medium, child: Text('Medium')),
                        DropdownMenuItem(
                            value: PriorityLevel.low, child: Text('Low')),
                      ],
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Add Product'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final totalQty = int.parse(_totalQtyController.text);
      final stockIn = int.parse(_stockInController.text);
      final price = double.tryParse(_priceController.text) ?? 100.0;
      final costPrice = double.tryParse(_costPriceController.text) ?? 60.0;

      final newItem = InventoryItem(
        id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        category: _category,
        totalQty: totalQty,
        stockIn: stockIn,
        price: price,
        costPrice: costPrice,
        priority: _priority,
        tag: _tag,
        isOutOfStock: stockIn == 0,
      );

      widget.onAdd(newItem);
      Navigator.pop(context);
    }
  }
}
