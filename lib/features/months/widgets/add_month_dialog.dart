import 'package:expense_tracker/features/months/providers/months_provider.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddMonthDialog extends ConsumerStatefulWidget {
  const AddMonthDialog({super.key});

  @override
  ConsumerState<AddMonthDialog> createState() => _AddMonthDialogState();
}

class _AddMonthDialogState extends ConsumerState<AddMonthDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _selectedYear;
  late int _selectedMonth;
  bool _generateFromPrevious = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = DateFormat('MMMM yyyy', 'ar').format(DateTime(_selectedYear, _selectedMonth));

      final monthsAsync = ref.read(monthsProvider);
      String? prevMonthId;
      if (monthsAsync.hasValue && monthsAsync.value!.isNotEmpty) {
        prevMonthId = monthsAsync.value!.first.id;
      }

      String? newMonthId;
      if (_generateFromPrevious && prevMonthId != null) {
        newMonthId = await ref.read(monthsProvider.notifier).generateNextMonth(
              prevMonthId,
              name,
              _selectedYear,
              _selectedMonth,
            );
      } else {
        newMonthId = await ref.read(monthsProvider.notifier).createMonth(
              name,
              _selectedYear,
              _selectedMonth,
            );
      }

      // Switch to the newly created month
      if (newMonthId != null) {
        ref.read(selectedMonthIdProvider.notifier).state = newMonthId;
        print('Switched to newly created month: $newMonthId');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // Generate year list (2020 to current year)
    final years = List.generate(currentYear - 2019, (i) => 2020 + i);
    
    // Generate month list, filtered by selected year
    final months = _selectedYear == currentYear
        ? List.generate(currentMonth, (i) => i + 1)
        : List.generate(12, (i) => i + 1);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'إضافة شهر جديد',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'السنة',
                          border: InputBorder.none,
                        ),
                        items: years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                            // Reset month if it's now invalid
                            if (_selectedYear == currentYear && _selectedMonth > currentMonth) {
                              _selectedMonth = currentMonth;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'الشهر',
                          border: InputBorder.none,
                        ),
                        items: months.map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(DateFormat('MMMM', 'ar').format(DateTime(2000, month))),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CheckboxListTile(
                  title: const Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 20, color: Color(0xFF667EEA)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نسخ المصاريف الثابتة (من قائمة القوالب)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(right: 28, top: 4),
                    child: Text(
                      'سيتم نسخ جميع المعاملات المحفوظة في قائمة القوالب',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  value: _generateFromPrevious,
                  activeColor: const Color(0xFF667EEA),
                  onChanged: (value) {
                    setState(() {
                      _generateFromPrevious = value ?? true;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إضافة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
