import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
// Function to delete a tool given a Tool object
Future<void> deleteTool(Tool tool) async {
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  try {
    final toolDoc = toolsCollection.doc(tool.gageID);
    final docSnapshot = await toolDoc.get();

    if (docSnapshot.exists) {
      // Delete the document
      await toolDoc.delete();
      if (kDebugMode) {
        print('Tool with ID ${tool.gageID} has been deleted.');
      }
    } else {
      if (kDebugMode) {
        print('Tool with ID ${tool.gageID} does not exist in the database.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error deleting tool with ID ${tool.gageID}: $e');
    }
  }
}

Future<String?> uploadImageToStorage(String filePath, String gageID) async {
  File file = File(filePath);
  try {
    final storageRef = FirebaseStorage.instance.ref().child('ToolImages/$gageID');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    if (kDebugMode) {
      print('Error uploading image: $e');
    }
    return null;
  }
}

Future<void> updateToolIfDifferent(Tool oldTool, Tool newTool) async {
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');
  final toolDoc = toolsCollection.doc(oldTool.gageID);

  Map<String, dynamic> updates = {};

  if (oldTool.calibrationFreq != newTool.calibrationFreq) {
    updates['Calibration Frequency'] = newTool.calibrationFreq;
  }
  if (oldTool.calibrationLast != newTool.calibrationLast) {
    updates['Last Calibrated'] = newTool.calibrationLast;
  }
  if (oldTool.calibrationNextDue != newTool.calibrationNextDue) {
    updates['Calibration Due Date'] = newTool.calibrationNextDue;
  }
  if (oldTool.creationDate != newTool.creationDate) {
    updates['Date Created'] = newTool.creationDate;
  }
  if (oldTool.gageID != newTool.gageID) {
    updates['Gage ID'] = newTool.gageID;
  }
  if (oldTool.gageType != newTool.gageType) {
    updates['Type of Gage'] = newTool.gageType;
  }
  if (oldTool.imagePath != newTool.imagePath) {
    String? newImageUrl = await uploadImageToStorage(newTool.imagePath, oldTool.gageID);
    if (newImageUrl != null) {
      updates['Tool Image Path'] = newImageUrl;
    }
  }
  if (oldTool.gageDesc != newTool.gageDesc) {
    updates['Gage Description'] = newTool.gageDesc;
  }
  if (oldTool.dayRemain != newTool.dayRemain) {
    updates['Days Remaining Until Calibration'] = newTool.dayRemain;
  }
  if (oldTool.status != newTool.status) {
    updates['Status'] = newTool.status;
  }
  if (oldTool.lastCheckedOutBy != newTool.lastCheckedOutBy) {
    updates['Last Checked Out By'] = newTool.lastCheckedOutBy;
  }
  if (oldTool.atMachine != newTool.atMachine) {
    updates['Located At Machine'] = newTool.atMachine;
  }
  if (oldTool.dateCheckedOut != newTool.dateCheckedOut) {
    updates['Date Checked Out'] = newTool.dateCheckedOut;
  }
  if (oldTool.checkedOutTo != newTool.checkedOutTo) {
    updates['Checked Out To'] = newTool.checkedOutTo;
  }

  if (updates.isNotEmpty) {
    try {
      await toolDoc.update(updates);
      if (kDebugMode) {
        print('Tool with ID ${oldTool.gageID} has been updated with new information.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating tool with ID ${oldTool.gageID}: $e');
      }
    }
  } else {
    if (kDebugMode) {
      print('No differences found between the old and new tool information.');
    }
  }
}
