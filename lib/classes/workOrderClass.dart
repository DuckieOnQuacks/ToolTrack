import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class WorkOrder {
  final String id;
  final List<String>? tool;
  late String imagePath; // Path to the image of the work order
  final String enteredBy;

  WorkOrder(
      {required this.id, required this.imagePath, this.tool, required this.enteredBy});

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
  factory WorkOrder.fromJson(Map<String, dynamic> json) =>
      WorkOrder(
        id: json['id'],
        imagePath: json['ImagePath'],
        tool: List<String>.from(json['Tools'] ?? []),
        enteredBy: json['Entered By'],
      );

  // Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'ImagePath': imagePath,
        'Tools': tool,
        'Entered By': enteredBy,
      };

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
    DocumentReference workOrderRef = firestore.collection('WorkOrders').doc(
        workOrderId);

    DocumentSnapshot workOrderSnapshot = await workOrderRef.get();

    if (workOrderSnapshot.exists) {
      Map<String, dynamic>? data = workOrderSnapshot.data() as Map<
          String,
          dynamic>?;
      if (data != null && data.containsKey('Tools') && data['Tools'] is List) {
        // Extract and return the list of tool IDs
        List<String> toolIds = List<String>.from(data['Tools']);
        return toolIds;
      } else {
        // The 'Tools' field is absent or is not a list
        if (kDebugMode) {
          print(
              'The work order does not have a valid \'Tools\' field or it is empty.');
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
      final Reference storageReference = storage.ref().child(
          'WorkOrderImages/$id.jpg');
      final UploadTask uploadTask = storageReference.putFile(File(imagePath));

      // Wait for the upload to complete
      final TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() =>
      {
      });

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
        print(
            'Work order $id has been successfully added to the WorkOrders collection.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding work order $id to the WorkOrders collection: $e');
      }
    }
  }
}

Future<void> handleWorkOrderAndCheckout({
  required String workorderId,
  required String toolId,
  required String imagePath,
  required String enteredBy,
}) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference workOrderRef = firestore.collection('WorkOrders').doc(workorderId);

  DocumentSnapshot workOrderSnapshot = await workOrderRef.get();

  if (workOrderSnapshot.exists) {
    // Work order exists, update the tools list
    await workOrderRef.update({
      'Tools': FieldValue.arrayUnion([toolId])
    });

    if (kDebugMode) {
      print('Tool $toolId has been successfully added to work order $workorderId.');
    }
  } else {
    // Work order does not exist, create a new one
    final FirebaseStorage storage = FirebaseStorage.instance;
    try {
      // Upload the image to Firebase Storage
      final Reference storageReference = storage.ref().child('WorkOrderImages/$workorderId.jpg');
      final UploadTask uploadTask = storageReference.putFile(File(imagePath));

      // Wait for the upload to complete
      final TaskSnapshot storageSnapshot = await uploadTask;

      // Get the download URL of the uploaded image
      final String downloadURL = await storageSnapshot.ref.getDownloadURL();

      // Create a map with the work order data
      Map<String, dynamic> workOrderData = {
        'id': workorderId,
        'ImagePath': downloadURL, // Use the download URL
        'Tools': [toolId], // Add the single tool ID to a list
        'Entered By': enteredBy,
      };

      // Create a new document in the 'WorkOrders' collection with the specified ID
      await workOrderRef.set(workOrderData);

      if (kDebugMode) {
        print('Work order $workorderId has been successfully added to the WorkOrders collection.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding work order $workorderId to the WorkOrders collection: $e');
      }
    }
  }
}