import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class CameraManager {
  CameraController? controller;
  final List<CameraDescription> cameras;
  final BarcodeScanner barcodeScanner = BarcodeScanner();

  CameraManager(this.cameras);

  Future<void> initializeCamera() async {
    if (cameras.isNotEmpty) {
      controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await controller!.initialize();
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    }
  }

  Future<void> disposeCamera() async {
    await controller?.dispose();
    await barcodeScanner.close();
  }

  Future<String?> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    if (!controller!.value.isTakingPicture) {
      try {
        final XFile file = await controller!.takePicture();
        return file.path;
      } catch (e) {
        debugPrint('Error taking picture: $e');
        return null;
      }
    }
    return null;
  }

  Future<String?> scanBarcode(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final List<Barcode> barcodes =
          await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        return barcodes.first.rawValue;
      }
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
    }
    return null;
  }
}
