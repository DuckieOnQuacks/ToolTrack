import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/*Camera helper that takes in a camera controller. When called it
opens the camera allows the user to take a picture and opens a
dialog asking if the picture taken is ok or not.*/

class CameraPreviewHelper extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewHelper(this.controller, {super.key});

  @override
  _CameraPreviewHelper createState() => _CameraPreviewHelper();
}

class _CameraPreviewHelper extends State<CameraPreviewHelper> {
  bool _isFlashOn = false; // Track if flash is on or off

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            // Navigator.of(context).pushReplacementNamed('/desiredRoute');
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 350, // Default width
              height: 600, // Default height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 3),
                borderRadius: BorderRadius.circular(20), // Added rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Clip it to have rounded corners
                child: CameraPreview(widget.controller),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCameraControls(),
    );
  }


  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flash button with unique heroTag
          FloatingActionButton(
            heroTag: 'flashButton', // Unique tag for the flash button
            mini: true, // Make it smaller than the capture button
            onPressed: _toggleFlash,
            backgroundColor: Colors.white,
            child: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 40), // Space between the flash and capture button
          // Camera capture button with unique heroTag
          FloatingActionButton(
            heroTag: 'captureButton', // Unique tag for the capture button
            onPressed: () {
              // Implement your capture and confirmation logic here
              _captureAndConfirmImage();
            },
            backgroundColor: Colors.deepOrange, // Custom color for the button
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await widget.controller.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _captureAndConfirmImage() async {
    try {
      final XFile image = await widget.controller.takePicture();
      final bool? isConfirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text("Is this image ok?"),
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
            body: Image.file(File(image.path), fit: BoxFit.contain),
          ),
        ),
      );
      if (isConfirmed ?? false) {
        // If the image is confirmed, do something with the image
        // For instance, you can pass the image path back to the previous screen
        Navigator.of(context).pop(image.path);
      }
      // If the image is not confirmed, simply return to the camera screen to retake the photo
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
