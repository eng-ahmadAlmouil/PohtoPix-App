import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController idController = TextEditingController();

  bool _isTakingPhoto = false;
  bool _permissionsDone = false;
  late CameraController _controller;
  bool _isCameraInitialized = false;
  Uint8List? _imageBytes;

  // App Permissions
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();
    final camera = statuses[Permission.camera];
    if (camera?.isGranted != true) return false;
    // Android 13+
    final mediaGranted =
        statuses[Permission.photos]?.isGranted == true ||
        statuses[Permission.videos]?.isGranted == true;
    // Android 12 وأقل
    final storageGranted = statuses[Permission.storage]?.isGranted == true;
    return mediaGranted || storageGranted;
  }

  @override
  void initState() {
    super.initState();

    requestPermissions().then((granted) {
      if (!mounted) return;
      if (granted) {
        setState(() {
          _permissionsDone = true;
        });
        _initCamera();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  "لا يمكن تشغيل التطبيق بدون الصلاحيات",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: "Cairo",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.ultraHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002623),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002623),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PhotoPix",
          style: TextStyle(
            color: Color(0xFFB9A779),
            fontFamily: "Angkor",
            fontSize: 23,
            // fontWeight: FontWeight.w100,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // The Number Here
                TextField(
                  controller: idController,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 14,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  decoration: InputDecoration(
                    labelText: "ادخل الرقم الشخصي",
                    labelStyle: const TextStyle(
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color.fromARGB(137, 255, 255, 255),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    prefixIconColor: const Color(0xFFB9A779),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFB9A779),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF988561),
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF988561)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // The Camera Here
                _isCameraInitialized
                    ? AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF988561),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _imageBytes == null
                                      ? GestureDetector(
                                          onTapDown: (details) async {
                                            if (!_controller
                                                .value
                                                .isInitialized)
                                              return;
                                            final RenderBox box =
                                                context.findRenderObject()
                                                    as RenderBox;
                                            final Offset localPosition = box
                                                .globalToLocal(
                                                  details.globalPosition,
                                                );
                                            final double x =
                                                localPosition.dx /
                                                box.size.width;
                                            final double y =
                                                localPosition.dy /
                                                box.size.height;
                                            await _controller.setFocusPoint(
                                              Offset(x, y),
                                            );
                                            await _controller.setExposurePoint(
                                              Offset(x, y),
                                            );
                                          },
                                          child: CameraPreview(_controller),
                                        )
                                      : Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                ),

                                // ✨ Overlay (خطوط الوجه)
                                if (_imageBytes == null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: FaceGuidePainter(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(),
                const SizedBox(height: 10),
                // Capture the photo button
                ElevatedButton(
                  onPressed: () async {
                    if (_isTakingPhoto) return;
                    _isTakingPhoto = true;
                    try {
                      if (!_controller.value.isInitialized) return;
                      await _controller.setFocusMode(FocusMode.auto);
                      await _controller.setExposureMode(ExposureMode.auto);
                      await Future.delayed(const Duration(milliseconds: 400));
                      final image = await _controller.takePicture();
                      final croppedFile = await ImageCropper().cropImage(
                        sourcePath: image.path,
                        aspectRatio: const CropAspectRatio(
                          ratioX: 3,
                          ratioY: 4,
                        ),
                        compressFormat: ImageCompressFormat.jpg,
                        compressQuality: 100,
                        uiSettings: [
                          AndroidUiSettings(
                            lockAspectRatio: true,
                            // Bottom strip for cutting and rotating
                            // hideBottomControls: true,
                            toolbarTitle: "قص الصورة بنسبة 4:3",
                            toolbarColor: const Color(0xFF002623),
                            toolbarWidgetColor: Color(0xFF988561),
                            activeControlsWidgetColor: const Color(0xFF988561),
                            backgroundColor: const Color(0xFF002623),
                          ),
                        ],
                      );
                      if (croppedFile == null) return;
                      final bytes = await File(croppedFile.path).readAsBytes();
                      setState(() {
                        _imageBytes = bytes;
                      });
                    } catch (e) {
                      print("Capture Error: $e");
                    } finally {
                      _isTakingPhoto = false;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFF988561), width: 2),
                    elevation: 0,
                  ),
                  child: const Icon(
                    Icons.camera,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 15),
                // Save + Restart Camera Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          try {
                            setState(() {
                              _imageBytes = null;
                            });
                          } catch (e) {
                            print("Reset Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(
                                  child: Text(
                                    "حدث خطأ أثناء إعادة التصوير",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF988561),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "إعادة التصوير",
                          style: TextStyle(
                            fontFamily: "Cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Check the image
                          if (_imageBytes == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(
                                  child: Text(
                                    "التقط الصورة أولاً",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          // Check the number
                          if (idController.text.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(
                                  child: Text(
                                    "ادخل الرقم أولاً",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          // Save image
                          try {
                            final Directory directory = Directory(
                              '/storage/emulated/0/Pictures/PhotoPix',
                            );
                            if (!await directory.exists()) {
                              await directory.create(recursive: true);
                            }
                            final file = File(
                              '${directory.path}/${idController.text}.jpg',
                            );
                            await file.writeAsBytes(_imageBytes!);
                            if (!mounted) return;
                            setState(() {
                              _imageBytes = null;
                            });
                            idController.clear();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(
                                  child: Text(
                                    "(PhotoPix)تم الحفظ في مجلد",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            print("Save Error: $e");
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Center(
                                  child: Text(
                                    "خطأ في الحفظ",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF988561),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "حفظ",
                          style: TextStyle(
                            fontFamily: "Cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// camera class
class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 🔲 تعتيم الخلفية
    final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.4);
    final Path background = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    //  شكل الوجه (بيضاوي)
    final Rect ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.height * 0.5,
    );
    final Path hole = Path()..addOval(ovalRect);
    final Path finalPath = Path.combine(
      PathOperation.difference,
      background,
      hole,
    );
    canvas.drawPath(finalPath, overlayPaint);
    // إطار أبيض خفيف
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
