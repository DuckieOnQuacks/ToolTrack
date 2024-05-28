import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../classes/tool_class.dart';

class ReturnConfirmationPage extends StatefulWidget {
  final String workorderId;
  final Tool tool;
  final String workOrderImagePath;
  final String toolImagePath;

  const ReturnConfirmationPage({
    super.key,
    required this.workorderId,
    required this.tool,
    required this.workOrderImagePath,
    required this.toolImagePath,
  });

  @override
  State<ReturnConfirmationPage> createState() => _ReturnConfirmationPageState();
}

class _ReturnConfirmationPageState extends State<ReturnConfirmationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _atMachineController = TextEditingController();

  void showTopSnackBar(BuildContext context, String message, Color color) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: color,
    ).show(context);
  }

  void confirmReturn() async {
    if (context.mounted) {
      String name = _nameController.text.trim();
      String atMachine = _atMachineController.text.trim();

      if (name.isNotEmpty && atMachine.isNotEmpty) {
        try {
          returnTool(widget.tool.gageID, "Available", "No One");
          // Navigate back to the first route and show the snackbar
          Navigator.popUntil(context, (route) => route.isFirst);
          Future.delayed(const Duration(milliseconds: 100), () {
            showTopSnackBar(context, "Return successful!", Colors.green);
          });
        } catch (e) {
          showTopSnackBar(
              context, "Failed to return. Please try again.", Colors.red);
        }
      } else {
        if (name.isEmpty) {
          showTopSnackBar(
              context, "Please enter your employee ID.", Colors.orange);
        }
        if (atMachine.isEmpty) {
          showTopSnackBar(
              context, "Please enter the machine where the tool is being used.", Colors.orange);
        }
      }
    }
  }

  void _showImage(String imagePath, {String? description}) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (description != null) ...[
                  Text(description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isNetworkUrl(imagePath)
                      ? Image.network(imagePath)
                      : Image.file(File(imagePath)),
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
        );
      },
    );
  }

  bool _isNetworkUrl(String path) {
    final uri = Uri.parse(path);
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Your Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  color: Colors.black45,
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Work Order ID:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.workorderId,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tool ID:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              widget.tool.gageID,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.image, color: Colors.white),
                              onPressed: () {
                                if (widget.toolImagePath.isEmpty) {
                                  showTopSnackBar(context, "No image available for this tool.", Colors.orange);
                                } else {
                                  _showImage(widget.toolImagePath);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Enter Employee ID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: _nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "i.e. 45454",
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Machine Where Tool Is Being Used:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: _atMachineController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'i.e. 345',
                            prefixIcon: Icon(Icons.build),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: confirmReturn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      'Return',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}