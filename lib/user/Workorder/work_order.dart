import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vineburgapp/admin/Workorder/scan_tool_workOrder.dart';
import 'package:vineburgapp/admin/Workorder/work_order_QR_scan.dart';
import 'package:vineburgapp/admin/Workorder/work_order_inspect.dart';
import 'package:vineburgapp/classes/work_order_class.dart';
import 'package:vineburgapp/user/Workorder/work_order_inspect.dart';
import '../../backend/message_helper.dart';
import '../../backend/user_helper.dart';

// All code on this page was developed by the team using the flutter framework
class UserWorkOrderPage extends StatefulWidget {
  const UserWorkOrderPage({super.key});

  @override
  State<UserWorkOrderPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<UserWorkOrderPage> {
  late List<CameraDescription> cameras;
  Future<List<WorkOrder>>? allworkorder;
  TextEditingController searchController = TextEditingController();
  late Future<List<WorkOrder>> filteredWorkorders;
  String imagePath = '';
  int pictureTaken = 0;

  // Define a list of pastel colors
  final List<Color> pastelColors = [
    const Color(0xFFE2F0CB), // Pastel Tea Green
    const Color(0xFFB5EAD7), // Pastel Keppel
    const Color(0xFFECEAE4), // Pastel Bone
    const Color(0xFFFAD0C4), // Pastel Salmon
    const Color(0xFFF9D5A7), // Pastel Orange
    const Color(0xFFF6EAC2), // Pastel Olive
    const Color(0xFFB5EAD7), // Pastel Mint
    const Color(0xFFC7CEEA), // Pastel Lavender
    const Color(0xFFA2D2FF), // Pastel Sky Blue
    const Color(0xFFBDE0FE), // Pastel Light Blue
    const Color(0xFFA9DEF9), // Pastel Cerulean
    const Color(0xFFFCF5C7), // Pastel Lemon
    const Color(0xFFC5CAE9), // Pastel indigo
    const Color(0xFFBBDEFB), // Pastel blue
    const Color(0xFFB3E5FC), // Lighter pastel blue
    const Color(0xFFB2EBF2), // Pastel cyan
    const Color(0xFFB2DFDB), // Pastel teal
    const Color(0xFFC8E6C9), // Pastal green
    const Color(0xFFA1C3D1), // Pastel Blue Green
    const Color(0xFFF4BFBF), // Pastel Red Pink
    const Color(0xFFF4E1D2), // Pastel Almond
    const Color(0xFFD3E0EA), // Pastel Blue Fog
    const Color(0xFFD6D2D2), // Pastel Gray
    const Color(0xFFFEC8D8), // Pastel Watermelon
    const Color(0xFFFFDFD3), // Pastel Peach
  ];

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });

    refreshWorkorderList();
    allworkorder = getUserWorkOrders();
    filteredWorkorders = allworkorder!; // Initially, filteredTools will show all tools
  }

  //Filters based on tool name and person checked out to.
  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredWorkorders = allworkorder!
            .then((allWorkorders) => allWorkorders.where((workorder) {
          return workorder.po
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              workorder.partName
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              workorder.enteredBy
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList());
      });
    } else {
      setState(() {
        filteredWorkorders = allworkorder!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Search'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
              onPressed: () async {
                imagePath = (await openCamera(context));
                if (imagePath.isNotEmpty) {
                  pictureTaken = 1;
                }
              },
              icon: const Icon(Icons.add_box_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              // 2. Add TextField
              onChanged: (value) {
                filterSearchResults(value);
              },
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by tool name, po number, or person",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<WorkOrder>>(
              future: filteredWorkorders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  // Handle the error case
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.hasData) {
                  final workOrderData = snapshot.data!;
                  if (workOrderData.isEmpty) {
                    return const Center(
                      child: Text("No Workorders"),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: workOrderData.length,
                    itemBuilder: (context, index) {
                      Color tileColor =
                      pastelColors[index % pastelColors.length];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        color: tileColor,
                        child: ListTile(
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // This is needed to keep the Row size to the minimum
                            children: <Widget>[
                              PopupMenuButton<String>(
                                onSelected: (String value) {
                                  if (value == 'Finish') {
                                    ///onDeletePressed(workOrderData[index]);
                                  }
                                  if (value == "Add Tool") {
                                    String data = workOrderData[index].id;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminScanToolWorkOrderPage(
                                                workId: data),
                                      ),
                                    );
                                  }
                                  //add more actions for other options
                                },
                                itemBuilder: (BuildContext context) {
                                  return <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'Add Tool',
                                      child: Text('Add Tool'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Finish',
                                      child: Text('Finish'),
                                    ),
                                    // Add more menu items here
                                  ];
                                },
                                icon: const Icon(Icons.more_vert_outlined),
                              ),
                            ],
                          ),
                          title: Text(
                            workOrderData[index].partName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('PO Number:  ${workOrderData[index].po}'),
                              Text(
                                  'Part Number: ${workOrderData[index].partNum}'),
                            ],
                          ),
                          onTap: () async {
                            var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserInspectOrderScreen(
                                    workOrder: workOrderData[index]),
                              ),
                            );
                            if (result == true) {
                              refreshWorkorderList();
                            }
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text("No Workorders"),
                  );
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
        builder: (context) => QRScan(
          controller,
          onWorkOrderAdded: () {
            refreshWorkorderList();
          },
        ),
      ),
    );
    if (imagePath == null || imagePath.isEmpty) {
      return 'null';
    }
    return imagePath;
  }

  void refreshWorkorderList() async {
    // Step 1: Fetch Work Orders
    var workOrderList = await getUserWorkOrders();

    // Step 2: Sort the List Alphabetically by partName
    workOrderList
        .sort((WorkOrder a, WorkOrder b) => a.partName.compareTo(b.partName));

    // Step 3: Update State with Sorted List
    setState(() {
      // Assigning the sorted list to the future that will be used by the UI
      allworkorder = Future.value(workOrderList);
      // Assigning the sorted list to the filtered list as well
      filteredWorkorders = Future.value(workOrderList);
    });
  }

  void onDeletePressed(WorkOrder workOrder) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          DeleteMachineDialog(workOrder: workOrder),
    );
    if (result != null && result) {
      setState(() {
        //Scan for favorites again after deletion
        allworkorder = getAllWorkOrders();
        refreshWorkorderList();
      });
    }
  }
}

class DeleteMachineDialog extends StatelessWidget {
  final WorkOrder workOrder;

  const DeleteMachineDialog({super.key, required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      buttonPadding: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
          ),
          SizedBox(width: 10),
          Text(
            'Confirm Delete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: const Text(
          'Are you sure you want to remove this workorder from the database?'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.grey[300],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await workOrder.deleteWorkorder(workOrder);
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
