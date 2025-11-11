// lib/v2/app/data/services/export_service.dart - FIXED VERSION
import 'dart:developer' as developer;
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import '../models/attendance_model.dart';
// import '../models/dashboard_model.dart';

class ExportService extends GetxService {
  /// Export attendance to Excel - FIXED VERSION
  Future<void> exportAttendanceToExcel({
    required String className,
    required String subjectName,
    required List<StudentAttendanceModel> students,
    required DateTime date,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Absensi'];

      // Clear default sheet if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Header styling - FIXED
      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.amber,
        fontColorHex: ExcelColor.white,
        bold: true,
      );

      // Add title and info
      sheet.cell(CellIndex.indexByString('A1')).value =
          'LAPORAN ABSENSI SISWA' as CellValue?;
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
        fontColorHex: ExcelColor.white,
        bold: true,
      );

      sheet.cell(CellIndex.indexByString('A2')).value =
          'Kelas: $className' as CellValue?;
      sheet.cell(CellIndex.indexByString('A3')).value =
          'Mata Pelajaran: $subjectName' as CellValue?;
      sheet.cell(CellIndex.indexByString('A4')).value =
          'Tanggal: ${_formatDateIndonesian(date)}' as CellValue?;

      // Headers for data table
      const headerRow = 6;
      final headers = ['No', 'NIS', 'Nama Siswa', 'Status', 'Keterangan'];

      for (int i = 0; i < headers.length; i++) {
        final cellAddress = _getColumnLetter(i) + headerRow.toString();
        final cell = sheet.cell(CellIndex.indexByString(cellAddress));
        cell.value = headers[i] as CellValue?;
        cell.cellStyle = headerStyle;
      }

