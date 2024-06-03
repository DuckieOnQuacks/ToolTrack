import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

/*Message widget that can be used to show pop up messages throughout the app
Pass in context and the message you want on the pop up*/

import 'package:flutter/material.dart';

void showTopSnackBar(BuildContext context, String message, Color color) {
  Flushbar(
    message: message,
    duration: const Duration(seconds: 3),
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(8),
    backgroundColor: color,
  ).show(context);
}
