import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final bool isValid;
  final String studentName;

  const ResultDialog({
    super.key,
    required this.isValid,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isValid ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isValid ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isValid ? 'Present ✓' : 'Invalid Student ✗',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // Student name or message
            Text(
              isValid
                  ? studentName
                  : 'Student ID not found in database',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isValid ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
