import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/user/scan_tool_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vineburgapp/user/user_work_order_inspect.dart';
import '../backend/camera_helper.dart';
import '../backend/message_helper.dart';
import '../classes/work_order_class.dart';


class UserWorkOrderPage extends StatefulWidget {
  const UserWorkOrderPage({super.key});

  @override
  _UserWorkOrderPageState createState() => _UserWorkOrderPageState();
}

class _UserWorkOrderPageState extends State<UserWorkOrderPage> {
  late List<CameraDescription> cameras;
  String imagePath = ' ';
  int pictureTaken = 0;
  TextEditingController searchController = TextEditingController();
  late List<WorkOrder> allWorkOrders = [];
  late List<WorkOrder> filteredWorkOrders = [];

  @override
  void initState() {
    super.initState();
    // Get a list of available cameras on the device
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });

    // Initialize work orders
    allWorkOrders = [];
    filteredWorkOrders = [];
  }

  @override
  void dispose() {
    super.dispose();
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<WorkOrder> dummyListData = allWorkOrders.where((workOrder) {
        // Customize this based on your WorkOrder class structure
        return workOrder.partName.toLowerCase().contains(query.toLowerCase()) ||
            workOrder.po.toLowerCase().contains(query.toLowerCase()) ||
            workOrder.partNum.toLowerCase().contains(query.toLowerCase());
      }).toList();
      setState(() {
        filteredWorkOrders.clear();
        filteredWorkOrders.addAll(dummyListData);
      });
    } else {
      setState(() {
        filteredWorkOrders.clear();
        filteredWorkOrders.addAll(allWorkOrders);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
              onPressed: () async {
                imagePath = (await openCamera(context))!;
                if (imagePath.isNotEmpty) {
                  pictureTaken = 1;
                }
              },
              icon: const Icon(Icons.add_box_rounded))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField( // 2. Add TextField
              onChanged: (value) {
                filterSearchResults(value);
              },
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by part name, PO, or part number",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WorkOrder>>(
              future: getAllWorkOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  allWorkOrders = snapshot.data ?? []; // Store all work orders
                  if (filteredWorkOrders.isEmpty && searchController.text.isEmpty) {
                    filteredWorkOrders.addAll(allWorkOrders); // Populate filteredWorkOrders on first fetch
                  }
                  return ListView.builder(
                    itemCount: filteredWorkOrders.length, // 3. Use filteredWorkOrders for the list
                    itemBuilder: (context, index) {
                      return WorkOrderCard(workOrder: filteredWorkOrders[index]);
                    },
                  );
                } else {
                  return const Center(child: Text('No work orders found'));
                }
              },
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
        showWarning2(context, "App require access to camera... Press allow camera to allow the camera.");
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
    //String? imagePath = await Navigator.push(context,
      //MaterialPageRoute(
      //  builder: (context) => CameraScreen(
       //     onToolAdded: () {
        //      refreshToolsList();
        //    }, controller: controller
        //),
      //),
    //);
    if (imagePath == null || imagePath.isEmpty) {
      return 'null';
    }
    return imagePath;
  }


}


class WorkOrderCard extends StatelessWidget {
  final WorkOrder workOrder;

  const WorkOrderCard({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Adds shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounds corners
      ),
      child: ListTile(
        title: Text(
          workOrder.partName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('PO Number:  ${workOrder.po}'),
            Text('Part Number: ${workOrder.partNum}'),
          ],
        ),
        isThreeLine: true,
        // If subtitle has more than one line
        trailing: PopupMenuButton(
          icon: const Icon(Icons.add),
          itemBuilder: (context) =>
          [
            const PopupMenuItem(
              value: 1,
              child: Text('Add Tool'),
            ),
          ],
          onSelected: (value) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScanToolPage(workOrder: workOrder),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectOrderScreen(workOrder: workOrder),
            ),
          );
          print('Tapped on ${workOrder.po}');
        },
      ),
    );
  }

}


