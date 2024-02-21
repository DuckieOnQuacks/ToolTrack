import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vineburgapp/backend/user_helper.dart';

String tableName = 'WorkOrders';

class WorkOrder {
  final String id;
  final String po;
  final String partNum;
  final List<String>? tool;
  final String partName;
  late String imagePath; // Path to the image of the work order
  late bool isFavorited;
  late String enteredBy;
  late String status;

  WorkOrder({required this.id, required this.po, required this.partNum, required this.partName, required this.imagePath, required this.isFavorited, this.tool, required this.enteredBy, required this.status});

// Factory method to create a Machine object from JSON data
  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: json['id'],
        partName: json["PartName"],
        po: json['PONumber'],
        partNum: json['PartNumber'],
        imagePath: json['ImagePath'],
        isFavorited: json['isFavorited'],
        tool: List<String>.from(json['Tools'] ?? []),
        enteredBy: json['Entered By'],
        status: json['Status'],
  );

  // Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'PartName': partName,
        'PONumber': po,
        'PartNumber': partNum,
        'ImagePath' : imagePath,
        'isFavorited': isFavorited,
        'Tools': tool,
        'Entered By': enteredBy,
        'Status': status,
      };

  Future<void> deleteWorkorder(WorkOrder workOrder) async {
    final workOrderCollection = FirebaseFirestore.instance.collection('WorkOrders');
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print('No user signed in.');
      }
      return;
    }

    try {
      // Fetch the work order document
      DocumentSnapshot workOrderDoc = await workOrderCollection.doc(workOrder.id).get();

      if (workOrderDoc.exists) {
        List<dynamic> toolsList = workOrderDoc.get('Tools') ?? []; // Assuming 'Tools' is the field with tool IDs/names

        // Delete the image from Firebase Storage if the image path exists
        String? imagePath = workOrderDoc.get('ImagePath');
        if (imagePath != null && imagePath.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
          if (kDebugMode) {
            print('Image associated with Workorder ${workOrder.id} has been successfully deleted.');
          }
        }

        // Delete the work order document
        await workOrderCollection.doc(workOrder.id).delete();
        if (kDebugMode) {
          print('Workorder ${workOrder.id} has been successfully deleted from the Workorder collection.');
        }

        // Remove the tools from the current user's tools list
        final userDocRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
        DocumentSnapshot userDoc = await userDocRef.get();
        if (userDoc.exists && userDoc.data() != null) {
          List<dynamic> userToolsList = userDoc.get('Tools') ?? [];
          for (var tool in toolsList) {
            userToolsList.remove(tool); // Assuming you're storing tool IDs or names directly in the user's Tools list
          }

          await userDocRef.update({'Tools': userToolsList});
          if (kDebugMode) {
            print('Tools associated with Workorder ${workOrder.id} have been successfully removed from the current user\'s tools list.');
          }
        }
      } else {
        if (kDebugMode) {
          print('Work Order ${workOrder.id} not found.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting workorder ${workOrder.id} and updating user\'s tools list: $e');
      }
    }
  }

}

Future<List<String>> getToolIdsFromWorkOrder(String workOrderId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference workOrderRef = firestore.collection('WorkOrders').doc(workOrderId);

  DocumentSnapshot workOrderSnapshot = await workOrderRef.get();

  if (workOrderSnapshot.exists) {
    Map<String, dynamic>? data = workOrderSnapshot.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('Tools') && data['Tools'] is List) {
      // Extract and return the list of tool IDs
      List<String> toolIds = List<String>.from(data['Tools']);
      return toolIds;
    } else {
      // The 'Tools' field is absent or is not a list
      if (kDebugMode) {
        print('The work order does not have a valid \'Tools\' field or it is empty.');
      }
      return [];
    }
  } else {
    // The work order document does not exist
    if (kDebugMode) {
      print('The specified work order does not exist.');
    }
    return [];
  }
}

//Creates a machine table that is to be sent to the firebase database, before it is sent it converts it to JSON format
Future<void> addWorkOrder(WorkOrder order) async {
  final docOrder = FirebaseFirestore.instance.collection(tableName).doc();
  final orderTable = WorkOrder(
    id: docOrder.id,
    partName: order.partName,
    po: order.po,
    partNum: order.partNum,
    imagePath: order.imagePath,
    isFavorited: order.isFavorited,
    tool: order.tool,
    enteredBy: order.enteredBy,
    status: order.status,
  );
  final json = orderTable.toJson();
  // Create document and write data to Firestore
  await docOrder.set(json);
}

// Function to add a work order with individual parameters and an image
Future<void> addWorkOrderWithParams(String partName, String po, String partNum, String imagePath, bool isFavorited, List<String> tools, String status) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }

  final docOrder = FirebaseFirestore.instance.collection(tableName).doc();
  final orderTable = WorkOrder(
    id: docOrder.id,
    partName: partName,
    po: po,
    partNum: partNum,
    isFavorited: isFavorited,
    tool: tools,
    imagePath: imagePath, // Add the image URL here
    enteredBy: await getUserFullName(),
    status: status,
  );
  final json = orderTable.toJson();

  // Create document and write data to Firestore
  await docOrder.set(json);
}

//Makes a Firestore instance, gets a snapshot fo the data inside the Machine collection
//Returns a list of machines and the data inside them
Future<List<WorkOrder>> getAllWorkOrders() async {
  final machinesCollection = FirebaseFirestore.instance.collection(tableName);
  final querySnapshot = await machinesCollection.get();
  return querySnapshot.docs.map((doc) => WorkOrder.fromJson(doc.data())).toList();
}



//
Future<void> updateWorkOrder(String workOrderId, {String? partName, String? po, String? partNum, String? enteredBy}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }

  final docOrder = FirebaseFirestore.instance.collection(tableName).doc(workOrderId);

  // Fetch the current data of the work order
  final currentData = await docOrder.get();
  if (!currentData.exists) {
    if (kDebugMode) {
      print('Work order not found.');
    }
    return;
  }

  // Create a map for the updates
  Map<String, dynamic> updates = {};

  // Only add the fields to the update map if they are not null
  if (partName != null) updates['PartName'] = partName;
  if (po != null) updates['PONumber'] = po;
  if (partNum != null) updates['PartNumber'] = partNum;
  if (enteredBy != null) updates['Entered By'] = enteredBy;

  // Check if there are any updates to be made
  if (updates.isNotEmpty) {
    // Update the document with the new data
    await docOrder.update(updates);
    if (kDebugMode) {
      print('Work order updated successfully.');
    }
  } else {
    if (kDebugMode) {
      print('No updates provided.');
    }
  }
}

