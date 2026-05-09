// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/student_model.dart';

// class ApiService {
//   static const String baseUrl = 'https://vishalmehra05.github.io/attendancesheet';

//   /// Fetches the list of students from the GitHub Pages API
//   Future<List<Student>> fetchStudents(String branch, String year) async {
//     // Construct URL: e.g., sd1.json
//     final String fileName = '${branch.toLowerCase()}$year.json';
//     final String url = '$baseUrl/$fileName';

//     try {
//       final response = await http.get(Uri.parse(url));

//       if (response.statusCode == 200) {
//         final List<dynamic> jsonData = json.decode(response.body);
//         return jsonData.map((json) => Student.fromJson(json)).toList();
//       } else if (response.statusCode == 404) {
//         throw Exception('Data file not found for $branch - $year Year ($fileName)');
//       } else {
//         throw Exception('Failed to load students: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error fetching students: $e');
//     }
//   }

//   /// Validates if a student ID exists in the API for the given branch and year
//   Future<Student?> validateStudentId(String scannedId, String branch, String year) async {
//     try {
//       final students = await fetchStudents(branch, year);

//       // Search for student by ID
//       for (var student in students) {
//         if (student.id == scannedId) {
//           return student;
//         }
//       }

//       // Student not found
//       return null;
//     } catch (e) {
//       rethrow;
//     }
//   }
// }


import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';
import '../models/branch_data_model.dart';

class ApiService {
  // 🔗 Base GitHub Pages URL
  static const String baseUrl =
      'https://vishalmehra05.github.io/attendancesheet';

  /// 🔹 Fetch Branch Data (Students + Subjects) by branch & year
  /// Example file: sd3.json, ai2.json
  Future<BranchData> fetchBranchData(String branch, int year) async {
    final String fileName = '${branch.toLowerCase()}$year.json';
    final String url = '$baseUrl/$fileName';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 🔹 Sanitize JSON (Remove trailing commas which are invalid in JSON)
        final String cleanJson =
            response.body.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
        final dynamic decodedData = json.decode(cleanJson);

        if (decodedData is Map<String, dynamic>) {
          // ✅ New Format: { branch, year, subjects, students }
          return BranchData.fromJson(decodedData);
        } else if (decodedData is List) {
          // ⚠️ Legacy Format: [ {id, name}, ... ]
          // Treat as students only, no subjects
          final List<Student> students = decodedData
              .map((e) => Student.fromJson(e as Map<String, dynamic>))
              .toList();

          return BranchData(
            branch: branch,
            year: year,
            subjects: [],
            students: students,
          );
        } else {
          throw Exception('❌ Invalid data format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('❌ File not found: $fileName');
      } else {
        throw Exception(
            '❌ Failed to load data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('❌ Error fetching data: $e');
    }
  }

  /// 🔹 Legacy support: Fetch students only (using new structure internally)
  Future<List<Student>> fetchStudents(String branch, int year) async {
    final data = await fetchBranchData(branch, year);
    return data.students;
  }

  /// 🔹 Validate scanned student ID
  /// Returns Student if valid, else null
  Future<Student?> validateStudentId(
      String scannedId, String branch, int year) async {
    try {
      final data = await fetchBranchData(branch, year);

      for (final student in data.students) {
        if (student.id.trim() == scannedId.trim()) {
          return student;
        }
      }

      // ❌ Student not found
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
