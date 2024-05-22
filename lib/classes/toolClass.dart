import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Tool {
  final String calibrationFreq;
  final String calibrationLast;
  final String calibrationNextDue;
  final String creationDate;
  final String gageID;
  final String gageType;
  final String imagePath;
  final String gageDesc;
  final String dayRemain;
  final String status;
  final String? lastCheckedOutBy;
  final String atMachine;
  final String dateCheckedOut;
  final String checkedOutTo;

  Tool({
    required this.calibrationFreq,
    required this.calibrationLast,
    required this.calibrationNextDue,
    required this.creationDate,
    required this.gageID,
    required this.gageType,
    required this.imagePath,
    required this.gageDesc,
    required this.dayRemain,
    required this.status,
    required this.lastCheckedOutBy,
    required this.atMachine,
    required this.dateCheckedOut,
    required this.checkedOutTo,
  });


  final List<Color> pastelColors = [
    const Color(0xFFFFDFD3), // Pastel Peach
    const Color(0xFFE2F0CB), // Pastel Tea Green
    const Color(0xFFB5EAD7), // Pastel Keppel
    const Color(0xFFECEAE4), // Pastel Bone
    const Color(0xFFF9D5A7), // Pastel Orange
    const Color(0xFFBDE0FE), // Pastel Light Blue
    const Color(0xFFA9DEF9), // Pastel Cerulean
    const Color(0xFFFCF5C7), // Pastel Lemon
    const Color(0xFFC5CAE9), // Pastel indigo
    const Color(0xFFBBDEFB), // Pastel blue
    const Color(0xFFB2EBF2), // Pastel cyan
    const Color(0xFFB2DFDB), // Pastel teal
    const Color(0xFFC8E6C9), // Pastal green
    const Color(0xFFA1C3D1), // Pastel Blue Green
    const Color(0xFFF4E1D2), // Pastel Almond
    const Color(0xFFD3E0EA), // Pastel Blue Fog
    const Color(0xFFD6D2D2), // Pastel Gray
    const Color(0xFFF6EAC2), // Pastel Olive
    const Color(0xFFB5EAD7), // Pastel Mint
    const Color(0xFFC7CEEA), // Pastel Lavender
    const Color(0xFFA2D2FF), // Pastel Sky Blue

  ];

  // Factory method to create a Tool object from JSON data
  factory Tool.fromJson(Map<String, dynamic> json) =>
      Tool(
        calibrationFreq: json['Calibration Frequency'] as String? ?? '' ,
        calibrationLast: json["Last Calibrated"] as String? ?? '',
        calibrationNextDue: json['Calibration Due Date'] as String? ?? '',
        creationDate: json['Date Created'] as String? ?? '',
        gageID: json['Gage ID'] as String? ?? '',
        gageType: json['Type of Gage'] as String? ?? '',
        imagePath: json['Tool Image Path'] as String? ?? '',
        gageDesc: json['Gage Description'] as String? ?? '',
        dayRemain: json['Days Remaining Until Calibration'] as String? ?? '',
        status: json['Status'] as String? ?? '',
        lastCheckedOutBy: json['Last Checked Out By'] as String? ?? '',
        atMachine: json["Located At Machine"] as String? ?? '',
        dateCheckedOut: json["Date Checked Out"] as String? ?? '',
        checkedOutTo: json["Checked Out To"] as String? ?? '',
    );
  // Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'Calibration Frequency': calibrationFreq,
        'Last Calibrated': calibrationLast,
        'Calibration Due Date': calibrationNextDue,
        'Date Created': creationDate,
        'Gage ID': gageID,
        'Type of Gage': gageType,
        'Tool Image Path': imagePath,
        'Gage Description': gageDesc,
        'Days Remaining Until Calibration': dayRemain,
        'Status': status,
        'Last Checked Out By': lastCheckedOutBy,
        'Located At Machine': atMachine,
        'Checked Out To': checkedOutTo
      };
}

