import 'package:expense_tracker/features/reports/models/report_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/services/appwrite_service.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(ref.read(appwriteServiceProvider));
});

class ReportsService {
  final AppwriteService _appwriteService;

  ReportsService(this._appwriteService);

  Future<ReportData> generateMonthComparison() async {
    final months = await _appwriteService.getMonths();
    if (months.length < 2) {
      throw Exception('يجب وجود شهرين على الأقل للمقارنة');
    }

    final current = months[0];
    final previous = months[1];

    return ReportData(
      type: ReportType.monthComparison,
      title: 'مقارنة ${current.name} مع ${previous.name}',
      data: {
        'current': current,
        'previous': previous,
        'incomeDiff': current.totalIncome - previous.totalIncome,
        'expenseDiff': current.totalExpense - previous.totalExpense,
        'balanceDiff': current.remainingBalance - previous.remainingBalance,
      },
    );
  }

  Future<ReportData> generateCustomComparison(String month1Id, String month2Id) async {
    final months = await _appwriteService.getMonths();
    final month1 = months.firstWhere((m) => m.id == month1Id);
    final month2 = months.firstWhere((m) => m.id == month2Id);

    return ReportData(
      type: ReportType.customComparison,
      title: 'مقارنة ${month1.name} مع ${month2.name}',
      data: {
        'month1': month1,
        'month2': month2,
        'incomeDiff': month1.totalIncome - month2.totalIncome,
        'expenseDiff': month1.totalExpense - month2.totalExpense,
        'balanceDiff': month1.remainingBalance - month2.remainingBalance,
      },
    );
  }

  Future<ReportData> generateYearlyOverview(int year) async {
    final months = await _appwriteService.getMonths();
    final yearMonths = months.where((m) => m.year == year).toList();

    if (yearMonths.isEmpty) {
      throw Exception('لا توجد بيانات لعام $year');
    }

    final totalIncome = yearMonths.fold(0.0, (sum, m) => sum + m.totalIncome);
    final totalExpense = yearMonths.fold(0.0, (sum, m) => sum + m.totalExpense);
    final totalBalance = yearMonths.fold(0.0, (sum, m) => sum + m.remainingBalance);

    return ReportData(
      type: ReportType.yearlyOverview,
      title: 'ملخص عام $year',
      data: {
        'year': year,
        'months': yearMonths,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'totalBalance': totalBalance,
        'monthCount': yearMonths.length,
      },
    );
  }

  Future<ReportData> generateYearToYearComparison(int year1, int year2) async {
    final months = await _appwriteService.getMonths();
    final year1Months = months.where((m) => m.year == year1).toList();
    final year2Months = months.where((m) => m.year == year2).toList();

    if (year1Months.isEmpty || year2Months.isEmpty) {
      throw Exception('لا توجد بيانات كافية للمقارنة');
    }

    final year1Income = year1Months.fold(0.0, (sum, m) => sum + m.totalIncome);
    final year1Expense = year1Months.fold(0.0, (sum, m) => sum + m.totalExpense);
    final year2Income = year2Months.fold(0.0, (sum, m) => sum + m.totalIncome);
    final year2Expense = year2Months.fold(0.0, (sum, m) => sum + m.totalExpense);

    return ReportData(
      type: ReportType.yearToYear,
      title: 'مقارنة عام $year1 مع $year2',
      data: {
        'year1': year1,
        'year2': year2,
        'year1Months': year1Months,
        'year2Months': year2Months,
        'year1Income': year1Income,
        'year1Expense': year1Expense,
        'year2Income': year2Income,
        'year2Expense': year2Expense,
        'incomeDiff': year1Income - year2Income,
        'expenseDiff': year1Expense - year2Expense,
      },
    );
  }
}
