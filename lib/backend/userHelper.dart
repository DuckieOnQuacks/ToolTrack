import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../classes/workOrderClass.dart';


Future<void> addUserDetails(String firstName, String lastName, List<String>? tools, List<String>? workOrders, String id) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }
  final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
  String username = createUsername(firstName, lastName);
  await userDocRef.set({
    'First Name': firstName.trim(),
    'Last Name': lastName.trim(),
    'Email': username,
    'Tools': tools,
    'Workorders': workOrders,
    'Id': id,
  });
}

Future<String> getUserFullName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    try {
      final snapshot = await userDocRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        String firstName = snapshot.data()?['First Name'] ?? 'NoFirstName';
        String lastName = snapshot.data()?['Last Name'] ?? 'NoLastName';
        return '$firstName $lastName';
      } else {
        return 'User does not exist in the database.';
      }
    } catch (e) {
      return 'Error fetching user details: $e';
    }
  } else {
    return 'No user signed in.';
  }
}

Future<List<WorkOrder>> getUserWorkOrders() async {
  final user = FirebaseAuth.instance.currentUser;
  final List<WorkOrder> workOrders = [];

  if (user == null) {
    return workOrders; // Return empty list if no user is logged in.
  }

  try {
    final userDocSnapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (!userDocSnapshot.exists || userDocSnapshot.data() == null) {
      return workOrders; // Return empty list if user document doesn't exist or is empty.
    }

    final List<dynamic> workOrderIds = userDocSnapshot.data()!['Workorders'] ?? [];

    for (var workOrderId in workOrderIds) {
      try {
        final workOrderDocSnapshot = await FirebaseFirestore.instance
            .collection('WorkOrders')
            .doc(workOrderId.toString())
            .get();

        final status = workOrderDocSnapshot.data()?['Status'] ?? 'Unknown';

        if (workOrderDocSnapshot.exists && status == 'Active') {
          workOrders.add(WorkOrder.fromJson(workOrderDocSnapshot.data()!));
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching work order with ID $workOrderId: $e");
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error fetching user's work orders: $e");
    }
  }
  return workOrders;
}

String createUsername(String firstName, String lastName) {
  String formattedFirstName = firstName.trim().replaceAll(' ', '_').toLowerCase();
  String formattedLastName = lastName.trim().replaceAll(' ', '_').toLowerCase();

  return '$formattedFirstName$formattedLastName@vineburg.com';
}