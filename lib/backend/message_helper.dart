import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

/*Message widget that can be used to show pop up messages throughout the app
Pass in context and the message you want on the pop up*/

import 'package:flutter/material.dart';

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
        offset: Offset(0, 2),
        blurRadius: 3,
      ),
    ],
  ).show(context);
}