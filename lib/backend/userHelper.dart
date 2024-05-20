import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<void> addUserDetails(String firstName) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (kDebugMode) {
      print('No user signed in.');
    }
    return;
  }
  final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
  String username = createUsername(firstName);
  await userDocRef.set({
    'First Name': firstName.trim(),
    'Email': username,

  });
}

String createUsername(String firstName) {
  String formattedFirstName = firstName.trim().replaceAll(' ', '_').toLowerCase();

  return '$formattedFirstName@vineburg.com';
}