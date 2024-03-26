import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';
import '../../classes/user_class.dart';


class ToolReturnPage extends StatefulWidget {
  final Tool toolToReturn;

  const ToolReturnPage({super.key, required this.toolToReturn});

  @override
  State<StatefulWidget> createState() => _ToolReturnPageState();
}

class _ToolReturnPageState extends State<ToolReturnPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late final User user = FirebaseAuth.instance.currentUser!; // Get current user
  bool isCorrectToolScanned = false; // New flag for correct tool scanning
  Barcode? result;
  String toolName = " ";
  QRViewController? controller;
  bool isScanned = false; // Add a new flag for scanning status
  late Future<String> fullName;  // Future to hold the full name
  bool isToolNameConfirmed = false;
  bool isImageConfirmed = false;

  bool warningShown = false;

  @override
  void initState() {
    super.initState();
    fullName = getUserFullName();  // Fetch the full name when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 200 || MediaQuery.of(context).size.height < 200) ? 150.0 : 300.0;
    var cutOutSize = scanArea * 0.6;

    var imageSizeWidth = MediaQuery.of(context).size.width * 0.7; // 50% of screen width
    var imageSizeHeight = MediaQuery.of(context).size.height * 0.6; // 30% of screen height

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Tool'),
      ),
      body: SingleChildScrollView( // Ensure the content fits on smaller screens
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!isScanned || !isCorrectToolScanned) ...[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Scan Bin #14',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
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
                  ],
                ),
              ],
              if (isScanned && isCorrectToolScanned) ...[

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        activeColor: Colors.black,
                        title: RichText(
                          text: const TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: 'Tool Being Returned: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),

                            ],
                          ),
                        ),
                        value: isToolNameConfirmed,
                        onChanged: (bool? value) {
                          setState(() {
                            isToolNameConfirmed = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 17.0),
                      child: Text(toolName, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 20, color: Colors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        activeColor: Colors.black,
                        title: RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: 'Is the ${toolName} shown below?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                              //TextSpan(text: '$toolName?', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 20, color: Colors.black)),
                            ],
                          ),
                        ),
                        value: isImageConfirmed,
                        onChanged: (bool? value) {
                          setState(() {
                            isImageConfirmed = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 17.0),
                      child: Image.network(
                        widget.toolToReturn.imagePath,
                        width: imageSizeWidth,
                        height: imageSizeHeight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: isScanned && isCorrectToolScanned && isToolNameConfirmed && isImageConfirmed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              await widget.toolToReturn.returnToolAndUpdateUser(widget.toolToReturn);
              Navigator.pop(context,true);
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.black,
              onPrimary: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Return Tool'),
          ),
        ),
      ),
    );
  }


  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      var scannedToolName = scanData.code; // Temporarily hold the scanned code

      // Check if the scanned tool name matches the expected tool name
      if (scannedToolName == widget.toolToReturn.toolName && !isScanned) {
        // Ensure that we only react to the first scan matching the expected tool name
        // and that no scans are processed if a correct scan has already been detected.
        setState(() {
          result = scanData;
          toolName = scannedToolName!;
          isScanned = true; // Indicate that a scan has been successfully processed
          isCorrectToolScanned = true; // Confirm the correct tool has been scanned
        });

        // Pause the camera after a successful scan to prevent multiple scans
        controller.pauseCamera();
      } else if (!warningShown && !isScanned) {
        controller.pauseCamera();
        // Show warning only if no correct scan has been processed and the warning hasn't been shown yet
        await showWarning2(context, "Wrong Bin").then((_) {
          // Once the warning has been dismissed, reset warningShown to false
          // and optionally resume camera for a new scan attempt.
          setState(() {
            warningShown = false;
          });
          controller.resumeCamera(); // Uncomment if you wish to automatically resume scanning after the warning
        });
      }

    });
  }



  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
