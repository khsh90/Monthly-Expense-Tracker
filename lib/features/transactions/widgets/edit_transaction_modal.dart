import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditTransactionModal extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const EditTransactionModal({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionModal> createState() =>
      _EditTransactionModalState();
}

class _EditTransactionModalState extends ConsumerState<EditTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late CategoryMain _selectedCategory;
  late bool _isFixed;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _selectedCategory = widget.transaction.categoryMain;
    _isFixed = widget.transaction.isFixed;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) return;

      ref.read(transactionsProvider.notifier).updateTransaction(
            transactionId: widget.transaction.id,
            category: _selectedCategory,
            title: _titleController.text,
            amount: amount,
            isFixed: _isFixed,
          );
      Navigator.pop(context);
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(transactionsProvider.notifier)
                  .deleteTransaction(widget.transaction.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'تعديل المعاملة',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'حذف',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<CategoryMain>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  border: InputBorder.none,
                  icon: Icon(Icons.category_rounded, color: Color(0xFF667EEA)),
                ),
                items: CategoryMain.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: InputBorder.none,
                  icon: Icon(Icons.title_rounded, color: Color(0xFF667EEA)),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: InputBorder.none,
                  icon: Icon(Icons.attach_money, color: Color(0xFF667EEA)),
                  hintText: '0.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'مطلوب';
                  if (double.tryParse(value) == null) return 'رقم غير صحيح';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                title: const Row(
                  children: [
                    Icon(Icons.push_pin, size: 20, color: Color(0xFF667EEA)),
                    SizedBox(width: 8),
                    Text('مصروف ثابت شهرياً'),
                  ],
                ),
                value: _isFixed,
                activeColor: const Color(0xFF667EEA),
                onChanged: (value) {
                  setState(() {
                    _isFixed = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حفظ التعديلات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(CategoryMain category) {
    switch (category) {
      case CategoryMain.income:
        return 'الدخل';
      case CategoryMain.mandatory:
        return 'المصاريف الاجبارية';
      case CategoryMain.optional:
        return 'المصاريف الاختيارية';
      case CategoryMain.debt:
        return 'ديون';
      case CategoryMain.savings:
        return 'ادخار';
    }
  }
}
