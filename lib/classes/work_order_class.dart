
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vineburgapp/backend/user_helper.dart';

class WorkOrder {
  final String id;
  final String po;
  final String partNum;
  final List<String>? tool;
  final String partName;
  late String imagePath; // Path to the image of the work order
  late bool isFavorited;
  late String enteredBy;

  WorkOrder({required this.id, required this.po, required this.partNum, required this.partName, required this.imagePath, required this.isFavorited, this.tool, required this.enteredBy});


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
      };

  Future<void> deleteWorkorder(WorkOrder workOrder) async {
    final workOrderCollection = FirebaseFirestore.instance.collection('WorkOrders');

    try {
      // Fetch the work order document
      DocumentSnapshot workOrderDoc = await workOrderCollection.doc(workOrder.id).get();

      if (workOrderDoc.exists) {
        String? imagePath = workOrderDoc.get('ImagePath');

        // Delete the image from Firebase Storage if the image path exists
        if (imagePath != null && imagePath.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
          print('Image associated with Workorder ${workOrder.id} has been successfully deleted.');
        }

        // Delete the work order document
        await workOrderCollection.doc(workOrder.id).delete();
        print('Workorder ${workOrder.id} has been successfully deleted from the Workorder collection.');
      } else {
        print('Work Order ${workOrder.id} not found.');
      }
    } catch (e) {
      print('Error deleting workorder ${workOrder.id}: $e');
    }
  }

}

String tableName = 'WorkOrders';

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
      print('The work order does not have a valid \'Tools\' field or it is empty.');
      return [];
    }
  } else {
    // The work order document does not exist
    print('The specified work order does not exist.');
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
  );
  final json = orderTable.toJson();
  // Create document and write data to Firestore
  await docOrder.set(json);
}

// Function to mark a WorkOrder as favorite in Firestore
Future<void> favoriteWorkOrder(String docId, bool state) async {
  final docOrder = FirebaseFirestore.instance.collection(tableName).doc(docId);

  // Update only the isFavorited field in the document
  await docOrder.update({'isFavorited': state});
}

// Function to get the favorite status of a WorkOrder from Firestore
Future<bool> getFavoriteStatus(String docId) async {
  final docOrder = FirebaseFirestore.instance.collection(tableName).doc(docId);

  try {
    // Get the document
    DocumentSnapshot docSnapshot = await docOrder.get();
    if (docSnapshot.exists && docSnapshot.data() != null) {
      // Extract the isFavorited field value
      bool isFavorited = docSnapshot.get('isFavorited') ?? false;
      return isFavorited;
    } else {
      // If the document does not exist, return false or handle as appropriate
      return false;
    }
  } catch (e) {
    // Handle errors, such as network issues or permission errors
    print("Error fetching favorite status: $e");
    return false; // Return false or handle as appropriate
  }
}

// Function to add a work order with individual parameters and an image
Future<void> addWorkOrderWithParams(String partName, String po, String partNum, String imagePath, bool isFavorited, List<String> tools) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print('No user signed in.');
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
    enteredBy: await getUserFullName()
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


