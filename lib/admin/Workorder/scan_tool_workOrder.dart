import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../backend/message_helper.dart';
import '../../backend/user_helper.dart';
import '../../classes/tool_class.dart';


class AdminScanToolWorkOrderPage extends StatefulWidget {
  String workId;

  AdminScanToolWorkOrderPage({super.key, required this.workId});

  @override
  State<StatefulWidget> createState() => _AdminScanToolWorkOrderPage();
}

class _AdminScanToolWorkOrderPage extends State<AdminScanToolWorkOrderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late final User user = FirebaseAuth.instance.currentUser!; // Get current user
  Barcode? result;
  String toolName = "";
  QRViewController? controller;
  String machineNumber = ''; // Variable to store machine number
  bool isScanned = false; // Add a new flag for scanning status
  final TextEditingController _machineController = TextEditingController(); // Controller for machine number input
  String currentDate = DateFormat('MM/dd/yyyy').format(DateTime.now());
  late Future<String> fullName;  // Future to hold the full name

  @override
  void initState() {
    super.initState();
     fullName = getUserFullName();  // Fetch the full name when the widget is initialized
    }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 200 || MediaQuery.of(context).size.height < 200)
        ? 150.0
        : 300.0; // Adjust the size of scan area here
    var cutOutSize = scanArea * 0.6; // Make cutout size smaller than the scan area

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Tool For Workorder'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Visibility(
              visible: !isScanned, // Show camera view if QR code is not yet scanned
              child: Center(
                child: SizedBox(
                  width: scanArea,
                  height: scanArea,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: cutOutSize,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Tool Name: ',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: toolName.isEmpty ? 'Not Scanned' : toolName,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // For spacing
                  const Text(
                    'Enter Machine Number*',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _machineController,
                    decoration: const InputDecoration(
                      hintText: 'Ex. "123"',
                    ),
                    maxLength: 3,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: (value) {
                      machineNumber = value;
                    },
                  ),
                    FutureBuilder<String>(
                      future: fullName,
                      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            return RichText(
                              text: TextSpan(
                                text: 'Current User: ',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: snapshot.data,
                                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return const CircularProgressIndicator();  // Show a loading spinner while waiting for the data
                      },
                    ),
                    const SizedBox(height: 30),
                    RichText(
                      text: TextSpan(
                        text: 'Checkout Date: ',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                            text: currentDate.isEmpty ? 'Not Scanned' : currentDate,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.normal, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Visibility(
              visible: isScanned, // Show the button only after QR code is scanned
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (machineNumber.isNotEmpty) {
                      Tool? toolExists = await getToolByToolName(toolName);
                      if (toolExists != null) {
                        // Proceed with whatever needs to be done if the tool exists
                        toolExists.addToolToUserAndWorkOrder(toolExists, widget.workId, currentDate, machineNumber);
                        Navigator.pop(context);
                      } else {
                        // Show a message if the tool does not exist
                        showMessage(context, 'Tool Not Found', 'The tool "$toolName" does not exist in the database.');
                      }
                    } else {
                      showMessage(context, 'Machine Number Required', 'Please enter the machine number.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue, // Button color
                    onPrimary: Colors.white, // Text color
                    elevation: 5, // Button shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ),
          ),

        ],
      ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        toolName = result!.code!; // Assuming the QR code contains just the tool name
        isScanned = true; // Set the flag to true when QR code is scanned
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}