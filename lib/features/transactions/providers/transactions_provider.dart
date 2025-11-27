import 'package:expense_tracker/core/services/appwrite_service.dart';
import 'package:expense_tracker/features/months/providers/months_provider.dart';
import 'package:expense_tracker/features/transactions/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMonthIdProvider = StateProvider<String?>((ref) => null);

final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  final monthId = ref.watch(selectedMonthIdProvider);
  return TransactionsNotifier(ref.read(appwriteServiceProvider), monthId, ref);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final AppwriteService _appwriteService;
  final String? _monthId;
  final Ref _ref;

  TransactionsNotifier(this._appwriteService, this._monthId, this._ref) : super(const AsyncValue.loading()) {
    if (_monthId != null) {
      loadTransactions();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadTransactions() async {
    if (_monthId == null) return;
    try {
      final transactions = await _appwriteService.getTransactions(_monthId!);
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction({
    required CategoryMain category,
    required String title,
    required double amount,
    required bool isFixed,
  }) async {
    if (_monthId == null) return;
    try {
      // Create the transaction in the current month
      await _appwriteService.createTransaction(
        monthId: _monthId!,
        categoryMain: category,
        title: title,
        amount: amount,
        isFixed: isFixed,
      );

      // If marked as fixed, also create/update a template for future months
      if (isFixed) {
        print('Transaction marked as fixed, creating template: $title');
        await _appwriteService.createOrUpdateTemplateByTitle(
          categoryMain: category,
          title: title,
          amount: amount,
        );
      }

      // Update month totals
      await _appwriteService.updateMonthTotals(_monthId!);
      // Refresh months to update dashboard
      _ref.read(monthsProvider.notifier).loadMonths();
      await loadTransactions();
    } catch (e, st) {
      print('Error adding transaction: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTransaction({
    required String transactionId,
    required CategoryMain category,
    required String title,
    required double amount,
    required bool isFixed,
    bool? wasFixed,
  }) async {
    if (_monthId == null) return;
    try {
      // Get the old transaction to check if it was previously fixed
      final oldTransaction = state.value?.firstWhere((t) => t.id == transactionId);
      final previouslyFixed = wasFixed ?? oldTransaction?.isFixed ?? false;

      // Update the transaction in the current month
      await _appwriteService.updateTransaction(
        transactionId: transactionId,
        monthId: _monthId!,
        categoryMain: category,
        title: title,
        amount: amount,
        isFixed: isFixed,
      );

      // Handle template synchronization
      if (isFixed && !previouslyFixed) {
        // Changed from not-fixed to fixed: Create template
        print('Transaction changed to fixed, creating template: $title');
        await _appwriteService.createOrUpdateTemplateByTitle(
          categoryMain: category,
          title: title,
          amount: amount,
        );
      } else if (!isFixed && previouslyFixed) {
        // Changed from fixed to not-fixed: Remove template
        print('Transaction changed to not-fixed, removing template: ${oldTransaction?.title}');
        if (oldTransaction != null) {
          await _appwriteService.deleteTemplateByTitle(oldTransaction.title);
        }
      } else if (isFixed) {
        // Still fixed but values changed: Update template
        print('Fixed transaction updated, updating template: $title');
        await _appwriteService.createOrUpdateTemplateByTitle(
          categoryMain: category,
          title: title,
          amount: amount,
        );
      }

      // Update month totals
      await _appwriteService.updateMonthTotals(_monthId!);
      // Refresh months to update dashboard
      _ref.read(monthsProvider.notifier).loadMonths();
      await loadTransactions();
    } catch (e, st) {
      print('Error updating transaction: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_monthId == null) return;
    try {
      await _appwriteService.deleteTransaction(transactionId);
      // Update month totals
      await _appwriteService.updateMonthTotals(_monthId!);
      // Refresh months to update dashboard
      _ref.read(monthsProvider.notifier).loadMonths();
      await loadTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
