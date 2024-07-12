import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void showTopSnackBar(BuildContext context, String message, Color color, {String? title, IconData? icon}) {
  Flushbar(
    title: title,
    message: message,
    icon: icon != null ? Icon(icon, size: 28.0, color: Colors.white) : null,
    duration: const Duration(seconds: 3),
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(8),
    backgroundColor: color,
    leftBarIndicatorColor: Colors.white,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        offset: const Offset(0, 2),
        blurRadius: 3,
      ),
    ],
  ).show(context);
}

void showAdminInstructionsDialog(BuildContext context, String section) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Admin Instructions - $section",
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(20),
          thickness: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: getSectionContent(section),
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    },
  );
}

Widget getSectionContent(String section) {
  switch (section) {
    case 'Bins':
      return buildBinsInstructions();
    case 'Work Orders':
      return buildWorkOrdersInstructions();
    case 'Tools':
      return buildToolsInstructions();
    default:
      return const Text('Invalid section');
  }
}

Widget buildBinsInstructions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionHeader("Add Bin:"),
      stepDetail("1. Tap the 'Add' icon in the top right corner."),
      stepDetail("2. Enter bin name, location and tool IDs to be put in the bin."),
      stepDetail("3. Press submit button and confirm that bin was successfully added."),
      note("Note:"),
      stepDetail("- Tools must be in database before adding them to a bin."),
      sectionHeader("Delete Bin:"),
      stepDetail("1. Tap the 'Delete' icon on the bin you would like to remove and confirm."),
      stepDetail("2. Confirm the bin was deleted successfully."),
      note("Note:"),
      stepDetail("- Deleting a bin removes it from the database, none of the tools within the bin are affected."),
      sectionHeader("Modify Bin:"),
      stepDetail("1. Select the bin to modify by tapping on the list option."),
      stepDetail("2. Modify any entry that pertains to the specific bin."),
      note("Note:"),
      stepDetail("- Deleting tools removes them from the bin but not the database."),
      stepDetail("- Tools must be in database before adding them to a preexisting bin."),
    ],
  );
}

Widget buildWorkOrdersInstructions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionHeader("Add Work Order:"),
      stepDetail("1. Tap the 'Add' icon in the top right corner."),
      stepDetail("2. Enter work order ID and tools."),
      stepDetail("3. Submit and confirm that the work order was added successfully."),
      note("Note:"),
      stepDetail("- Tools must be in database before adding them to a bin."),
      const SizedBox(height: 10),
      sectionHeader("Delete Work Order:"),
      stepDetail("1. Tap the trashcan icon of the work order you would like to delete."),
      stepDetail("2. Confirm the deletion."),
      note("Note:"),
      stepDetail("- Deleting a work order does not affect the tools within the work order. They will still be checked out or available."),
      const SizedBox(height: 10),
      sectionHeader("Modify Work Order:"),
      stepDetail("1. Select the work order to modify by tapping on it."),
      stepDetail("2. Modify any entry that pertains to the specific work order."),
      note("Note:"),
      stepDetail("- Deleting tools removes them from the work order itself but not the database."),
      stepDetail("- Tools must be in database before adding them to a preexisting work order."),
    ],
  );
}

Widget buildToolsInstructions() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionHeader("Add Tool:"),
      stepDetail("1. Tap the 'Plus' icon in the top right hand corner."),
      stepDetail("2. Fill in all required tool detail fields (fields with '*')."),
      stepDetail("3. Submit the form and confirm that the tool was added successfully."),

      sectionHeader("Delete Tool:"),
      stepDetail("1. Tap the trashcan icon of the tool you would like to delete."),
      stepDetail("2. Confirm the deletion."),
      note("Note:"),
      stepDetail("- Deleting a tool removes it from the database but not the work orders. That needs to be done in the work order page."),

      sectionHeader("Modify Tool:"),
      stepDetail("1. Select the tool to modify."),
      stepDetail("2. If there is only a camera icon then the tool has no image yet. Otherwise a green photo icon will show as well."),
      stepDetail("3. Modify details."),
      stepDetail("4. Submit the details and review changes."),
      stepDetail("5. Confirm that the changes were applied successfully."),
    ],
  );
}

Widget sectionHeader(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 22,
      ),
    ),
  );
}

Widget note(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 5, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 16,
      ),
    ),
  );
}

Widget step(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 5, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 18,
      ),
    ),
  );
}

Widget stepDetail(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    ),
  );
}

void showInstructionsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Help",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(20),
          thickness: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader("Checkout Tool:"),
                stepDetail("1. Select 'Checkout Tool'."),
                stepDetail("2. Scan or manually enter work order ID."),
                stepDetail("3. Scan or manually enter the Bin name."),
                stepDetail("4. Enter your employee ID, machine ID and confirm checkout."),
                stepDetail("5. Confirm that the tool was checked out successfully."),

                const SizedBox(height: 10),

                sectionHeader("Return Tool:"),
                stepDetail("1. Select 'Return Tool'."),
                stepDetail("2. Scan or manually enter bin QR code."),
                stepDetail("3. Select the tool you're returning from the list. If it's not there you most likely scanned the wrong bin."),
                stepDetail("4. Confirm that the tool was returned successfully."),

                const SizedBox(height: 10),

                sectionHeader("Barcode or QR code not scanning?"),
                stepDetail("1. On the work order scan page, tap the 'pencil' icon to manually enter Work order ID or Bin name."),
                stepDetail("2. Work orders are manually entered by ID."),
                stepDetail("3. Bins are manually entered by bin name."),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    },
  );
}
