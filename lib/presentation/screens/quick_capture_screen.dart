import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';

class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen> {
  CameraController? _controller;
  final List<String> _capturedPaths = [];
  bool _capturing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final dest = p.join(dir.path, 'qc_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(file.path).copy(dest);
      setState(() => _capturedPaths.add(dest));
    } finally {
      setState(() => _capturing = false);
    }
  }

  void _done() => Navigator.pop(context, _capturedPaths);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _done,
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Quick Capture',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_capturedPaths.isNotEmpty)
                    GestureDetector(
                      onTap: _done,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Done (${_capturedPaths.length})',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Camera preview
            Expanded(
              child: _initialized && _controller != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CameraPreview(_controller!),
                    )
                  : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),

            // Captured thumbnails strip
            if (_capturedPaths.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _capturedPaths.length,
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      image: DecorationImage(
                        image: FileImage(File(_capturedPaths[i])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

            // Capture button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: GestureDetector(
                onTap: _capture,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _capturing ? 68 : 72,
                  height: _capturing ? 68 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _capturing ? Colors.grey : Colors.white,
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: _capturing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
