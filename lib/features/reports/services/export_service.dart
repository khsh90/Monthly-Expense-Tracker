import 'dart:io';
import 'package:excel/excel.dart';
import 'package:expense_tracker/features/months/models/month.dart';
import 'package:expense_tracker/features/reports/models/report_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class ExportService {
  Future<void> exportToPDF(ReportData report) async {
    final pdf = pw.Document();

    // Load Arabic font
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                report.title,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              ..._buildPDFContent(report),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<String> exportToExcel(ReportData report) async {
    try {
      print('=== EXCEL EXPORT DEBUG ===');
      print('Report title: ${report.title}');
      print('Report type: ${report.type}');
      print('Report data keys: ${report.data.keys.toList()}');
      print('Report data: ${report.data}');

      var excel = Excel.createExcel();

      // Delete default sheet
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Create our report sheet
      excel.copy('Sheet1', 'Report');
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      Sheet sheet = excel['Report'];

      // Add title
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(report.title);

      // Add empty row
      var emptyCell = sheet.cell(CellIndex.indexByString('A2'));
      emptyCell.value = TextCellValue('');

      // Add content based on report type (starting from row 3)
      _addExcelContent(sheet, report, startingRow: 2);

      print('Excel content added. Total rows: ${sheet.maxRows}');

      // Save file
      final fileBytes = excel.save();
    
      if (fileBytes == null) {
        return 'فشل في إنشاء الملف';
      }

      if (kIsWeb) {
        // For web: trigger download
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'report_${DateTime.now().millisecondsSinceEpoch}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'تم تنزيل الملف';
      } else {
        // For mobile/desktop: save to file
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return 'تم حفظ الملف في: $filePath';
      }
    } catch (e) {
      return 'خطأ في التصدير: $e';
    }
  }

  List<pw.Widget> _buildPDFContent(ReportData report) {
    switch (report.type) {
      case ReportType.monthComparison:
      case ReportType.customComparison:
        return _buildComparisonPDF(report);
      case ReportType.yearlyOverview:
        return _buildYearlyPDF(report);
      case ReportType.yearToYear:
        return _buildYearToYearPDF(report);
    }
  }

  List<pw.Widget> _buildComparisonPDF(ReportData report) {
    final month1 = report.data['current'] as Month? ?? report.data['month1'] as Month;
    final month2 = report.data['previous'] as Month? ?? report.data['month2'] as Month;
    
    return [
      pw.Text('${month1.name}: الدخل ${month1.totalIncome.toStringAsFixed(3)} - المصاريف ${month1.totalExpense.toStringAsFixed(3)}'),
      pw.SizedBox(height: 10),
      pw.Text('${month2.name}: الدخل ${month2.totalIncome.toStringAsFixed(3)} - المصاريف ${month2.totalExpense.toStringAsFixed(3)}'),
      pw.SizedBox(height: 10),
      pw.Text('الفرق في الدخل: ${report.data['incomeDiff'].toStringAsFixed(3)}'),
      pw.Text('الفرق في المصاريف: ${report.data['expenseDiff'].toStringAsFixed(3)}'),
    ];
  }

  List<pw.Widget> _buildYearlyPDF(ReportData report) {
    return [
      pw.Text('إجمالي الدخل: ${report.data['totalIncome'].toStringAsFixed(3)}'),
      pw.Text('إجمالي المصاريف: ${report.data['totalExpense'].toStringAsFixed(3)}'),
      pw.Text('المتبقي: ${report.data['totalBalance'].toStringAsFixed(3)}'),
      pw.Text('عدد الأشهر: ${report.data['monthCount']}'),
    ];
  }

  List<pw.Widget> _buildYearToYearPDF(ReportData report) {
    return [
      pw.Text('عام ${report.data['year1']}: الدخل ${report.data['year1Income'].toStringAsFixed(3)} - المصاريف ${report.data['year1Expense'].toStringAsFixed(3)}'),
      pw.Text('عام ${report.data['year2']}: الدخل ${report.data['year2Income'].toStringAsFixed(3)} - المصاريف ${report.data['year2Expense'].toStringAsFixed(3)}'),
      pw.Text('الفرق في الدخل: ${report.data['incomeDiff'].toStringAsFixed(3)}'),
      pw.Text('الفرق in المصاريف: ${report.data['expenseDiff'].toStringAsFixed(3)}'),
    ];
  }

  void _addExcelContent(Sheet sheet, ReportData report, {int startingRow = 0}) {
    try {
      print('Adding Excel content for type: ${report.type}');
      switch (report.type) {
        case ReportType.monthComparison:
        case ReportType.customComparison:
          print('Processing month comparison...');
          final month1 = (report.data['current'] ?? report.data['month1']) as Month?;
          final month2 = (report.data['previous'] ?? report.data['month2']) as Month?;

          print('Month1: ${month1?.name}, Month2: ${month2?.name}');

          if (month1 == null || month2 == null) {
            print('ERROR: One or both months are null!');
            sheet.appendRow([TextCellValue('لا توجد بيانات للمقارنة')]);
            break;
          }

          print('Adding month comparison data to Excel...');

          sheet.appendRow([
            TextCellValue('الشهر'),
            TextCellValue('الدخل'),
            TextCellValue('المصاريف'),
            TextCellValue('المتبقي')
          ]);
          sheet.appendRow([
            TextCellValue(month1.name),
            DoubleCellValue(month1.totalIncome),
            DoubleCellValue(month1.totalExpense),
            DoubleCellValue(month1.remainingBalance)
          ]);
          sheet.appendRow([
            TextCellValue(month2.name),
            DoubleCellValue(month2.totalIncome),
            DoubleCellValue(month2.totalExpense),
            DoubleCellValue(month2.remainingBalance)
          ]);
          break;
        
        case ReportType.yearlyOverview:
          final months = report.data['months'] as List<Month>?;

          if (months == null || months.isEmpty) {
            sheet.appendRow([TextCellValue('لا توجد بيانات لهذا العام')]);
            break;
          }

          sheet.appendRow([
            TextCellValue('الشهر'),
            TextCellValue('الدخل'),
            TextCellValue('المصاريف'),
            TextCellValue('المتبقي')
          ]);
          for (var month in months) {
            sheet.appendRow([
              TextCellValue(month.name),
              DoubleCellValue(month.totalIncome),
              DoubleCellValue(month.totalExpense),
              DoubleCellValue(month.remainingBalance)
            ]);
          }
          sheet.appendRow([]);
          sheet.appendRow([
            TextCellValue('الإجمالي'),
            DoubleCellValue((report.data['totalIncome'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((report.data['totalExpense'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((report.data['totalBalance'] as num?)?.toDouble() ?? 0.0)
          ]);
          break;
        
        case ReportType.yearToYear:
          sheet.appendRow([
            TextCellValue('العام'),
            TextCellValue('الدخل'),
            TextCellValue('المصاريف')
          ]);
          sheet.appendRow([
            IntCellValue((report.data['year1'] as num?)?.toInt() ?? 0),
            DoubleCellValue((report.data['year1Income'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((report.data['year1Expense'] as num?)?.toDouble() ?? 0.0)
          ]);
          sheet.appendRow([
            IntCellValue((report.data['year2'] as num?)?.toInt() ?? 0),
            DoubleCellValue((report.data['year2Income'] as num?)?.toDouble() ?? 0.0),
            DoubleCellValue((report.data['year2Expense'] as num?)?.toDouble() ?? 0.0)
          ]);
          break;
      }
    } catch (e) {
      sheet.appendRow([TextCellValue('خطأ في إنشاء التقرير: $e')]);
    }
  }
}
