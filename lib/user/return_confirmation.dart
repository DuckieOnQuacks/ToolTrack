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
    if(context.mounted) {
      String name = _nameController.text.trim();
      if (name.isNotEmpty) {
        try {
          bool toolIsInWorkOrder = await isToolInWorkOrder(
              widget.workorderId, widget.tool.gageID);
          if (toolIsInWorkOrder == false) {
            showTopSnackBar(context,
                "Tool Not Checked Out To WorkOrder ${widget.workorderId}",
                Colors.red);
          }
          else {
            updateToolStatus(widget.tool.gageID, "Available", "No One");
            // Navigate back to the first route and show the snackbar
            Navigator.popUntil(context, (route) => route.isFirst);
            Future.delayed(const Duration(milliseconds: 100), () {
              showTopSnackBar(context, "Return successful!", Colors.green);
            });
          }
        } catch (e) {
          showTopSnackBar(
              context, "Failed to return. Please try again.", Colors.red);
        }
      } else {
        showTopSnackBar(
            context, "Please enter your employee ID.", Colors.orange);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                color: Colors.black45,
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Work Order ID:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        widget.workorderId,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Tool ID:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.image),
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
                      Text(
                        widget.tool.gageID,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Employee ID',
                          labelStyle: TextStyle(color: Colors.white),
                          border: UnderlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
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
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Return',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}