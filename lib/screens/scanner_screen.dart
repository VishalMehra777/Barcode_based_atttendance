import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final bool continuous;
  final Future<bool> Function(String)? onScan;

  const ScannerScreen({
    super.key,
    this.continuous = false,
    this.onScan,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController cameraController;
  bool isProcessing = false;
  String? lastScannedCode;
  DateTime? lastScanTime;
  String? feedbackMessage;
  Color? feedbackColor;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      // Logic for Continuous Mode
      if (widget.continuous) {
        // Prevent duplicate spam (simple debounce)
        if (lastScannedCode == code &&
            lastScanTime != null &&
            DateTime.now().difference(lastScanTime!) < const Duration(seconds: 2)) {
          return;
        }

        setState(() {
          isProcessing = true;
          lastScannedCode = code;
          lastScanTime = DateTime.now();
        });

        // Trigger callback
        final bool success = await widget.onScan!(code);

        if (mounted) {
          setState(() {
            feedbackMessage = success ? 'Marked: $code' : 'Error/Duplicate: $code';
            feedbackColor = success ? Colors.green : Colors.red;
          });

          // Hide feedback after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                feedbackMessage = null;
              });
            }
          });
        }

        // Resume processing
        setState(() {
          isProcessing = false;
        });

      } else {
        // Normal Mode (Single Scan)
        if (isProcessing) return; // reused bool instead of isScanned
        setState(() {
          isProcessing = true;
        });
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan Student ID Barcode',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // Overlay guide
          Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: feedbackColor ?? Colors.white.withValues(alpha: 0.7),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: feedbackMessage != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Text(
                          feedbackMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: feedbackColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                   Text(
                    widget.continuous 
                      ? 'Continuous Mode' 
                      : 'Position the barcode within the frame',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.continuous)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Done Scanning'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
