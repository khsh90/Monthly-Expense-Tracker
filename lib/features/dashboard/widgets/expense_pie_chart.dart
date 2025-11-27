import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensePieChart extends ConsumerWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد بيانات',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final Map<CategoryMain, double> categoryTotals = {};
        for (var t in transactions) {
          categoryTotals[t.categoryMain] =
              (categoryTotals[t.categoryMain] ?? 0) + t.amount;
        }

        final total = categoryTotals.values.fold(0.0, (sum, item) => sum + item);
        if (total == 0) {
          return const Center(child: Text('لا توجد مصاريف'));
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: categoryTotals.entries.map((entry) {
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        color: _getColorForCategory(entry.key),
                        value: entry.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: null,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryTotals.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getColorForCategory(entry.key),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getCategoryName(entry.key),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
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
        return 'دخل';
      case CategoryMain.mandatory:
        return 'اجباري';
      case CategoryMain.optional:
        return 'اختياري';
      case CategoryMain.debt:
        return 'ديون';
      case CategoryMain.savings:
        return 'ادخار';
    }
  }
}