Future<void> addToolWithParams(String calFreq, String calLast, String calNextDue, String creationDate, String gageID, String gageType, String imagePath, String gageDesc, String daysRemain) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }

  final docOrder = FirebaseFirestore.instance.collection("Tools").doc(gageID);
  final orderTable = Tool(
      calibrationFreq: calFreq,
      calibrationLast: calLast,
      calibrationNextDue: calNextDue,
      creationDate: creationDate,
      gageID: gageID,
      gageType: gageType,
      imagePath: imagePath,
      gageDesc: gageDesc,
      dayRemain: daysRemain,
      status: "Available",
      lastCheckedOutBy: "",
      atMachine: "",
      dateCheckedOut: "",
      checkedOutTo: "",
  );
  final json = orderTable.toJson();
  // Create document and write data to Firestore
  await docOrder.set(json);
}

Future<DocumentSnapshot?> getToolDocument(String toolId) async {
  final toolDoc = await FirebaseFirestore.instance.collection('Tools').doc(toolId).get();
  return toolDoc.exists ? toolDoc : null;
}

Future<void> updateToolStatus(String toolId, String status, String userWhoCheckedOut) async {
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  try {
    final toolDoc = toolsCollection.doc(toolId);
    final docSnapshot = await toolDoc.get();

    if (docSnapshot.exists) {
      // Update the status field of the document
      await toolDoc.update({
        'Status': status,
        'Checked Out To': userWhoCheckedOut,
      });
      if (kDebugMode) {
        print('Status of tool with ID $toolId has been updated to $status.');
      }
    } else {
      if (kDebugMode) {
        print('Tool with ID $toolId does not exist in the database.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error updating status for tool with ID $toolId: $e');
    }
  }
}

Future<String?> getToolStatus(String toolId) async {
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  try {
    final toolDoc = await toolsCollection.doc(toolId).get();

    if (toolDoc.exists) {
      // Retrieve the status field of the document
      final status = toolDoc.data()?['Status'] as String?;
      if (kDebugMode) {
        print('Status of tool with ID $toolId is $status.');
      }
      return status;
    } else {
      if (kDebugMode) {
        print('Tool with ID $toolId does not exist in the database.');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error retrieving status for tool with ID $toolId: $e');
    }
    return null;
  }
}

Future<bool> isToolInWorkOrder(String workOrderId, String toolId) async {
  final workOrdersCollection = FirebaseFirestore.instance.collection('WorkOrders');

  try {
    final workOrderDoc = await workOrdersCollection.doc(workOrderId).get();

    if (workOrderDoc.exists) {
      final data = workOrderDoc.data();
      if (data != null && data['Tools'] is List) {
        final List<dynamic> tools = data['Tools'];
        if (tools.contains(toolId)) {
          if (kDebugMode) {
            print('Tool ID $toolId is found in work order $workOrderId.');
          }
          return true;
        }
      }
    } else {
      if (kDebugMode) {
        print('Work order with ID $workOrderId does not exist.');
      }
    }
    if (kDebugMode) {
      print('Tool ID $toolId is not found in work order $workOrderId.');
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('Error checking tool ID in work order $workOrderId: $e');
    }
    return false;
  }
}

//Admin helper functions.
Future<List<Tool>> getAllTools() async {
  List<Tool> toolDetails = [];
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  try {
    final querySnapshot = await toolsCollection.get();
    for (var doc in querySnapshot.docs) {
      if (doc.exists) {
        toolDetails.add(Tool.fromJson(doc.data()));
      } else {
        print('Tool ${doc.id} does not exist in the Tools collection.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching tools: $e');
    }
  }

  return toolDetails;
}

Future<void> addCheckedOutToFieldToTools() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference toolsCollection = firestore.collection('Tools');

  try {
    QuerySnapshot querySnapshot = await toolsCollection.get();
    WriteBatch batch = firestore.batch();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      // Get the current data of the tool
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Check if the field already exists to avoid overwriting existing data
      if (!data.containsKey('Checked Out To')) {
        // Add "Checked Out To" field with an empty string or default value
        batch.update(doc.reference, {'Checked Out To': ''});
      }
    }

    // Commit the batch update
    await batch.commit();

    if (kDebugMode) {
      print('Successfully added "Checked Out To" field to all tools.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error updating tools: $e');
    }
  }
}