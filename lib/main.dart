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
      title: 'Stray Tufting Camera',
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.camera),
            ),
            const SizedBox(width: 10),
            const Text('Stray Tufting Camera'),
          ],
        ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'photo_btn',
                backgroundColor: Colors.white,
                onPressed: () async {
                  try {
                    final image = await controller!.takePicture();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Foto guardada en: ${image.path}')),
                    );
                  } catch (e) {
                    debugPrint('Error al capturar foto: $e');
                  }
                },
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),

              FloatingActionButton(
                heroTag: 'video_btn',
                backgroundColor: isRecording ? Colors.red : Colors.redAccent,
                onPressed: () async {
                  if (isRecording) {
                    final video = await controller!.stopVideoRecording();
                    setState(() => isRecording = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Video guardado en: ${video.path}')),
                    );
                  } else {
                    await controller!.startVideoRecording();
                    setState(() => isRecording = true);
                  }
                },
                child: Icon(isRecording ? Icons.stop : Icons.videocam, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);

    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
