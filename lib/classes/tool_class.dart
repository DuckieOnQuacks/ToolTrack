import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vineburgapp/classes/user_class.dart';

class Tool{
  late final String toolName;
  late final String? dateCheckedOut;
  late final String? dateCheckedIn;
  late final String personCheckedTool;
  late final String? personReturnedTool;
  late final String whereBeingUsed;
  late final String calibrationDate;
  late final String imagePath;
  late final String personAddedTool;
  late final String? workOrderId;

  Tool({
    required this.toolName,
    this.dateCheckedOut,
    this.dateCheckedIn,
    required this.personCheckedTool,
    this.personReturnedTool,
    required this.whereBeingUsed,
    required this.calibrationDate,
    required this.imagePath,
    required this.personAddedTool,
    this.workOrderId,
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

  // Factory method to create a Machine object from JSON data
  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    toolName: json['Tool Name'] as String? ?? '',
    dateCheckedOut: json["Check Out Date"] as String? ?? '',
    dateCheckedIn: json['Check In Date'] as String?,
    personCheckedTool: json['Person Checked Tool'] as String? ?? '',
    personReturnedTool: json['Person Returned Tool'] as String?,
    whereBeingUsed: json['Machine Where Used'] as String,
    calibrationDate: json['Calibration Date'] as String? ?? '',
    imagePath: json['Tool Image Path'] as String? ?? '',
    personAddedTool: json['Person Added Tool'] as String? ?? '',
    workOrderId: json['Checked Out To Workorder'] as String? ?? '',
  );


// Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'Tool Name': toolName,
        'Check Out Date': dateCheckedOut,
        'Check In Date':dateCheckedIn,
        'Person Checked Tool': personCheckedTool,
        'Person Returned Tool' : personReturnedTool,
        'Machine Where Used': whereBeingUsed,
        'Calibration Date': calibrationDate,
        'Tool Image Path': imagePath,
        'Person Added Tool': personAddedTool,
        'Checked Out To Workorder': workOrderId,
      };

  // Variables to store machine data
  String tableName = 'Tools';

