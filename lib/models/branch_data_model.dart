import 'student_model.dart';

class BranchData {
  final String branch;
  final int year;
  final List<Subject> subjects;
  final List<Student> students;

  BranchData({
    required this.branch,
    required this.year,
    required this.subjects,
    required this.students,
  });

  factory BranchData.fromJson(Map<String, dynamic> json) {
    return BranchData(
      branch: json['branch'] ?? '',
      year: json['year'] ?? 0,
      subjects: json['subjects'] != null
          ? (json['subjects'] as List).map((e) => Subject.fromJson(e)).toList()
          : [],
      students: json['students'] != null
          ? (json['students'] as List).map((e) => Student.fromJson(e)).toList()
          : [],
    );
  }
}

class Subject {
  final String subjectCode;
  final String subjectName;
  final List<Unit> units;

  Subject({
    required this.subjectCode,
    required this.subjectName,
    required this.units,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      units: json['units'] != null
          ? (json['units'] as List).map((e) => Unit.fromJson(e)).toList()
          : [],
    );
  }

  // Override equality for Dropdown
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          subjectCode == other.subjectCode &&
          subjectName == other.subjectName; // Assuming name/code combination is unique enough

  @override
  int get hashCode => subjectCode.hashCode ^ subjectName.hashCode;
}

class Unit {
  final int unitId;
  final String unitName;

  Unit({
    required this.unitId,
    required this.unitName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unitId: json['unitId'] ?? 0,
      unitName: json['unitName'] ?? '',
    );
  }

  // Override equality for Dropdown
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          unitId == other.unitId &&
          unitName == other.unitName;

  @override
  int get hashCode => unitId.hashCode ^ unitName.hashCode;
}
