class SemesterHelper {
  /// Extract year digit(s) from student ID (e.g., PAC7SD3-44 → 7, PAC11MS2-518 → 11)
  static int extractYearDigit(String studentId) {
    if (studentId.length < 4) return 0;
    
    // Try to extract 1 or 2 digits after "PAC"
    // Pattern: PAC[year][branch]...
    // Look for digits after position 3
    final yearPart = studentId.substring(3);
    final yearMatch = RegExp(r'^\d+').firstMatch(yearPart);
    
    if (yearMatch != null) {
      return int.tryParse(yearMatch.group(0)!) ?? 0;
    }
    
    return 0;
  }

  /// Extract branch code from student ID (e.g., PAC7SD3-44 → SD, PAC11MS2-518 → MS)
  static String extractBranch(String studentId) {
    if (studentId.length < 4) return 'N/A';
    
    // Extract the year digits first to know where branch starts
    final yearPart = studentId.substring(3);
    final yearMatch = RegExp(r'^\d+').firstMatch(yearPart);
    
    if (yearMatch != null) {
      final yearLength = yearMatch.group(0)!.length;
      final branchStartIndex = 3 + yearLength;
      
      // Extract 2 characters for branch code
      if (studentId.length >= branchStartIndex + 2) {
        return studentId.substring(branchStartIndex, branchStartIndex + 2).toUpperCase();
      }
    }
    
    return 'N/A';
  }

  /// Calculate admission year from year digit
  /// Year digit 7 → 2027
  static int calculateAdmissionYear(int yearDigit) {
    return 2020 + yearDigit;
  }

  /// Determine if current month is in even semester (Jan-Jun)
  static bool isEvenSemester(DateTime date) {
    return date.month >= 1 && date.month <= 6;
  }

  /// Calculate current semester based on admission year and current date
  /// Returns semester number (1-8)
  static int calculateSemester(String studentId, DateTime currentDate) {
    final yearDigit = extractYearDigit(studentId);
    final admissionYear = calculateAdmissionYear(yearDigit);
    
    final currentYear = currentDate.year;
    final yearDifference = currentYear - admissionYear;
    
    // If admission is in future, student hasn't started yet
    if (yearDifference < 0) {
      return 1;
    }
    
    // Calculate semester: each year has 2 semesters
    // Jan-Jun → Even semester (2, 4, 6, 8)
    // Jul-Dec → Odd semester (1, 3, 5, 7)
    final baseSemester = yearDifference * 2;
    final semesterOffset = isEvenSemester(currentDate) ? 2 : 1;
    
    return baseSemester + semesterOffset;
  }

  /// Get semester display string
  static String getSemesterDisplay(int semester) {
    return 'Semester $semester';
  }

  /// Format date for PDF header
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Format time for PDF header
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