  //Helpers for user
  Future<void> addToolToUserAndWorkOrder(Tool tool, String workOrderId, String checkedOut, String machineNum) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('No user signed in.');
      }
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    final workOrderRef = FirebaseFirestore.instance.collection('WorkOrders').doc(workOrderId);
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');

    // Update the specific tool's "Check Out Date" and "Person Checked Tool" in the Tools collection
    final toolDocRef = toolsCollection.doc(tool.toolName); // Assuming toolName is used as the document ID

    await toolDocRef.update({
      'Check Out Date': checkedOut,
      'Person Checked Tool': await getCurrentUser(),
      "Machine Where Used": machineNum,
      "Checked Out To Workorder": workOrderId,
    }).then((_) {
      if (kDebugMode) {
        print('Tool updated with check out date and person checked tool.');
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('Error updating tool: $error');
      }
    });

    // Add tool name to user's list
    final userSnapshot = await userDocRef.get();
    if (userSnapshot.exists) {
      var userData = userSnapshot.data();
      List<dynamic> userToolsArray = userData?['Tools'] ?? [];

      if (!userToolsArray.contains(tool.toolName)) {
        userToolsArray.add(tool.toolName);
        await userDocRef.update({
          'Tools': userToolsArray,
        });
      } else {
        if (kDebugMode) {
          print('Tool is already in the user\'s list');
        }
      }
    } else {
      if (kDebugMode) {
        print('User document does not exist or has no data.');
      }
    }

    // Add tool name to work order's 'Tools' array field
    await workOrderRef.update({
      'Tools': FieldValue.arrayUnion([tool.toolName]) // Directly add the toolName to the 'Tools' array
    }).catchError((error) {
      if (kDebugMode) {
        print('Error updating work order: $error');
      }
    });
  }

  //Helpers for admin
  Future<void> deleteToolEverywhere(Tool tool) async {
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');
    final workOrdersCollection = FirebaseFirestore.instance.collection('WorkOrders');
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      if (kDebugMode) {
        print('No user signed in.');
      }
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);

    try {
      // Retrieve the tool document by tool name
      DocumentSnapshot toolDoc = await toolsCollection.doc(tool.toolName).get();
      if (toolDoc.exists) {
        // Check if there's an image path to delete from Firebase Storage
        String? imagePath = toolDoc.get('Tool Image Path');
        if (imagePath != null && imagePath.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
          if (kDebugMode) {
            print('Image associated with Workorder ${tool.toolName} has been successfully deleted.');
          }
        }

        // Delete the tool document from the Firestore collection
        await toolsCollection.doc(tool.toolName).delete();
        if (kDebugMode) {
          print('Tool ${tool.toolName} has been successfully deleted from the Tools collection.');
        }

        // Remove the tool name from the 'Tools' array in the specific work order document
        if (tool.workOrderId != null) {
          DocumentReference workOrderDocRef = workOrdersCollection.doc(tool.workOrderId);
          await workOrderDocRef.update({
            'Tools': FieldValue.arrayRemove([tool.toolName])
          });
          if (kDebugMode) {
            print('Tool ${tool.toolName} has been successfully removed from WorkOrder ${tool.workOrderId}.');
          }
        } else {
          if (kDebugMode) {
            print('No workOrderId provided for ${tool.toolName}.');
          }
        }

        // Remove the tool name from the current user's 'Tools' array list
        await userDocRef.get().then((DocumentSnapshot userDocSnapshot) {
          if (userDocSnapshot.exists && userDocSnapshot.data() is Map<String, dynamic>) {
            Map<String, dynamic> userData = userDocSnapshot.data() as Map<String, dynamic>;
            List<dynamic> userTools = userData['Tools'] ?? [];
            if (userTools.contains(tool.toolName)) {
              userTools.remove(tool.toolName);
              userDocRef.update({'Tools': userTools});
              if (kDebugMode) {
                print('Tool ${tool.toolName} has been successfully removed from the current user\'s tool list.');
              }
            }
          }
        });
      } else {
        if (kDebugMode) {
          print('Tool document does not exist.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting tool ${tool.toolName}: $e');
      }
    }
  }

  Future<void> addToolToCollection(Tool tool) async {
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');

    // Creating a new document for the tool
    final docTool = toolsCollection.doc(toolName);
    final toolData = Tool(
      toolName: tool.toolName,
      dateCheckedOut: tool.dateCheckedOut,
      dateCheckedIn: tool.dateCheckedIn,
      personCheckedTool: tool.personCheckedTool,
      personReturnedTool: tool.personReturnedTool,
      whereBeingUsed: tool.whereBeingUsed,
      calibrationDate: tool.calibrationDate,
      imagePath: tool.imagePath,
      personAddedTool: personAddedTool,
    );
    final json = toolData.toJson();

    // Write data to Firestore for the new tool
    await docTool.set(json).then((_) {
      if (kDebugMode) {
        print('Tool added to Tools collection successfully.');
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('Error adding tool: $error');
      }
    });
  }

  Future<void> deleteToolFromWorkorder(Tool tool) async {
    final workOrdersCollection = FirebaseFirestore.instance.collection("WorkOrders");

    if (tool.workOrderId != null) {
      DocumentReference workOrderDocRef = workOrdersCollection.doc(tool.workOrderId);
      await workOrderDocRef.update({
        'Tools': FieldValue.arrayRemove([tool.toolName])
      });
      if (kDebugMode) {
        print('Tool ${tool.toolName} has been successfully removed from WorkOrder ${tool.workOrderId}.');
      }
    } else {
      if (kDebugMode) {
        print('No workOrderId provided for ${tool.toolName}.');
      }
    }
  }

}

