import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error al inicializar la cámara: $e');
  }
  runApp(const StrayCameraApp());
}

class StrayCameraApp extends StatelessWidget {
  const StrayCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stray Camera',
      theme: ThemeData.dark(),
      home: const CameraHomeScreen(),
    );
  }
}

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stray Camera - Proceso'),
        centerTitle: true,
      ),
      body: _cameras.isEmpty
          ? const Center(child: Text('No se detectaron cámaras disponibles.'))
          : const CameraPreviewWidget(),
    );
  }
}

class CameraPreviewWidget extends StatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  CameraController? controller;
  bool isRecording = false;
  bool showGrid = true;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera(selectedCameraIndex);
  }

  Future<void> _initCamera(int cameraIndex) async {
    if (_cameras.isEmpty) return;
    controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error al cargar vista previa de cámara: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % _cameras.length;
    _initCamera(selectedCameraIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(controller!),
        ),

        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off, color: Colors.white),
                onPressed: () => setState(() => showGrid = !showGrid),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                onPressed: _toggleCamera,
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
