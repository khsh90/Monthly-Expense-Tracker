import 'package:expense_tracker/core/services/appwrite_service.dart';
import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:expense_tracker/features/transactions/models/transaction_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final templatesProvider = FutureProvider<List<TransactionTemplate>>((ref) async {
  final appwriteService = ref.read(appwriteServiceProvider);
  return await appwriteService.getTemplates();
});

class FixedTransactionsScreen extends ConsumerWidget {
  const FixedTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin, color: Color(0xFF667EEA)),
            SizedBox(width: 12),
            Text('قوالب المصاريف الثابتة'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTemplateDialog(context, ref);
        },
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add_rounded),
        label: const Text('قالب جديد'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          print('Templates loaded: ${templates.length}');
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.push_pin_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد قوالب',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'القوالب ستُنسخ عند إنشاء شهر جديد',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تعديل القوالب يؤثر فقط على الأشهر الجديدة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return InkWell(
                onTap: () {
                  _showEditTemplateDialog(context, ref, template);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getColorForCategory(template.categoryMain),
                            _getColorForCategory(template.categoryMain).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(template.categoryMain),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_all,
                                size: 12,
                                color: Color(0xFF667EEA),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'قالب',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_getCategoryName(template.categoryMain)),
                    ),
                    trailing: Text(
                      template.amount.toStringAsFixed(3),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: template.categoryMain == CategoryMain.income
                            ? const Color(0xFF48BB78)
                            : const Color(0xFFF56565),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () {
          print('Loading templates...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, stackTrace) {
          print('Error loading templates: $e');
          print('Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل القوالب',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '$e',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TemplateDialog(ref: ref),
    );
  }

  void _showEditTemplateDialog(BuildContext context, WidgetRef ref, TransactionTemplate template) {
    showDialog(
      context: context,
      builder: (context) => TemplateDialog(ref: ref, template: template),
    );
  }

  IconData _getCategoryIcon(CategoryMain category) {
    switch (category) {
      case CategoryMain.income:
        return Icons.trending_up_rounded;
      case CategoryMain.mandatory:
        return Icons.priority_high_rounded;
      case CategoryMain.optional:
        return Icons.shopping_bag_rounded;
      case CategoryMain.debt:
        return Icons.credit_card_rounded;
      case CategoryMain.savings:
        return Icons.savings_rounded;
    }
  }

  Color _getColorForCategory(CategoryMain category) {
    switch (category) {
      case CategoryMain.income:
        return const Color(0xFF48BB78);
      case CategoryMain.mandatory:
        return const Color(0xFFF56565);
      case CategoryMain.optional:
        return const Color(0xFFED8936);
      case CategoryMain.debt:
        return const Color(0xFF9F7AEA);
      case CategoryMain.savings:
        return const Color(0xFF4299E1);
    }
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

class TemplateDialog extends StatefulWidget {
  final WidgetRef ref;
  final TransactionTemplate? template;

  const TemplateDialog({super.key, required this.ref, this.template});

  @override
  State<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late CategoryMain _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template?.title ?? '');
    _amountController = TextEditingController(
      text: widget.template?.amount.toString() ?? '',
    );
    _selectedCategory = widget.template?.categoryMain ?? CategoryMain.optional;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null) return;

      final appwriteService = widget.ref.read(appwriteServiceProvider);
      
      if (widget.template == null) {
        // Create
        await appwriteService.createTemplate(
          categoryMain: _selectedCategory,
          title: _titleController.text,
          amount: amount,
        );
      } else {
        // Update
        await appwriteService.updateTemplate(
          templateId: widget.template!.id,
          categoryMain: _selectedCategory,
          title: _titleController.text,
          amount: amount,
        );
      }

      widget.ref.invalidate(templatesProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القالب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.template != null) {
      final appwriteService = widget.ref.read(appwriteServiceProvider);
      await appwriteService.deleteTemplate(widget.template!.id);
      widget.ref.invalidate(templatesProvider);
      // Only close the edit dialog, stay on Fixed Transactions screen
      if (mounted) {
        Navigator.pop(context); // Close the edit dialog only
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Icon(
                      widget.template == null ? Icons.add_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.template == null ? 'قالب جديد' : 'تعديل القالب',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  if (widget.template != null)
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.template == null ? 'إضافة' : 'حفظ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
