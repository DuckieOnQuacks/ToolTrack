import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/camera_manager.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';

class AdminInspectToolScreen extends StatefulWidget {
  final Tool tool;

  const AdminInspectToolScreen({super.key, required this.tool});

  @override
  State<AdminInspectToolScreen> createState() => _AdminInspectToolScreenState();
}

class _AdminInspectToolScreenState extends State<AdminInspectToolScreen> {
  late List<CameraDescription> cameras;
  late CameraManager _cameraManager;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController gageIDController = TextEditingController();
  final TextEditingController gageTypeController = TextEditingController();
  final TextEditingController gageDescriptionController =
  TextEditingController();
  final TextEditingController checkedOutToController = TextEditingController();
  final TextEditingController lastCheckedOutController =
  TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController calibrationFreqController =
  TextEditingController();
  final TextEditingController daysRemainController = TextEditingController();
  final TextEditingController dateCreatedController = TextEditingController();
  final TextEditingController calibrationDueController =
  TextEditingController();
  final TextEditingController lastCalibratedController =
  TextEditingController();
  final TextEditingController atMachineController = TextEditingController();
  final TextEditingController dateCheckedOutController =
  TextEditingController();

  String imagePath = '';
  bool pictureTaken = false;
  FlashMode _flashMode = FlashMode.off;
  bool isCameraInitialized = false;
  bool isLoading = false;
  String? imageUrl;
  String statusValue = 'Available';
  bool isModeled = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      setState(() {
        _cameraManager = CameraManager(cameras);
      });
      _initializeCamera();
    });
    gageIDController.text = widget.tool.gageID;
    gageTypeController.text = widget.tool.gageType;
    gageDescriptionController.text = widget.tool.gageDesc;
    checkedOutToController.text = widget.tool.checkedOutTo;
    lastCheckedOutController.text = widget.tool.lastCheckedOutBy;
    statusValue = widget.tool.status;
    statusController.text = widget.tool.status; // Initialize with tool status
    dateCreatedController.text = widget.tool.creationDate;
    calibrationDueController.text = widget.tool.calibrationNextDue;
    lastCalibratedController.text = widget.tool.calibrationLast;
    atMachineController.text = widget.tool.atMachine;
    dateCheckedOutController.text = widget.tool.dateCheckedOut;
    imagePath = widget.tool.imagePath;
    isModeled = widget.tool.modeled;
    _fetchImageUrl();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      isLoading = true;
    });
    await _cameraManager.initializeCamera();
    setState(() {
      isCameraInitialized = true;
      isLoading = false;
    });
  }

  Future<void> _fetchImageUrl() async {
    try {
      DocumentSnapshot toolSnapshot = await FirebaseFirestore.instance
          .collection('tools')
          .doc(widget.tool.gageID)
          .get();
      if (toolSnapshot.exists) {
        setState(() {
          imageUrl = toolSnapshot['imageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching image URL: $e');
    }
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    gageIDController.dispose();
    gageTypeController.dispose();
    gageDescriptionController.dispose();
    checkedOutToController.dispose();
    lastCheckedOutController.dispose();
    statusController.dispose();
    dateCreatedController.dispose();
    calibrationDueController.dispose();
    lastCalibratedController.dispose();
    atMachineController.dispose();
    super.dispose();
  }

  Future<void> _showCameraDialog() async {
    if (_cameraManager.controller != null &&
        _cameraManager.controller!.value.isInitialized) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: SizedBox(
                        width: 350,
                        height: 500,
                        child: CameraPreview(_cameraManager.controller!),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_flashMode == FlashMode.torch
                            ? Icons.flash_on
                            : Icons.flash_off),
                        onPressed: _toggleFlashMode,
                        color: Colors.yellow,
                        iconSize: 36,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        iconSize: 50.0,
                        onPressed: () async {
                          String? path = await _cameraManager.takePicture();
                          if (path != null) {
                            setState(() {
                              imagePath = path;
                              pictureTaken = true;
                            });
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _toggleFlashMode() {
    setState(() {
      _flashMode =
      _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraManager.controller?.setFlashMode(_flashMode);
    });
  }

  void _confirmChanges(BuildContext context) {
    List<Widget> changesWidgets = [];
    if (gageIDController.text != widget.tool.gageID) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Gage ID: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.tool.gageID} -> ${gageIDController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }
    const SizedBox(height: 10);
    if (gageTypeController.text != widget.tool.gageType) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Gage Type: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.gageType} -> ${gageTypeController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal))
            ]),
      ));
    }
    const SizedBox(height: 10);
    if (gageDescriptionController.text != widget.tool.gageDesc) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Gage Description: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.gageDesc} -> ${gageDescriptionController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    const SizedBox(height: 10);
    if (checkedOutToController.text != widget.tool.checkedOutTo) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Checked Out To: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.checkedOutTo} -> ${checkedOutToController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    const SizedBox(height: 10);
    if (lastCheckedOutController.text != widget.tool.lastCheckedOutBy) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Last Checked Out To: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.lastCheckedOutBy} -> ${lastCheckedOutController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (statusValue != widget.tool.status) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Status: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.status} -> $statusValue',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (dateCreatedController.text != widget.tool.creationDate) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Tool Creation Date: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.creationDate} -> ${dateCreatedController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (calibrationDueController.text != widget.tool.calibrationNextDue) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Calibration Next Due: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool
                      .calibrationNextDue} -> ${calibrationDueController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (lastCalibratedController.text != widget.tool.calibrationLast) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Last Calibrated On: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.calibrationLast} -> ${lastCalibratedController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (atMachineController.text != widget.tool.atMachine) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'At Machine: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.atMachine} -> ${atMachineController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (dateCheckedOutController.text != widget.tool.dateCheckedOut) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Checked Out On: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text:
                  '${widget.tool.dateCheckedOut} -> ${dateCheckedOutController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (isModeled != widget.tool.modeled) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Modeled: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.modeled} -> $isModeled',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    if (pictureTaken) {
      changesWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Image:',
              style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Image.file(
              File(imagePath),
              width: 100,
              height: 100,
            ),
          ],
        ),
      );
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          buttonPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Changes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: changesWidgets,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTool = Tool(
                  calibrationFreq: widget.tool.calibrationFreq,
                  calibrationLast: lastCalibratedController.text,
                  calibrationNextDue: calibrationDueController.text,
                  creationDate: dateCreatedController.text,
                  gageID: gageIDController.text,
                  gageType: gageTypeController.text,
                  imagePath: imagePath,
                  gageDesc: gageDescriptionController.text,
                  dayRemain: daysRemainController.text,
                  status: statusValue,
                  lastCheckedOutBy: lastCheckedOutController.text,
                  atMachine: atMachineController.text,
                  dateCheckedOut: dateCheckedOutController.text,
                  checkedOutTo: checkedOutToController.text,
                  modeled: isModeled,
                );
                if ((imagePath != widget.tool.imagePath) &&
                    widget.tool.imagePath != "") {
                  await deleteOldImage(widget.tool.imagePath);
                }
                // Implement save functionality here
                await updateToolIfDifferent(widget.tool, newTool);
                if (context.mounted) {
                  Navigator.of(context).pop(true); // Return true to indicate changes
                  Navigator.of(context).pop(true); // Return true to indicate changes
                  showTopSnackBar(context, "Changes Saved Successfully", Colors.green, title: "Success", icon: Icons.check_circle);

                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showImage(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Tool ID: ${widget.tool.gageID}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder(
                      future: _loadImage(imagePath),
                      builder: (BuildContext context, AsyncSnapshot<ImageProvider<Object>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(child: Icon(Icons.error));
                        } else {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.5,
                            ),
                            child: Image(
                              image: snapshot.data!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<ImageProvider<Object>> _loadImage(String path) async {
    if (_isNetworkUrl(path)) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  bool _isNetworkUrl(String path) {
    final uri = Uri.parse(path);
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit/View Tool Details'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 70, color: Colors.orange),
                          onPressed: () async {
                            await _showCameraDialog();
                          },
                        ),
                        if (pictureTaken || imagePath != "") ...[
                          IconButton(
                            icon: const Icon(Icons.image,
                                color: Colors.green, size: 70),
                            onPressed: () {
                              _showImage(imagePath);
                            },
                          ),
                        ],
                      ],
                    ),
                    _buildSectionHeader('Tool Information'),
                    _buildModeledCheckbox(),
                    _buildTextField(
                      controller: gageIDController,
                      label: 'Tool ID: ',
                      hintText: 'e.g. 00001',
                    ),
                    _buildTextField(
                      controller: gageDescriptionController,
                      label: 'Tool Description: ',
                      hintText: 'e.g. 2-3" MITUTOYO MICROMETER',
                    ),
                    _buildTextField(
                      controller: gageTypeController,
                      label: 'Tool Type: ',
                      hintText: 'Enter In Gage Type',
                    ),
                    _buildDateField(
                      controller: dateCreatedController,
                      label: 'Tool Creation Date: ',
                      hintText: 'MM/DD/YYYY',
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Status/Location'),
                    _buildTextField(
                      controller: checkedOutToController,
                      label: 'Checked Out To: ',
                      hintText: 'i.e. Jack',
                    ),
                    _buildTextField(
                      controller: lastCheckedOutController,
                      label: 'Last Checked Out To: ',
                      hintText: 'i.e. Joey',
                    ),
                    _buildTextField(
                      controller: atMachineController,
                      label: 'At Machine: ',
                      hintText: 'i.e. 1234',
                    ),
                    _buildDropdownField(
                      controller: statusController,
                      label: 'Status: ',
                      hintText: 'i.e. Available',
                      items: ['Available', "Checked Out"],
                    ),
                    _buildDateFieldWithClear(
                      controller: dateCheckedOutController,
                      label: 'Date Checked Out: ',
                      hintText: 'MM/DD/YYYY',
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Calibration Information'),
                    _buildDateField(
                      controller: calibrationDueController,
                      label: 'Next Due: ',
                      hintText: 'MM/DD/YYYY',
                    ),
                    _buildDateField(
                      controller: lastCalibratedController,
                      label: 'Last Completed: ',
                      hintText: 'MM/DD/YYYY',
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _confirmChanges(context),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              hintText: hintText,
            ),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                controller.text = DateFormat('MM/dd/yyyy').format(date);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFieldWithClear({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        controller.text = DateFormat('MM/dd/yyyy').format(date);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value:
            controller.text.isEmpty ? widget.tool.status : controller.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  statusValue =
                      newValue; // Update the status value when the dropdown changes
                });
                controller.text = newValue;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
      ),
    );
  }

  Widget _buildModeledCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: isModeled,
              onChanged: (bool? value) {
                setState(() {
                  isModeled = value ?? false;
                });
              },
              activeColor: Colors.orange[800],
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
           const Text(
            'Modeled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
