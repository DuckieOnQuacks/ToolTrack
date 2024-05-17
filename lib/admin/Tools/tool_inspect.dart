/*import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vineburgapp/backend/camera_preview_helper.dart';
import '../../backend/message_helper.dart';
import '../../classes/tools_class.dart';

class AdminInspectToolScreen extends StatefulWidget {
  final Tool tool;

  const AdminInspectToolScreen({super.key, required this.tool});

  @override
  _AdminInspectToolScreenState createState() => _AdminInspectToolScreenState();
}

class _AdminInspectToolScreenState extends State<AdminInspectToolScreen> {
  late List<CameraDescription> cameras;
  late TextEditingController toolNameController;
  String imagePath = '';
  //late TextEditingController whereBeingUsedController;
  //late TextEditingController personCheckedOutController;
  //late TextEditingController dateCheckedOutController;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });
    toolNameController = TextEditingController(text: widget.tool.gageType);//whereBeingUsedController = TextEditingController(text: widget.tool.whereBeingUsed);
    //personCheckedOutController = TextEditingController(text: widget.tool.personCheckedTool);
    //dateCheckedOutController = TextEditingController(text: widget.tool.dateCheckedOut);
  }
  @override
  void dispose() {
    toolNameController.dispose();
    //whereBeingUsedController.dispose();
    //personCheckedOutController.dispose();
    //dateCheckedOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tool Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.blueAccent,
            iconSize: 100.0,
            onPressed: () =>
                _showImageFullscreen(context, widget.tool.imagePath),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            color: Colors.blueAccent,
            iconSize: 100.0,
            onPressed: () async {
             imagePath = await openCamera(context);
            }
          ),
          const SizedBox(height: 20),
          const Text(
            'Tool Name:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: toolNameController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Located At Machine: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
         /* TextFormField(
            controller: whereBeingUsedController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Checked Out To: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: personCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check Out Date: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: dateCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          */
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: ElevatedButton (
              onPressed: () => _confirmChanges(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                elevation: 5, // Button shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ), // Button padding
                ),
              child: const Text('Submit Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ),
          ),
        ],
      ),
    );
  }

  Future<String> openCamera(BuildContext context) async {
    // Ensure that there is a camera available on the device
    if (cameras.isEmpty) {
      showMessage(context, 'Uh Oh!', 'Camera not available');
      return 'null';
    }

    // Check if the user has granted camera permission
    PermissionStatus cameraPermission = await Permission.camera.status;
    if (cameraPermission != PermissionStatus.granted) {
      // Request camera permission
      PermissionStatus permissionStatus = await Permission.camera.request();
      if (permissionStatus == PermissionStatus.denied) {
        // Permission denied show warning
        showWarning2(context,
            "App require access to camera... Press allow camera to allow the camera.");
        // Request camera permission again
        PermissionStatus permissionStatus2 = await Permission.camera.request();
        if (permissionStatus2 != PermissionStatus.granted) {
          // Permission still not granted, return null
          showMessage(context, 'Uh Oh!', 'Camera permission denied');
          return 'null';
        }
      } else if (permissionStatus != PermissionStatus.granted) {
        // Permission not granted, return null
        showMessage(context, 'Uh Oh!', 'Camera permission denied');
        return 'null';
      }
    }

    // Take the first camera in the list
    CameraDescription camera = cameras[0];

    // Open the camera and store the resulting CameraController
    CameraController controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();

    // Navigate to the CameraScreen and pass the CameraController to it
    String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPreviewHelper(
          controller,
        ),
      ),
    );
    if (imagePath == null || imagePath.isEmpty) {
      return 'null';
    }
    return imagePath;
  }

  void _confirmChanges(BuildContext context) {
    // Compare current values with original values and create a list of changes
    List<Widget> changesWidgets = [];
    if (toolNameController.text != widget.tool.gageType) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Tool Name: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.tool.gageType} -> ${toolNameController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      );
    }
    /*
    const SizedBox(height: 10);
    if (whereBeingUsedController.text != widget.tool.whereBeingUsed) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Located At Machine: ',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.whereBeingUsed} -> ${whereBeingUsedController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              )
            ]
        ),
      ));
    }
    const SizedBox(height: 10);
    if (personCheckedOutController.text != widget.tool.personCheckedTool) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Checked Out To:',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.personCheckedTool} -> ${personCheckedOutController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }
    const SizedBox(height: 10);
    if (dateCheckedOutController.text != widget.tool.dateCheckedOut) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Check Out Date:',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.dateCheckedOut} -> ${dateCheckedOutController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }
*/
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Changes"),
          content: SingleChildScrollView(
            child: ListBody(
              children: changesWidgets.isNotEmpty
                  ? changesWidgets
                  : [const Text("No changes made.")],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                await updateToolImagePath(widget.tool.gageID, imagePath);
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }
}

void _showImageFullscreen(BuildContext context, String imageUrl) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Tool Image'),
        leading: const BackButton(), // Uses default back button
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    ),
  ));
}
*/

