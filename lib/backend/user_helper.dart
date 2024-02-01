import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addUserDetails(String firstName, String lastName, List<String>? tools, List<String>? favOrders ) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user signed in.');
    return;
  }
  final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
  String username = createUsername(firstName, lastName);
  await userDocRef.set({
    'First Name': firstName.trim(),
    'Last Name': lastName.trim(),
    'Email': username,
    'Tools': tools,
    'Favorite Workorders': favOrders,
  });
}

Future<String> getUserFullName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDocRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    try {
      final snapshot = await userDocRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        String firstName = snapshot.data()?['First Name'] ?? 'NoFirstName';
        String lastName = snapshot.data()?['Last Name'] ?? 'NoLastName';
        return '$firstName $lastName';
      } else {
        return 'User does not exist in the database.';
      }
    } catch (e) {
      return 'Error fetching user details: $e';
    }
  } else {
    return 'No user signed in.';
  }
}

String createUsername(String firstName, String lastName) {
  String formattedFirstName = firstName.trim().replaceAll(' ', '_').toLowerCase();
  String formattedLastName = lastName.trim().replaceAll(' ', '_').toLowerCase();

  return '$formattedFirstName$formattedLastName@vineburg.com';
}