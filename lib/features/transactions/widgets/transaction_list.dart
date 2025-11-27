import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:expense_tracker/features/transactions/widgets/edit_transaction_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد معاملات',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Group by Category
        final grouped = <CategoryMain, List<TransactionModel>>{};
        for (var t in transactions) {
          if (!grouped.containsKey(t.categoryMain)) {
            grouped[t.categoryMain] = [];
          }
          grouped[t.categoryMain]!.add(t);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final category = grouped.keys.elementAt(index);
            final items = grouped[category]!;
            final total = items.fold(0.0, (sum, item) => sum + item.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorForCategory(category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: _getColorForCategory(category),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getCategoryName(category),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      Text(
                        total.toStringAsFixed(3),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getColorForCategory(category),
                        ),
                      ),
                    ],
                  ),
                ),
                ...items.map((item) => InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditTransactionModal(transaction: item),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getColorForCategory(category),
                                  _getColorForCategory(category).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              if (item.isFixed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF667EEA).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.push_pin,
                                        size: 12,
                                        color: Color(0xFF667EEA),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ثابت',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFF667EEA),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            item.amount.toStringAsFixed(3),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: category == CategoryMain.income
                                  ? const Color(0xFF48BB78)
                                  : const Color(0xFFF56565),
                            ),
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: Colors.red),
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
}