//User helper functions.
Future<List<Tool>> getUserTools() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final userDocumentReference = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    try {
      final userSnapshot = await userDocumentReference.get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        List<String> toolNames = List.from(userSnapshot.data()?['Tools'] ?? []);
        List<Tool> toolDetails = [];

        final toolsCollection = FirebaseFirestore.instance.collection('Tools');

        for (String toolName in toolNames) {
          try {
            final toolDocumentSnapshot = await toolsCollection.doc(toolName).get();
            if (toolDocumentSnapshot.exists && toolDocumentSnapshot.data() != null) {
              toolDetails.add(Tool.fromJson(toolDocumentSnapshot.data()!));
            } else {
              if (kDebugMode) {
                print('Tool $toolName does not exist in the Tools collection.');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching tool $toolName: $e');
            }
          }
        }

        return toolDetails;
      } else {
        if (kDebugMode) {
          print('User does not exist in the database.');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user tools: $e');
      }
      if (kDebugMode) {
        print(currentUser.uid);
      }
      return [];
    }
  } else {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return [];
  }
}
Future<List<Tool>> getToolsFromToolIds(List<String> toolIds) async {
  List<Tool> tools = [];
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  for (String toolId in toolIds) {
    try {
      final toolDocumentSnapshot = await toolsCollection.doc(toolId).get();
      if (toolDocumentSnapshot.exists && toolDocumentSnapshot.data() != null) {
        tools.add(Tool.fromJson(toolDocumentSnapshot.data()!));
      } else {
        if (kDebugMode) {
          print('Tool $toolId does not exist in the Tools collection.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tool $toolId: $e');
      }
    }
  }
  return tools;
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
        if (kDebugMode) {
          print('Tool ${doc.id} does not exist in the Tools collection.');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching tools: $e');
    }
  }
  return toolDetails;
}
Future<void> updateTool(String toolId, String toolName, String whereBeingUsed, String personCheckedOut, String dateCheckedOut) async {
  final docRef = FirebaseFirestore.instance.collection("Tools").doc(toolId);

  // Fetch the current data of the tool
  final currentData = await docRef.get();
  if (!currentData.exists) {
    if (kDebugMode) {
      print('Tool not found.');
    }
    return;
  }

  Map<String, dynamic> newData = currentData.data()!;

  // Update "Tool Name" field in the newData map if toolName is provided
  if (toolName != null && toolName.isNotEmpty) {
    newData['Tool Name'] = toolName; // Ensure the "Tool Name" field is updated in the new document
  }

  // Add other updates to the newData map
  if (whereBeingUsed != null) newData['Machine Where Used'] = whereBeingUsed;
  if (personCheckedOut != null) newData['Person Checked Tool'] = personCheckedOut;
  if (dateCheckedOut != null) newData['Check Out Date'] = dateCheckedOut;

  // If the toolName is provided and different from the current ID, proceed to create a new document and delete the old one
  if (toolName != null && toolName != toolId) {
    final newDocRef = FirebaseFirestore.instance.collection("Tools").doc(toolName);
    await newDocRef.set(newData); // Create the new document with the updated data
    await docRef.delete(); // Delete the old document

    if (kDebugMode) {
      print('Tool updated with new ID and Tool Name successfully.');
    }
  } else {
    // If no new toolName is provided or it's the same as the current ID, just update the existing document
    await docRef.update(newData);

    if (kDebugMode) {
      print('Tool updated successfully.');
    }
  }
}
Future<Tool?> getToolByToolName(String toolName) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  QuerySnapshot querySnapshot = await firestore
      .collection('Tools')
      .where('Tool Name', isEqualTo: toolName) // Ensure the field name matches your Firestore document
      .limit(1)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    var doc = querySnapshot.docs.first;
    Tool tool = Tool.fromJson({
      'Tool ID': doc.id, // Pass the document ID as 'Tool ID'
      ...doc.data() as Map<String, dynamic>,
    });
    return tool;
  } else {
    return null;
  }
}




