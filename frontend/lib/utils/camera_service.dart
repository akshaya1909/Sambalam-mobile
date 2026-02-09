import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  static final CameraService _instance = CameraService._internal();
  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? cameras;
  CameraController? controller;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  /// Initialize available cameras
  Future<void> initCameras() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  /// Initialize the camera controller with the front camera
  Future<void> initCameraController() async {
    if (cameras == null || cameras!.isEmpty) {
      await initCameras();
    }

    if (cameras != null && cameras!.isNotEmpty) {
      // Use the front camera if available
      final frontCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
    }
  }

  /// Take a picture using the camera controller
  Future<XFile?> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      print('Camera controller not initialized');
      return null;
    }

    try {
      final XFile file = await controller!.takePicture();
      return file;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  /// Take a selfie using the image picker
  Future<XFile?> takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      return photo;
    } catch (e) {
      print('Error taking selfie: $e');
      return null;
    }
  }

  /// Save an image file to a permanent location
  Future<String?> saveImagePermanently(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = path.basename(image.path);
      final savedImage = await File(image.path).copy('${directory.path}/$name');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Dispose the camera controller
  void dispose() {
    controller?.dispose();
    controller = null;
  }
}