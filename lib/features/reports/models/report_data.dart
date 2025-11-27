enum ReportType {
  monthComparison,     // Compare current month with previous
  customComparison,    // Compare any two months
  yearlyOverview,      // All months in current year
  yearToYear,          // Compare same period across years
}

class ReportData {
  final ReportType type;
  final String title;
  final Map<String, dynamic> data;

  ReportData({
    required this.type,
    required this.title,
    required this.data,
  });
}