      // Add student data
      for (int i = 0; i < students.length; i++) {
        final student = students[i];
        final rowIndex = headerRow + 1 + i;

        // Data cells
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value =
            (i + 1) as CellValue?;
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value =
            student.nisn as CellValue?;
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value =
            student.name as CellValue?;
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value =
            student.currentStatus.displayName as CellValue?;
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value =
            (student.notes ?? '') as CellValue?;

        // Status cell styling - FIXED
        final statusCell = sheet.cell(CellIndex.indexByString('D$rowIndex'));
        String bgColor = '#9E9E9E';

        switch (student.currentStatus) {
          case AttendanceStatus.hadir:
            bgColor = '#4CAF50';
            break;
          case AttendanceStatus.sakit:
            bgColor = '#2196F3';
            break;
          case AttendanceStatus.izin:
            bgColor = '#FF9800';
            break;
          case AttendanceStatus.alpha:
            bgColor = '#F44336';
            break;
        }

        statusCell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(bgColor),
          fontColorHex: ExcelColor.amber,
          bold: true,
        );
      }

      // Add summary
      final summaryStartRow = headerRow + students.length + 3;
      sheet.cell(CellIndex.indexByString('A$summaryStartRow')).value =
          'RINGKASAN ABSENSI:' as CellValue?;
      sheet
          .cell(CellIndex.indexByString('A$summaryStartRow'))
          .cellStyle = CellStyle(bold: true);

      final summary = _calculateAttendanceSummary(students);
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 1}')).value =
          'Total Siswa: ${students.length}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 2}')).value =
          'Hadir: ${summary['hadir']}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 3}')).value =
          'Sakit: ${summary['sakit']}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 4}')).value =
          'Izin: ${summary['izin']}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 5}')).value =
          'Alpha: ${summary['alpha']}' as CellValue?;

      // Calculate attendance percentage
      final attendancePercentage =
          students.isNotEmpty
              ? (summary['hadir']! / students.length * 100).toStringAsFixed(1)
              : '0';
      sheet.cell(CellIndex.indexByString('A${summaryStartRow + 6}')).value =
          'Persentase Kehadiran: $attendancePercentage%' as CellValue?;

      // Auto-size columns (if available)
      _autoSizeColumns(sheet, headers.length);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Absensi_${className.replaceAll(' ', '_')}_${subjectName.replaceAll(' ', '_')}_${_formatDate(date)}.xlsx';
      final file = File('${directory.path}/$fileName');

      List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);

        // Share file
        // await Share.shareXFiles(
        //   [XFile(file.path)],
        //   text:
        //       'بسم الله - Laporan Absensi $className - $subjectName\nTanggal: ${_formatDateIndonesian(date)}',
        // );

        developer.log('Excel exported successfully: ${file.path}');
      } else {
        throw Exception('Gagal menggenerate file Excel');
      }
    } catch (e) {
      developer.log('Error exporting to Excel: $e');
      throw Exception('Gagal mengekspor ke Excel: ${e.toString()}');
    }
  }

  /// Export attendance history to PDF - SIMPLIFIED VERSION
  Future<void> exportAttendanceHistoryToPDF({
    required StudentHistoryModel studentHistory,
    required String subjectName,
    required String className,
  }) async {
    try {
      final pdf = pw.Document();

      // Create PDF font (use built-in fonts to avoid font loading issues)
      final titleFont = pw.Font.helveticaBold();
      final bodyFont = pw.Font.helvetica();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'My NCH',
                          style: pw.TextStyle(font: titleFont, fontSize: 18),
                        ),
                        pw.Text(
                          'Laporan Riwayat Kehadiran Siswa',
                          style: pw.TextStyle(font: bodyFont, fontSize: 14),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'بسم الله الرحمن الرحيم',
                          style: pw.TextStyle(font: bodyFont, fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Text(
                      _formatDateIndonesian(DateTime.now()),
                      style: pw.TextStyle(font: bodyFont, fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Student Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMASI SISWA',
                      style: pw.TextStyle(font: titleFont, fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Nama: ${studentHistory.name}',
                      style: pw.TextStyle(font: bodyFont),
                    ),
                    pw.Text(
                      'NIS: ${studentHistory.nisn}',
                      style: pw.TextStyle(font: bodyFont),
                    ),
                    pw.Text(
                      'Kelas: ${studentHistory.className}',
                      style: pw.TextStyle(font: bodyFont),
                    ),
                    pw.Text(
                      'Mata Pelajaran: $subjectName',
                      style: pw.TextStyle(font: bodyFont),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RINGKASAN KEHADIRAN',
                      style: pw.TextStyle(font: titleFont, fontSize: 14),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPdfSummaryColumn(
                          '${studentHistory.summary.hadir}',
                          'Hadir',
                          titleFont,
                          bodyFont,
                        ),
                        _buildPdfSummaryColumn(
                          '${studentHistory.summary.sakit}',
                          'Sakit',
                          titleFont,
                          bodyFont,
                        ),
                        _buildPdfSummaryColumn(
                          '${studentHistory.summary.izin}',
                          'Izin',
                          titleFont,
                          bodyFont,
                        ),
                        _buildPdfSummaryColumn(
                          '${studentHistory.summary.alpha}',
                          'Alpha',
                          titleFont,
                          bodyFont,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Persentase Kehadiran: ${studentHistory.summary.attendancePercentage.toStringAsFixed(1)}%',
                      style: pw.TextStyle(font: titleFont, fontSize: 16),
                    ),
                    pw.Text(
                      'Total Pertemuan: ${studentHistory.summary.totalSessions}',
                      style: pw.TextStyle(font: bodyFont, fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // History Table
              pw.Text(
                'RIWAYAT DETAIL KEHADIRAN',
                style: pw.TextStyle(font: titleFont, fontSize: 14),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FlexColumnWidth(),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildPdfTableCell('No', titleFont, 8),
                      _buildPdfTableCell('Tanggal', titleFont, 8),
                      _buildPdfTableCell('Status', titleFont, 8),
                      _buildPdfTableCell('Keterangan', titleFont, 8),
                    ],
                  ),

                  // Table Data
                  ...studentHistory.history.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;

                    return pw.TableRow(
                      children: [
                        _buildPdfTableCell('${index + 1}', bodyFont, 8),
                        _buildPdfTableCell(
                          _formatDateIndonesian(record.date),
                          bodyFont,
                          8,
                        ),
                        _buildPdfTableCell(
                          record.status.displayName,
                          bodyFont,
                          8,
                        ),
                        _buildPdfTableCell(record.notes ?? '-', bodyFont, 8),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'جزاك الله خيرا',
                      style: pw.TextStyle(font: bodyFont, fontSize: 12),
                    ),
                    pw.Text(
                      'Semoga bermanfaat untuk kemajuan pendidikan',
                      style: pw.TextStyle(
                        font: bodyFont,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Riwayat_${studentHistory.name.replaceAll(' ', '_')}_${_formatDate(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share PDF
      // await Share.shareXFiles(
      //   [XFile(file.path)],
      //   text:
      //       'بسم الله - Riwayat Kehadiran ${studentHistory.name} - $subjectName',
      // );

      developer.log('PDF exported successfully: ${file.path}');
    } catch (e) {
      developer.log('Error exporting to PDF: $e');
      throw Exception('Gagal mengekspor ke PDF: ${e.toString()}');
    }
  }

  /// Export class summary to Excel
  Future<void> exportClassSummaryToExcel({
    required TeacherClassModel teacherClass,
    required String period,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Rekap Kelas'];

      // Clear default sheet
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Title and class info
      sheet.cell(CellIndex.indexByString('A1')).value =
          'REKAP KEHADIRAN KELAS' as CellValue?;
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
        fontColorHex: ExcelColor.white,
        bold: true,
      );

      sheet.cell(CellIndex.indexByString('A2')).value =
          'Kelas: ${teacherClass.className}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A3')).value =
          'Mata Pelajaran: ${teacherClass.subjectName}' as CellValue?;
      sheet.cell(CellIndex.indexByString('A4')).value =
          'Periode: $period' as CellValue?;
      sheet.cell(CellIndex.indexByString('A5')).value =
          'Total Siswa: ${teacherClass.studentCount}' as CellValue?;

      // Headers for student data
      const headerRow = 7;
      final headers = [
        'No',
        'NIS',
        'Nama Siswa',
        'Persentase Kehadiran',
        'Status',
      ];

      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
        fontColorHex: ExcelColor.white,
        bold: true,
      );

      for (int i = 0; i < headers.length; i++) {
        final cellAddress = _getColumnLetter(i) + headerRow.toString();
        final cell = sheet.cell(CellIndex.indexByString(cellAddress));
        cell.value = headers[i] as CellValue?;
        cell.cellStyle = headerStyle;
      }

      // Student data
      for (int i = 0; i < teacherClass.students.length; i++) {
        final student = teacherClass.students[i];
        final rowIndex = headerRow + 1 + i;

        sheet.cell(CellIndex.indexByString('A$rowIndex')).value =
            (i + 1) as CellValue?;
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value =
            student.nisn as CellValue?;
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value =
            student.name as CellValue?;
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value =
            '${student.attendancePercentage.toStringAsFixed(1)}%' as CellValue?;

        // Status based on attendance percentage
        String status = '';
        String statusColor = '#9E9E9E';

        if (student.attendancePercentage >= 90) {
          status = 'Sangat Baik';
          statusColor = '#4CAF50';
        } else if (student.attendancePercentage >= 75) {
          status = 'Baik';
          statusColor = '#FF9800';
        } else {
          status = 'Perlu Perhatian';
          statusColor = '#F44336';
        }

        final statusCell = sheet.cell(CellIndex.indexByString('E$rowIndex'));
        statusCell.value = status as CellValue?;
        statusCell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(statusColor),
          fontColorHex: ExcelColor.white,
          bold: true,
        );
      }

      // Calculate class average
      final classAverage =
          teacherClass.students.isNotEmpty
              ? teacherClass.students
                      .map((s) => s.attendancePercentage)
                      .reduce((a, b) => a + b) /
                  teacherClass.students.length
              : 0.0;

      final summaryRow = headerRow + teacherClass.students.length + 2;
      sheet.cell(CellIndex.indexByString('A$summaryRow')).value =
          'Rata-rata Kelas: ${classAverage.toStringAsFixed(1)}%' as CellValue?;
      sheet.cell(CellIndex.indexByString('A$summaryRow')).cellStyle = CellStyle(
        bold: true,
      );

      // Auto-size columns
      _autoSizeColumns(sheet, headers.length);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Rekap_${teacherClass.className.replaceAll(' ', '_')}_${teacherClass.subjectName.replaceAll(' ', '_')}_${_formatDate(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');

      List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);

        // Share file
        // await Share.shareXFiles(
        //   [XFile(file.path)],
        //   text:
        //       'بسم الله - Rekap Kehadiran Kelas ${teacherClass.className}\nMata Pelajaran: ${teacherClass.subjectName}',
        // );

        developer.log('Class summary exported successfully');
      } else {
        throw Exception('Gagal menggenerate file Excel');
      }
    } catch (e) {
      developer.log('Error exporting class summary: $e');
      throw Exception('Gagal mengekspor rekap kelas: ${e.toString()}');
    }
  }

  // Helper methods
  Map<String, int> _calculateAttendanceSummary(
    List<StudentAttendanceModel> students,
  ) {
    final summary = <String, int>{
      'hadir': 0,
      'sakit': 0,
      'izin': 0,
      'alpha': 0,
    };

    for (final student in students) {
      switch (student.currentStatus) {
        case AttendanceStatus.hadir:
          summary['hadir'] = (summary['hadir'] ?? 0) + 1;
          break;
        case AttendanceStatus.sakit:
          summary['sakit'] = (summary['sakit'] ?? 0) + 1;
          break;
        case AttendanceStatus.izin:
          summary['izin'] = (summary['izin'] ?? 0) + 1;
          break;
        case AttendanceStatus.alpha:
          summary['alpha'] = (summary['alpha'] ?? 0) + 1;
          break;
      }
    }

    return summary;
  }

  String _getColumnLetter(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index < 26) {
      return letters[index];
    } else {
      return letters[(index / 26).floor() - 1] + letters[index % 26];
    }
  }

  void _autoSizeColumns(Sheet sheet, int columnCount) {
    // Basic auto-sizing logic - can be improved
    for (int i = 0; i < columnCount; i++) {
      // This is a basic implementation
      // The excel package might not support auto-sizing
      // but we can set reasonable column widths
    }
  }

  pw.Widget _buildPdfSummaryColumn(
    String value,
    String label,
    pw.Font titleFont,
    pw.Font bodyFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: titleFont, fontSize: 18)),
        pw.Text(label, style: pw.TextStyle(font: bodyFont, fontSize: 12)),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, pw.Font font, double padding) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateIndonesian(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }
}
