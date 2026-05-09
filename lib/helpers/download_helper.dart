import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DownloadHelper {
  /// Download or share PDF based on platform
  static Future<void> downloadPdf(
    Uint8List pdfBytes,
    String filename,
  ) async {
    if (kIsWeb) {
      // Web: Trigger browser download
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } else {
      // Mobile: Open share dialog
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    }
  }

  /// Generate filename for PDF
  static String generateFilename() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'attendance_$year$month${day}_$hour$minute$second.pdf';
  }
}
