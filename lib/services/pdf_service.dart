import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/attendance_record.dart';
import '../helpers/semester_helper.dart';

class PdfService {
  Future<Uint8List> generateAttendancePdf(
    List<AttendanceRecord> records,
    DateTime currentDate,
    String adminName, {
    DateTime? startTime,
    DateTime? endTime,
    String? subjectName,
    String? unitName,
  }) async {
    final pdf = pw.Document();

    if (records.isEmpty) {
      return pdf.save();
    }

    // Group students by branch
    final Map<String, List<AttendanceRecord>> branchGroups = {};

    for (final record in records) {
      final branch = SemesterHelper.extractBranch(record.studentId);
      if (!branchGroups.containsKey(branch)) {
        branchGroups[branch] = [];
      }
      branchGroups[branch]!.add(record);
    }

    // Format date and time once
    final formattedDate = SemesterHelper.formatDate(currentDate);

    final formattedTime = SemesterHelper.formatTime(currentDate);
    final startStr = startTime != null ? SemesterHelper.formatTime(startTime) : '-';
    final endStr = endTime != null ? SemesterHelper.formatTime(endTime) : '-';

    // Create a page for each branch
    for (final branchEntry in branchGroups.entries) {
      final branch = branchEntry.key;
      final branchRecords = branchEntry.value;

      // Calculate semester from first student in this branch
      final semester = SemesterHelper.calculateSemester(
        branchRecords.first.studentId,
        currentDate,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo700,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Attendance Sheet',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Admin: $adminName',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text(
                            'Start Class: $startStr',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Text(
                            'End Class: $endStr',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      // Branch & Subject Line
                      pw.Row(
                        children: [
                          pw.Text(
                            'Branch: $branch',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.white,
                            ),
                          ),
                          if (subjectName != null) ...[
                            pw.SizedBox(width: 20),
                            pw.Flexible(
                              child: pw.Text(
                                'Subject: $subjectName',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (unitName != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Unit: $unitName',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey200,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Date: $formattedDate',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Time: $formattedTime',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(60), // Serial Number
                    1: const pw.FixedColumnWidth(120), // Student ID
                    2: const pw.FlexColumnWidth(3), // Student Name
                    3: const pw.FixedColumnWidth(80), // Present
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildTableHeader('S.No'),
                        _buildTableHeader('Student ID'),
                        _buildTableHeader('Student Name'),
                        _buildTableHeader('Status'),
                      ],
                    ),

                    // Table Rows
                    ...branchRecords.asMap().entries.map((entry) {
                      final index = entry.key;
                      final record = entry.value;
                      return _buildTableRow(
                        index + 1,
                        record.studentId,
                        record.studentName,
                        record.status == AttendanceStatus.present,
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Footer
                pw.Text(
                  'Total Students: ${branchRecords.length}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Build table header cell
  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build table data row
  pw.TableRow _buildTableRow(
    int serialNo,
    String studentId,
    String studentName,
    bool isPresent,
  ) {
    return pw.TableRow(
      children: [
        _buildTableCell(serialNo.toString()),
        _buildTableCell(studentId),
        _buildTableCell(studentName),
        _buildTableCell(isPresent ? '✔' : '❌'),
      ],
    );
  }

  /// Build table data cell
  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
