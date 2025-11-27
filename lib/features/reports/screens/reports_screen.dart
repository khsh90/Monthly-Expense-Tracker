import 'package:expense_tracker/features/reports/models/report_data.dart';
import 'package:expense_tracker/features/reports/services/export_service.dart';
import 'package:expense_tracker/features/reports/services/reports_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType _selectedType = ReportType.monthComparison;
  ReportData? _currentReport;
  bool _isLoading = false;

  final _exportService = ExportService();

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportsService = ref.read(reportsServiceProvider);
      ReportData report;

      switch (_selectedType) {
        case ReportType.monthComparison:
          report = await reportsService.generateMonthComparison();
          break;
        case ReportType.yearlyOverview:
          final now = DateTime.now();
          report = await reportsService.generateYearlyOverview(now.year);
          break;
        case ReportType.customComparison:
        case ReportType.yearToYear:
          // These require user input - would need dialogs
          throw UnimplementedError('يتطلب اختيار الأشهر/الأعوام');
      }

      setState(() {
        _currentReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        actions: [
          if (_currentReport != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'تصدير PDF',
              onPressed: () => _exportService.exportToPDF(_currentReport!),
            ),
            IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: 'تصدير Excel',
              onPressed: () async {
                final message = await _exportService.exportToExcel(_currentReport!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نوع التقرير',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<ReportType>(
                    value: _selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: ReportType.monthComparison,
                        child: Text('مقارنة الشهر الحالي مع السابق'),
                      ),
                      DropdownMenuItem(
                        value: ReportType.yearlyOverview,
                        child: Text('ملخص السنة الحالية'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                          _currentReport = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateReport,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: const Text('إنشاء التقرير'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_currentReport != null) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildReportContent(_currentReport!),
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اختر نوع التقرير واضغط "إنشاء التقرير"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(ReportData report) {
    switch (report.type) {
      case ReportType.monthComparison:
      case ReportType.customComparison:
        return _buildComparisonContent(report);
      case ReportType.yearlyOverview:
        return _buildYearlyContent(report);
      case ReportType.yearToYear:
        return _buildYearToYearContent(report);
    }
  }

  Widget _buildComparisonContent(ReportData report) {
    final month1 = report.data['current'] ?? report.data['month1'];
    final month2 = report.data['previous'] ?? report.data['month2'];
    final incomeDiff = report.data['incomeDiff'] as double;
    final expenseDiff = report.data['expenseDiff'] as double;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildMonthCard(month1, 'الشهر الحالي')),
              const SizedBox(width: 16),
              Expanded(child: _buildMonthCard(month2, 'الشهر السابق')),
            ],
          ),
          const SizedBox(height: 24),
          _buildDifferenceCard('فرق الدخل', incomeDiff, Colors.green),
          const SizedBox(height: 12),
          _buildDifferenceCard('فرق المصاريف', expenseDiff, Colors.red),
        ],
      ),
    );
  }

  Widget _buildYearlyContent(ReportData report) {
    final months = report.data['months'] as List;
    final totalIncome = report.data['totalIncome'] as double;
    final totalExpense = report.data['totalExpense'] as double;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildTotalRow('إجمالي الدخل', totalIncome),
                const Divider(color: Colors.white24, height: 24),
                _buildTotalRow('إجمالي المصاريف', totalExpense),
                const Divider(color: Colors.white24, height: 24),
                _buildTotalRow('المتبقي', totalIncome - totalExpense),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'الأشهر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...months.map((month) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'الدخل: ${month.totalIncome.toStringAsFixed(3)} | المصاريف: ${month.totalExpense.toStringAsFixed(3)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildYearToYearContent(ReportData report) {
    return Center(
      child: Text('قريباً...'),
    );
  }

  Widget _buildMonthCard(dynamic month, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            month.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text('الدخل: ${month.totalIncome.toStringAsFixed(3)}'),
          Text('المصاريف: ${month.totalExpense.toStringAsFixed(3)}'),
          Text('المتبقي: ${month.remainingBalance.toStringAsFixed(3)}'),
        ],
      ),
    );
  }

  Widget _buildDifferenceCard(String label, double value, Color color) {
    final isPositive = value >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                value.abs().toStringAsFixed(3),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        Text(
          value.toStringAsFixed(3),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
