import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vineburgapp/classes/work_order_class.dart';

class UserClass {
  String firstName;
  String lastName;
  String email;
  List<String>? tools;
  List<String>? workOrders;
  String id;

  UserClass({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.tools,
    this.workOrders,
    required this.id,
  });

  /// Converts a Firestore document to a User object.
  factory UserClass.fromJson(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserClass(
      firstName: data['First Name'],
      lastName: data['Last Name'],
      email: data['Email'],
      tools: List<String>.from(data['Tools'] ?? []),
      workOrders: List<String>.from(data['Workorders'] ?? []),
      id: data['Id'],
    );
  }

  /// Converts the User object to a Map.
  Map<String, dynamic> toJson() => {
        'First Name': firstName,
        'Last Name': lastName,
        'Email': email,
        'Tools': tools,
        'Workorders': workOrders,
        'Id': id,
      };

  /// Updates the current user's details in Firestore.
  Future<void> updateDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('No user signed in.');
      }
      return;
    }
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .set(toJson());
  }
}

/// Fetches the current user's details from Firestore and returns a User object.
Future<UserClass?> getCurrentUser() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return null;
  }
  try {
    final userDocRef =
        FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    final snapshot = await userDocRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserClass.fromJson(snapshot);
    } else {
      if (kDebugMode) {
        print('User does not exist in the database.');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching user details: $e');
    }
    return null;
  }
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
