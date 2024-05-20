import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';


class WorkOrder {
  final String id;
  final List<String>? tool;
  late String imagePath; // Path to the image of the work order
  final String enteredBy;

  WorkOrder({required this.id, required this.imagePath, this.tool, required this.enteredBy});

  final List<Color> pastelColors = [
    const Color(0xFFC5CAE9), // Pastel indigo
    const Color(0xFFBBDEFB), // Pastel blue
    const Color(0xFFB2EBF2), // Pastel cyan
    const Color(0xFFB2DFDB), // Pastel teal
    const Color(0xFFC8E6C9), // Pastal green
    const Color(0xFFA1C3D1), // Pastel Blue Green
    const Color(0xFFF4E1D2), // Pastel Almond
    const Color(0xFFD3E0EA), // Pastel Blue Fog
    const Color(0xFFD6D2D2), // Pastel Gray
    const Color(0xFFFFDFD3), // Pastel Peach
    const Color(0xFFE2F0CB), // Pastel Tea Green
    const Color(0xFFB5EAD7), // Pastel Keppel
    const Color(0xFFECEAE4), // Pastel Bone
    const Color(0xFFF9D5A7), // Pastel Orange
    const Color(0xFFF6EAC2), // Pastel Olive
    const Color(0xFFB5EAD7), // Pastel Mint
    const Color(0xFFC7CEEA), // Pastel Lavender
    const Color(0xFFA2D2FF), // Pastel Sky Blue
    const Color(0xFFBDE0FE), // Pastel Light Blue
    const Color(0xFFA9DEF9), // Pastel Cerulean
    const Color(0xFFFCF5C7), // Pastel Lemon
  ];

// Factory method to create a Machine object from JSON data
  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: json['id'],
        imagePath: json['ImagePath'],
        tool: List<String>.from(json['Tools'] ?? []),
        enteredBy: json['Entered By'],
  );

  // Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'ImagePath' : imagePath,
        'Tools': tool,
        'Entered By': enteredBy,
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

/// Retrieves a list of tool IDs associated with a specific work order.
///
/// This function fetches a work order document from the 'WorkOrders' collection
/// using the provided workOrderId. It then extracts and returns the list of
/// tool IDs stored in the 'Tools' field of the document.
///
/// Returns a list of strings representing tool IDs. Returns an empty list if
/// the work order does not exist or does not contain a 'Tools' field.
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


/// Adds a new work order to the Firestore database.
/// This function creates a new document in the 'WorkOrders' collection with the specified
/// work order ID and populates it with the provided data.
Future<void> addWorkOrder({
  required String id,
  required String imagePath,
  required String toolId,
  required String enteredBy,
}) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final workOrderCollection = firestore.collection('WorkOrders');
  final FirebaseStorage storage = FirebaseStorage.instance;

  try {
    // Upload the image to Firebase Storage
    final Reference storageReference = storage.ref().child('WorkOrderImages/$id.jpg');
    final UploadTask uploadTask = storageReference.putFile(File(imagePath));

    // Wait for the upload to complete
    final TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => {});

    // Get the download URL of the uploaded image
    final String downloadURL = await storageSnapshot.ref.getDownloadURL();

    // Create a map with the work order data
    Map<String, dynamic> workOrderData = {
      'id': id,
      'ImagePath': downloadURL, // Use the download URL
      'Tools': [toolId], // Add the single tool ID to a list
      'Entered By': enteredBy,
    };

    // Create a new document in the 'WorkOrders' collection with the specified ID
    await workOrderCollection.doc(id).set(workOrderData);

    if (kDebugMode) {
      print('Work order $id has been successfully added to the WorkOrders collection.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error adding work order $id to the WorkOrders collection: $e');
    }
  }
}


/// Fetches all work order documents from the 'WorkOrders' collection.
/// This function retrieves all documents from the specified collection and
/// converts each document to a WorkOrder object.
///
/// Returns a list of WorkOrder objects representing all work orders in the collection.
Future<List<WorkOrder>> getAllWorkOrders() async {
  final machinesCollection = FirebaseFirestore.instance.collection('WorkOrders');
  final querySnapshot = await machinesCollection.get();
  return querySnapshot.docs.map((doc) => WorkOrder.fromJson(doc.data())).toList();
}

/// Updates specific fields of an existing work order document.
///
/// This function allows for selectively updating the fields of a work order document
/// identified by [workOrderId] with new values provided via optional parameters.
/// Only fields that are provided will be updated.
Future<void> updateWorkOrder(String workOrderId, {String? partName, String? po, String? partNum, String? enteredBy, String? status}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }

  final docOrder = FirebaseFirestore.instance.collection("WorkOrders").doc(workOrderId);

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
  if (status != null) updates['Status'] = status;

  // Check if there are any updates to be made
  if (updates.isNotEmpty) {
    // Update the document with the new data
    await docOrder.update(updates);
    if (kDebugMode) {
      print(status);
      print('Work order updated successfully.');
    }
  } else {
    if (kDebugMode) {
      print('No updates provided.');
    }
  }
}
