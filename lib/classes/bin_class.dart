import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../backend/message_helper.dart';

class Bin {
  String originalName;
  List<String?> tools;
  String location;
  bool finished;

  Bin({
    required this.originalName,
    required this.tools,
    required this.location,
    required this.finished
  });

// Factory method to create a bin object from JSON data
  factory Bin.fromJson(Map<String, dynamic> json) => Bin(
    originalName: json['Name'],
    tools: List<String>.from(json['Tools'] ?? []),
    location: json['Location'],
    finished: json['Finished'],
  );

  // Method to convert a bin object to JSON data
  Map<String, dynamic> toJson() => {
    'Name': originalName,
    'Tools': tools,
    'Location': location,
    'Finished': finished
  };
}

/// Retrieves all bins from the Firestore database.
Future<List<Bin>> getAllBins() async {
  List<Bin> binDetails = [];
  final binsCollection = FirebaseFirestore.instance.collection('Bins');

  try {
    final querySnapshot = await binsCollection.get();
    for (var doc in querySnapshot.docs) {
      if (doc.exists) {
        binDetails.add(Bin.fromJson(doc.data()));
      } else {
        if (kDebugMode) {
          print('Bin ${doc.id} does not exist in the Bins collection.');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching bins: $e');
    }
  }
  return binDetails;
}

/// Deletes a tool from the Firestore database given a Tool object as well as the image associated with it.
Future<void> deleteBin(Bin bin) async {
  final binsCollection = FirebaseFirestore.instance.collection('Bins');
  // Replace '/' with '|'
  String documentName = bin.originalName.replaceAll('|', '/');
  try {
    final binDoc = binsCollection.doc(documentName);
    final docSnapshot = await binDoc.get();

    if (docSnapshot.exists) {
      // Delete the document.
      await binDoc.delete();
      if (kDebugMode) {
        print('Bin with ID ${bin.originalName} has been deleted.');
      }
    } else {
      if (kDebugMode) {
        print('Bin with ID ${bin.originalName} does not exist in the database.');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error deleting bin with ID ${bin.originalName}: $e');
    }
  }
}

Future<void> updateBinIfDifferent(Bin oldBin, Bin newBin) async {
  final binsCollection = FirebaseFirestore.instance.collection('Bins');
  String sanitizedName = oldBin.originalName.replaceAll('/', '|');
  final binDoc = binsCollection.doc(sanitizedName);

  // If the bin name has changed, delete the old bin and create a new one with the new name.
  if (oldBin.originalName != newBin.originalName) {
    try {
      // Delete the old bin.
      await binDoc.delete();
      if (kDebugMode) {
        print('Old bin with name ${oldBin.originalName} has been deleted.');
      }
      String sanitized2 = newBin.originalName.replaceAll('/', "|");
      // Create a new bin with the new name.
      final newBinDoc = binsCollection.doc(sanitized2);
      final newBinData = Bin(
        originalName: newBin.originalName,
        location: newBin.location.isNotEmpty ? newBin.location : oldBin.location,
        tools: newBin.tools.isNotEmpty ? newBin.tools : oldBin.tools,
        finished: newBin.finished ? newBin.finished : oldBin.finished,
      ).toJson();

      await newBinDoc.set(newBinData);
      if (kDebugMode) {
        print('New bin with name ${newBin.originalName} has been created.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating bin with name ${oldBin.originalName}: $e');
      }
    }
    return;
  }

  Map<String, dynamic> updates = {};

  if (oldBin.location != newBin.location) {
    updates['Location'] = newBin.location;
  }
  if (!const ListEquality().equals(oldBin.tools, newBin.tools)) {
    updates['Tools'] = newBin.tools;
  }
  if (oldBin.finished != newBin.finished) {
    updates['Finished'] = newBin.finished;
  }

  if (updates.isNotEmpty) {
    try {
      await binDoc.update(updates);
      if (kDebugMode) {
        print('Bin with name ${oldBin.originalName} has been updated.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating bin with name ${oldBin.originalName}: $e');
      }
    }
  }

  if (updates.isNotEmpty) {
    try {
      await binDoc.update(updates);
      if (kDebugMode) {
        print('Bin with name ${oldBin.originalName} has been updated with new information.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating bin with name ${oldBin.originalName}: $e');
      }
    }
  } else {
    if (kDebugMode) {
      print('No differences found between the old and new bin information.');
    }
  }
}

Future<void> addBinWithParams(String originalName, String location, List<String> tools, bool finished) async {
  // Check if the user is signed in.
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('No user signed in.');
      }
      return;
    }

    String documentName = originalName.replaceAll('/', '|');

    // Prepare the tool data and write it to Firestore.
    final docOrder = FirebaseFirestore.instance.collection("Bins").doc(documentName);
    final bin = Bin(
      originalName: originalName,
      tools: tools,
      location: location,
      finished: finished,
    );
    final json = bin.toJson();
    await docOrder.set(json); // Create document and write data to Firestore.
    if (kDebugMode) {
      print("Successfully added new bin");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Failed to upload new bin: $e");
    }
  }
}

String formatBinID(binID) {
  String documentName = binID.replaceAll('/', '|');
  return documentName;
}
