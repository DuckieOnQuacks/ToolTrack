import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vineburgapp/backend/message_helper.dart';
import 'package:vineburgapp/classes/work_order_class.dart';

class Tool{
  late final String? id;
  late final String toolName;
  late final String dateCheckedOut;
  late final String? dateCheckedIn;
  late final String personCheckedTool;
  late final String? personReturnedTool;
  late final String whereBeingUsed;
  late final String calibrationDate;

  Tool({this.id,
    required this.toolName,
    required this.dateCheckedOut,
    this.dateCheckedIn,
    required this.personCheckedTool,
    this.personReturnedTool,
    required this.whereBeingUsed,
    required this.calibrationDate});

  // Factory method to create a Machine object from JSON data
  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    id: json['Tool ID'] as String?,
    toolName: json['Tool Name'] as String? ?? '',
    dateCheckedOut: json["Check Out Date"] as String? ?? '',
    dateCheckedIn: json['Check In Date'] as String?,
    personCheckedTool: json['Person Checked Tool'] as String? ?? '',
    personReturnedTool: json['Person Returned Tool'] as String?,
    whereBeingUsed: json['Machine Where Tool Is Used '] as String? ?? '',
    calibrationDate: json['Calibration Date'] as String? ?? '',
  );


// Method to convert a Machine object to JSON data
  Map<String, dynamic> toJson() =>
      {
        'Tool ID': id,
        'Tool Name': toolName,
        'Check Out Date': dateCheckedOut,
        'Check In Date':dateCheckedIn,
        'Person Checked Tool': personCheckedTool,
        'Person Returned Tool' : personReturnedTool,
        'Machine Where Tool Is Used': whereBeingUsed,
        'Calibration Date': calibrationDate,
      };

  // Variables to store machine data
  String tableName = 'Tools';

  //Helpers for user
  Future<void> addToolToUserAndWorkOrder(Tool tool, String workOrderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('No user signed in.');
      return;
    }

    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');
    final workOrderRef = FirebaseFirestore.instance.collection('WorkOrders').doc(workOrderId);

    // Creating a new document for the tool
    final docTool = toolsCollection.doc();
    final orderTable = Tool(
      id: docTool.id,
      toolName: tool.toolName,
      dateCheckedOut: tool.dateCheckedOut,
      dateCheckedIn: tool.dateCheckedIn,
      personCheckedTool: tool.personCheckedTool,
      personReturnedTool: tool.personReturnedTool,
      whereBeingUsed: tool.whereBeingUsed,
      calibrationDate: tool.calibrationDate,
    );
    final json = orderTable.toJson();

    // Write data to Firestore for the new tool
    await docTool.set(json);

    // Add tool to user's list
    final userSnapshot = await userDocRef.get();
    if (userSnapshot.exists) {
      var userData = userSnapshot.data();
      var userToolsArray = userData != null && userData['Tools'] is List
          ? List<String>.from(userData['Tools'])
          : [];

      if (!userToolsArray.contains(docTool.id)) {
        userToolsArray.add(docTool.id);
        await userDocRef.update({
          'Tools': userToolsArray,
        });

      } else {
        print('Tool is already in the user\'s list');
      }
    } else {
      print('User document does not exist or has no data.');
    }

    // Add tool to work order
    await workOrderRef.update({
      'Tools': FieldValue.arrayUnion([toolName]) // Add the toolId to the 'Tools' array in the work order
    }).catchError((error) {
      print('Error updating work order: $error');
    });
  }

  //Helpers for admin
  Future<void> deleteTool(Tool tool) async {
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');

    try {
      await toolsCollection.doc(tool.id).delete();
      print('Tool ${tool.id} has been successfully deleted from the Tools collection.');
    } catch (e) {
      print('Error deleting tool ${tool.id}: $e');
    }
  }

  Future<void> addToolToCollection(Tool tool) async {
    final toolsCollection = FirebaseFirestore.instance.collection('Tools');

    // Creating a new document for the tool
    final docTool = toolsCollection.doc();
    final toolData = Tool(
      id: docTool.id,
      toolName: tool.toolName,
      dateCheckedOut: tool.dateCheckedOut,
      dateCheckedIn: tool.dateCheckedIn,
      personCheckedTool: tool.personCheckedTool,
      personReturnedTool: tool.personReturnedTool,
      whereBeingUsed: tool.whereBeingUsed,
      calibrationDate: tool.calibrationDate,
    );
    final json = toolData.toJson();

    // Write data to Firestore for the new tool
    await docTool.set(json).then((_) {
      print('Tool added to Tools collection successfully.');
    }).catchError((error) {
      print('Error adding tool: $error');
    });
  }
}

//User helper functions.
Future<List<Tool>> getUserTools() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final userDocumentReference = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    print('Here');
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
              print('Tool $toolName does not exist in the Tools collection.');
            }
          } catch (e) {
            print('Error fetching tool $toolName: $e');
          }
        }

        return toolDetails;
      } else {
        print('User does not exist in the database.');
        return [];
      }
    } catch (e) {
      print('Error fetching user tools: $e');
      print(currentUser.uid);
      return [];
    }
  } else {
    print('No user signed in.');
    return [];
  }
}

//Admin helper functions.
Future<List<Tool>> getAllTools() async {
  List<Tool> toolDetails = [];
  final toolsCollection = FirebaseFirestore.instance.collection('Tools');

  try {
    final querySnapshot = await toolsCollection.get();
    for (var doc in querySnapshot.docs) {
      if (doc.exists && doc.data() != null) {
        toolDetails.add(Tool.fromJson(doc.data()!));
      } else {
        print('Tool ${doc.id} does not exist in the Tools collection.');
      }
    }
  } catch (e) {
    print('Error fetching tools: $e');
  }

  return toolDetails;
}





