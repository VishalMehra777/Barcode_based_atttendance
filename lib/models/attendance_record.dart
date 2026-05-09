class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime timestamp;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.status,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$hour:$minute • $day/$month/$year';
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    studentId: json['studentId'],
    studentName: json['studentName'],
    timestamp: DateTime.parse(json['timestamp']),
    status: AttendanceStatus.values[json['status']],
  );
}

enum AttendanceStatus {
  present,
  invalid,
}
