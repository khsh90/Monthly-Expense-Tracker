import 'package:expense_tracker/core/services/appwrite_service.dart';
import 'package:expense_tracker/features/months/models/month.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monthsProvider = StateNotifierProvider<MonthsNotifier, AsyncValue<List<Month>>>((ref) {
  return MonthsNotifier(ref.read(appwriteServiceProvider));
});

class MonthsNotifier extends StateNotifier<AsyncValue<List<Month>>> {
  final AppwriteService _appwriteService;

  MonthsNotifier(this._appwriteService) : super(const AsyncValue.loading()) {
    loadMonths();
  }

  Future<void> loadMonths() async {
    try {
      final months = await _appwriteService.getMonths();
      state = AsyncValue.data(months);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createMonth(String name, int year, int monthIndex) async {
    try {
      final newMonth = await _appwriteService.createMonth(
        name: name,
        year: year,
        monthIndex: monthIndex,
      );
      await loadMonths(); // Refresh list
      return newMonth.id; // Return the new month ID
    } catch (e, st) {
      // Handle error, maybe show snackbar via a side effect provider or listener
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> generateNextMonth(String prevMonthId, String name, int year, int monthIndex) async {
     try {
      final newMonthId = await _appwriteService.generateNextMonth(
        previousMonthId: prevMonthId,
        newMonthName: name,
        newYear: year,
        newMonthIndex: monthIndex,
      );
      await loadMonths();
      return newMonthId; // Return the new month ID
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> deleteMonth(String monthId) async {
    try {
      await _appwriteService.deleteMonth(monthId);
      await loadMonths();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
