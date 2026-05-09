import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../screens/scanner_screen.dart';
import '../widgets/result_dialog.dart';
import '../helpers/download_helper.dart';
import '../helpers/semester_helper.dart';
import '../models/branch_data_model.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final List<AttendanceRecord> _attendanceRecords = [];
  final ApiService _apiService = ApiService();
  final PdfService _pdfService = PdfService();

  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;

  String? _selectedBranch;
  String? _selectedYear; // keep string for dropdown

  final List<String> _branches = [
    'SD',
    'WD',
    'AI',
    'DS',
    'CC',
    'CB',
    'MSC(M)',
    'BSC-M(H)',
    'BSC-M(P)',
  ];
  final List<String> _years = ['1', '2', '3'];

  Future<void> _fetchBranchData() async {
    if (_selectedBranch == null || _selectedYear == null) return;

    setState(() {
      _isFetchingData = true;
      _subjects = [];
      _selectedSubject = null;
      _selectedUnit = null;
    });

    try {
      final data = await _apiService.fetchBranchData(
        _selectedBranch!,
        int.parse(_selectedYear!),
      );

      if (mounted) {
        setState(() {
          _subjects = data.subjects;
          _isFetchingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔹 Subject & Unit Data
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  Unit? _selectedUnit;
  bool _isFetchingData = false;

  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _checkDateAndLoadData();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('admin_name') ?? 'Admin';
    });
  }

  Future<void> _checkDateAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedDateStr = prefs.getString('attendance_date');
    final String? savedData = prefs.getString('attendance_records');

    if (savedDateStr == null || savedData == null) {
      // No data, set today as date
      await prefs.setString(
        'attendance_date',
        DateTime.now().toIso8601String().split('T').first,
      );
      return;
    }

    final DateTime savedDate = DateTime.parse(savedDateStr);
    final DateTime now = DateTime.now();

    // Compare dates (ignoring time)
    final bool isSameDay =
        savedDate.year == now.year &&
        savedDate.month == now.month &&
        savedDate.day == now.day;

    if (isSameDay) {
      // Load today's data
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _attendanceRecords.clear();
        _attendanceRecords.addAll(
          decoded.map((e) => AttendanceRecord.fromJson(e)).toList(),
        );
      });
    } else {
      // Data is from a previous day
      final List<dynamic> decoded = jsonDecode(savedData);
      final List<AttendanceRecord> oldRecords = decoded
          .map((e) => AttendanceRecord.fromJson(e))
          .toList();

      if (oldRecords.isNotEmpty) {
        // Show dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPreviousDayDialog(oldRecords, savedDate);
        });
      } else {
        // Empty old data, just clear
        await _clearAttendanceData();
      }
    }
  }

  Future<void> _showPreviousDayDialog(
    List<AttendanceRecord> oldRecords,
    DateTime date,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Previous Attendance Found'),
        content: Text(
          'Attendance data from ${date.day}/${date.month}/${date.year} was found. Do you want to share it before clearing?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Delete
              await _clearAttendanceData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Share PDF
              await _generatePdfForRecords(oldRecords, date);
              await _clearAttendanceData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Share PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('attendance_records');

    // Clear all session times
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('session_start_') || key.startsWith('session_end_')) {
        await prefs.remove(key);
      }
    }

    // Set new date
    await prefs.setString(
      'attendance_date',
      DateTime.now().toIso8601String().split('T').first,
    );
    setState(() {
      _attendanceRecords.clear();
      _sessionStartTime = null;
      _sessionEndTime = null;
    });
  }

  Future<void> _saveAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(
      _attendanceRecords.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('attendance_records', data);
    // Ensure date is today
    await prefs.setString(
      'attendance_date',
      DateTime.now().toIso8601String().split('T').first,
    );
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      await _validateAndMarkAttendance(result);
    }
  }

  Future<void> _startContinuousScan() async {
    if (_selectedBranch == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Branch and Year first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          continuous: true,
          onScan: _handleContinuousScan, // Pass callback
        ),
      ),
    );

    // Refresh UI after returning
    setState(() {});
  }

  Future<bool> _handleContinuousScan(String code) async {
    try {
      final result = await _processScan(code);
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadSessionTimes() async {
    if (_selectedBranch == null || _selectedYear == null) {
      setState(() {
        _sessionStartTime = null;
        _sessionEndTime = null;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final keySuffix = '${_selectedBranch}_${_selectedYear}';
    final startStr = prefs.getString('session_start_$keySuffix');
    final endStr = prefs.getString('session_end_$keySuffix');

    setState(() {
      _sessionStartTime = startStr != null ? DateTime.tryParse(startStr) : null;
      _sessionEndTime = endStr != null ? DateTime.tryParse(endStr) : null;
    });
  }

  Future<void> _handleSessionButton() async {
    if (_selectedBranch == null || _selectedYear == null) return;

    final prefs = await SharedPreferences.getInstance();
    final keySuffix = '${_selectedBranch}_${_selectedYear}';

    if (_sessionStartTime == null) {
      // Start Class
      final now = DateTime.now();
      await prefs.setString('session_start_$keySuffix', now.toIso8601String());
      setState(() {
        _sessionStartTime = now;
      });
    } else if (_sessionEndTime == null) {
      // End Class
      final now = DateTime.now();
      await prefs.setString('session_end_$keySuffix', now.toIso8601String());
      setState(() {
        _sessionEndTime = now;
      });
    }
  }

  Future<void> _validateAndMarkAttendance(String scannedId) async {
    setState(() => _isLoading = true);

    try {
      final result = await _processScan(scannedId);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result.isSuccess) {
        showDialog(
          context: context,
          builder: (_) => ResultDialog(
            isValid: true,
            studentName: result.studentName ?? '',
          ),
        );
      } else {
        if (result.error == 'Duplicate') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.studentName} already marked present'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => const ResultDialog(isValid: false, studentName: ''),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Returns a status object/enum or simpler class
  Future<ScanResult> _processScan(String scannedId) async {
    if (_selectedBranch == null || _selectedYear == null) {
      throw Exception('Please select Branch and Year');
    }

    final int year = int.parse(_selectedYear!);

    final student = await _apiService.validateStudentId(
      scannedId,
      _selectedBranch!,
      year,
    );

    if (student == null) {
      return ScanResult(isSuccess: false, error: 'Invalid');
    }

    final alreadyMarked = _attendanceRecords.any(
      (e) => e.studentId == student.id,
    );

    if (alreadyMarked) {
      return ScanResult(
        isSuccess: false,
        error: 'Duplicate',
        studentName: student.name,
      );
    }

    _attendanceRecords.insert(
      0,
      AttendanceRecord(
        studentId: student.id,
        studentName: student.name,
        timestamp: DateTime.now(),
        status: AttendanceStatus.present,
      ),
    );

    // Save data
    await _saveAttendanceData();

    return ScanResult(isSuccess: true, studentName: student.name);
  }

  Future<void> _generatePdf() async {
    if (_attendanceRecords.isEmpty) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final filteredRecords = _attendanceRecords.where((record) {
        if (_selectedBranch == null || _selectedYear == null) return true;

        final branch = SemesterHelper.extractBranch(record.studentId);
        // Basic check, might need more robust matching using SemesterHelper
        // Assuming API valid branch matches selected branch
        if (branch != _selectedBranch) return false;

        // Year check - this is tricky as ID doesn't directly map to year easily without context of current year
        // But the user said "know in the pdf secssion record only those selected the strean or year"
        // Let's filter by branch mostly.
        return true;
      }).toList();

      final pdfBytes = await _pdfService.generateAttendancePdf(
        _selectedBranch != null ? filteredRecords : _attendanceRecords,
        DateTime.now(),
        _adminName,
        startTime: _sessionStartTime,
        endTime: _sessionEndTime,
        subjectName: _selectedSubject?.subjectName,
        unitName: _selectedUnit?.unitName,
      );

      final fileName = DownloadHelper.generateFilename();
      await DownloadHelper.downloadPdf(pdfBytes, fileName);

      _isGeneratingPdf = false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _isGeneratingPdf = false;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() {});
  }

  Future<void> _generatePdfForRecords(
    List<AttendanceRecord> records,
    DateTime date,
  ) async {
    try {
      final pdfBytes = await _pdfService.generateAttendancePdf(
        records,
        date,
        _adminName,
      );
      final fileName = DownloadHelper.generateFilename();
      await DownloadHelper.downloadPdf(pdfBytes, fileName);
    } catch (e) {
      debugPrint('Error generating old PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // appBar: AppBar(
      //   backgroundColor: Colors.indigo,
      //   title: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text('Welcome, $_adminName'),
      //       Text(
      //         '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      //         style: const TextStyle(fontSize: 12, color: Colors.white70),
      //       ),
      //     ],
      //   ),
      // ),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Circular Logo
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/logo.jpeg'),
              ),
            ),
            const SizedBox(width: 15),
            // Title
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: "Center of Excellence ",
                    style: TextStyle(color: Color.fromARGB(255, 2, 17, 124)),
                  ),
                  // TextSpan(
                  //   text: "Ease",
                  //   style: TextStyle(color: Colors.orange),
                  // ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/p.png'),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Welcome & Date Container
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _adminName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 28, // Large font size as requested
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scan Container
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   colors: [Colors.indigo.shade600, Colors.indigo.shade400],
              // ),
              color: Color.fromARGB(255, 2, 17, 124),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _branchDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _yearDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (_isLoading ||
                                  _selectedBranch == null ||
                                  _selectedYear == null ||
                                  _selectedSubject == null ||
                                  _selectedUnit == null)
                              ? null
                              : _scanBarcode,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Single Scan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (_isLoading ||
                                  _selectedBranch == null ||
                                  _selectedYear == null ||
                                  _selectedSubject == null ||
                                  _selectedUnit == null)
                              ? null
                              : _startContinuousScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Continuous'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                  // Subject & Unit Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Subject>(
                              hint: const Text(
                                'Subject',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _selectedSubject,
                              dropdownColor: Colors.indigo,
                              icon: _isFetchingData
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                              style: const TextStyle(color: Colors.white),
                              isExpanded: true,
                              items: _subjects.map((Subject subject) {
                                return DropdownMenuItem<Subject>(
                                  value: subject,
                                  child: Text(
                                    subject.subjectName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (Subject? newValue) {
                                setState(() {
                                  _selectedSubject = newValue;
                                  _selectedUnit = null; // Reset unit
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Unit>(
                              hint: const Text(
                                'Unit',
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _selectedUnit,
                              dropdownColor: Colors.indigo,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              style: const TextStyle(color: Colors.white),
                              isExpanded: true,
                              items:
                                  _selectedSubject?.units.map((Unit unit) {
                                    return DropdownMenuItem<Unit>(
                                      value: unit,
                                      child: Text(unit.unitName),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (Unit? newValue) {
                                setState(() {
                                  _selectedUnit = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                if (_selectedBranch != null && _selectedYear != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sessionEndTime != null
                          ? null
                          : _handleSessionButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sessionStartTime == null
                            ? Colors.green
                            : (_sessionEndTime == null
                                  ? Colors.red
                                  : Colors.grey),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _sessionStartTime == null
                            ? 'Start Class'
                            : (_sessionEndTime == null
                                  ? 'End Class'
                                  : 'Class Ended'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _attendanceList()),
        ],
      ),
      floatingActionButton: _attendanceRecords.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isGeneratingPdf ? null : _generatePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate PDF'),
            ),
    );
  }

  // Widget _branchDropdown() {
  //   return DropdownButtonFormField<String>(
  //     value: _selectedBranch,
  //     hint: const Text('Branch'),

  //     items: _branches
  //         .map((b) => DropdownMenuItem(value: b, child: Text(b)))
  //         .toList(),
  //     onChanged: (v) => setState(() => _selectedBranch = v),
  //   );
  // }
  Widget _branchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBranch,

      // ✅ Selected value text color
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),

      // ✅ Hint text color
      hint: const Text('Branch', style: TextStyle(color: Colors.white70)),

      // ✅ Dropdown menu background color (dark)
      dropdownColor: Colors.indigo,

      items: _branches
          .map(
            (b) => DropdownMenuItem(
              value: b,
              child: Text(
                b,
                style: const TextStyle(
                  color: Colors.white, // ✅ item text white
                ),
              ),
            ),
          )
          .toList(),

      onChanged: (v) {
        setState(() => _selectedBranch = v);
        _loadSessionTimes();
        _fetchBranchData();
      },

      // ✅ Border style (optional but recommended for dark bg)
      decoration: const InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  // Widget _yearDropdown() {
  //   return DropdownButtonFormField<String>(
  //     value: _selectedYear,
   //     hint: const Text('Year'),
  //     items: _years
  //         .map((y) => DropdownMenuItem(value: y, child: Text('$y Year')))
  //         .toList(),
  //     onChanged: (v) => setState(() => _selectedYear = v),
  //   );
  // }
  Widget _yearDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedYear,

      // ✅ selected value text
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),

      // ✅ hint text
      hint: const Text('Year', style: TextStyle(color: Colors.white70)),

      // ✅ dropdown background
      dropdownColor: Colors.indigo,

      items: _years
          .map(
            (y) => DropdownMenuItem(
              value: y,
              child: Text(
                '$y Year',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),

      onChanged: (v) {
        setState(() => _selectedYear = v);
        _loadSessionTimes();
        _fetchBranchData();
      },

      // ✅ underline border styling
      decoration: const InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _attendanceList() {
    if (_attendanceRecords.isEmpty) {
      return const Center(child: Text('No attendance yet'));
    }

    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (_, i) {
        final r = _attendanceRecords[i];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(r.studentName),
          subtitle: Text(r.studentId),
          trailing: const Text('Present'),
        );
      },
    );
  }
}

class ScanResult {
  final bool isSuccess;
  final String? error;
  final String? studentName;

  ScanResult({required this.isSuccess, this.error, this.studentName});
}










