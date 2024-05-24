import 'package:cloud_firestore/cloud_firestore.dart';

class UserClass {
  String email;
  String id;

  UserClass({
    required this.email,
    required this.id,
  });

  /// Converts a Firestore document to a User object.
  factory UserClass.fromJson(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserClass(
      email: data['Email'],
      id: data['Id'],
    );
  }

  /// Converts the User object to a Map.
  Map<String, dynamic> toJson() => {
        'Email': email,
        'Id': id,
      };
}
