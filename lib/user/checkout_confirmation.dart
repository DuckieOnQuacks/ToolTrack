import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vineburgapp/classes/tool_class.dart';
import 'package:vineburgapp/classes/workorder_class.dart';
import '../backend/message_helper.dart';

class CheckoutConfirmationPage extends StatefulWidget {
  final String workorderId;
  final Tool tool;
  final String toolImagePath;

  const CheckoutConfirmationPage({
    super.key,
    required this.workorderId,
    required this.tool,
    required this.toolImagePath,
  });

  @override
  State<CheckoutConfirmationPage> createState() => _CheckoutConfirmationPageState();
}

class _CheckoutConfirmationPageState extends State<CheckoutConfirmationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _atMachineController = TextEditingController();

  void confirmCheckout() async {
    String name = _nameController.text.trim();
    String atMachine = _atMachineController.text.trim();
    if (name.isNotEmpty && atMachine.isNotEmpty) {
      try {
        await handleWorkOrderAndCheckout(
          workorderId: widget.workorderId,
          toolId: widget.tool.gageID,
          enteredBy: _nameController.text,
        );
        if (widget.tool.status == "Checked Out") {
          showTopSnackBar(context, "Already checked out to ${widget.tool.checkedOutTo}", Colors.red, title: "Error", icon: Icons.error);

        } else {
          checkoutTool(widget.tool.gageID, "Checked Out", _nameController.text.trim(), _atMachineController.text.trim());

          // Navigate back to the first route and show the snack-bar
          if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
          Future.delayed(const Duration(milliseconds: 100), () {
            showTopSnackBar(context, "Checkout successful!", Colors.green, title: "Success", icon: Icons.check_circle);
          });
        }
      } catch (e) {
        showTopSnackBar(context, "Failed to checkout. Please try again.", Colors.red, title: "Error", icon: Icons.error);
      }
    }
    if (name.isEmpty) {
      showTopSnackBar(context, "Please enter valid employee ID", Colors.orange, title: "Warning", icon: Icons.warning);

    }
    if (atMachine.isEmpty) {
      showTopSnackBar(context, "Please enter valid machine location ID", Colors.orange, title: "Warning", icon: Icons.warning);

    }
  }

  void showImage(String imagePath, {String? description}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black26,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // Increase the height of the bottom sheet
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description != null) ...[
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder(
                  future: loadImage(imagePath),
                  builder: (BuildContext context, AsyncSnapshot<ImageProvider<Object>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Icon(Icons.error));
                    } else {
                      return Image(
                        image: snapshot.data!,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width, // Increase the width of the image
                        height: MediaQuery.of(context).size.height * 0.75, // Increase the height of the image
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 35),
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
        );
      },
    );
  }

  Future<ImageProvider<Object>> loadImage(String path) async {
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Your Details',
          style: TextStyle(color: Colors.white),
        ),
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
                        Row(
                          children: [
                            const Text(
                              'Tool Description:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.image, color: Colors.white),
                              onPressed: () {
                                showImage(widget.toolImagePath);
                              },
                            ),
                          ],
                        ),
                        Text(
                          widget.tool.gageDesc,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Text(
                              'Tool ID:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        Text(
                          widget.tool.gageID,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Text(
                              'Work Order ID:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        Text(
                          widget.workorderId,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enter Employee ID: *',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'i.e. 18487',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Machine Where Tool Is Being Used: *',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextField(
                          controller: _atMachineController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "i.e. 263",
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
                    onPressed: confirmCheckout,
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
                      'Checkout',
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
