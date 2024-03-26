import 'dart:async';
import 'package:flutter/material.dart';

/*Message widget that can be used to show pop up messages throughout the app
Pass in context and the message you want on the pop up*/

void showMessage(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showWarning(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.redAccent,
                    size: 24.0,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Warning:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

}

Future<void> showWarning2(BuildContext context, String message) async {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.grey,
                    size: 24.0,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Warning:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.grey,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

}

