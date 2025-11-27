import 'package:expense_tracker/features/dashboard/widgets/expense_pie_chart.dart';
import 'package:expense_tracker/features/dashboard/widgets/summary_card.dart';
import 'package:expense_tracker/features/months/providers/months_provider.dart';
import 'package:expense_tracker/features/months/widgets/add_month_dialog.dart';
import 'package:expense_tracker/features/reports/screens/reports_screen.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:expense_tracker/features/transactions/screens/fixed_transactions_screen.dart';
import 'package:expense_tracker/features/transactions/widgets/add_transaction_modal.dart';
import 'package:expense_tracker/features/transactions/widgets/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthsAsync = ref.watch(monthsProvider);
    final selectedMonthId = ref.watch(selectedMonthIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'المصاريف الشهرية',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_outlined, color: Color(0xFF667EEA)),
            ),
            tooltip: 'التقارير',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.push_pin, color: Color(0xFF667EEA)),
            ),
            tooltip: 'المصاريف الثابتة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixedTransactionsScreen(),
                ),
              );
            },
          ),
          monthsAsync.when(
            data: (months) {
              if (months.isEmpty) {
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF667EEA)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddMonthDialog(),
                    );
                  },
                );
              }

              // Get the currently selected month or default to first
              final selectedMonth = months.firstWhere(
                (m) => m.id == selectedMonthId,
                orElse: () => months.first,
              );

              return Row(
                children: [
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    tooltip: 'اختر شهر',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedMonth.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF667EEA),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => months.map((month) {
                      return PopupMenuItem<String>(
                        value: month.id,
                        onTap: () {
                          // This onTap is called before the menu closes, so we use addPostFrameCallback
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref.read(selectedMonthIdProvider.notifier).state = month.id;
                          });
                        },
                        child: Row(
                          children: [
                            Expanded(child: Text(month.name)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                // Close the popup menu first
                                Navigator.pop(context);
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('تأكيد الحذف'),
                                    content: Text('هل أنت متأكد من حذف شهر ${month.name}؟'),
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
                                
                                if (confirmed == true) {
                                  await ref.read(monthsProvider.notifier).deleteMonth(month.id);
                                  // Reset selection to first month after deletion if the deleted month was selected
                                  if (ref.read(selectedMonthIdProvider) == month.id) {
                                    final updatedMonths = ref.read(monthsProvider).value;
                                    ref.read(selectedMonthIdProvider.notifier).state = updatedMonths?.first.id;
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF667EEA)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddMonthDialog(),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Icon(Icons.error),
          ),
        ],
      ),
      body: monthsAsync.when(
        data: (months) {
          if (months.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ابدأ بإضافة شهر جديد',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على زر + لإضافة شهرك الأول',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // If no month selected, select the first one (latest)
          if (selectedMonthId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedMonthIdProvider.notifier).state = months.first.id;
            });
            return const Center(child: CircularProgressIndicator());
          }

          final currentMonth = months.firstWhere((m) => m.id == selectedMonthId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SummaryCard(month: currentMonth),
                const SizedBox(height: 24),
                const SizedBox(
                  height: 240,
                  child: ExpensePieChart(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'المعاملات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TransactionList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final monthsAsync = ref.read(monthsProvider);
          if (!monthsAsync.hasValue || monthsAsync.value!.isEmpty) {
            // Show message to add month first
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('الرجاء إضافة شهر أولاً قبل إضافة المعاملات'),
                backgroundColor: Color(0xFFF56565),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTransactionModal(),
          );
        },
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add_rounded),
        label: const Text('معاملة جديدة'),
      ),
    );
  }
}
