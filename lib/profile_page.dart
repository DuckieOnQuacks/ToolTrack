import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'classes/user_class.dart'; // Make sure this path is correct according to your project structure
import 'login_page.dart'; // Make sure this path is correct according to your project structure

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserClass?> currentUserFuture;

  @override
  void initState() {
    super.initState();
    currentUserFuture = getCurrentUser(); // This method should be an async method returning a Future<UserClass>
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        centerTitle: true,
      ),
      body: FutureBuilder<UserClass?>(
        future: currentUserFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final currentUser = snapshot.data!;
            final fullname = createUsername(currentUser.firstName, currentUser.lastName);
            return buildProfileView(fullname, currentUser.email); // Assuming `email` is a field in UserClass
          }
        },
      ),
    );
  }

  Widget buildProfileView(String fullname, String email) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircleAvatar(
            radius: 50.0,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(height: 20.0),
          Text(
            fullname,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Text(
            email,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () => logout(context),
          ),
        ],
      ),
    );
  }

  void logout(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          buttonPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: const Text('Are you sure you want to log out of your account?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black54, backgroundColor: Colors.grey[300],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  String createUsername(String firstName, String lastName) {
    String formattedFirstName = firstName.trim().replaceAll(' ', '_').toLowerCase();
    String formattedLastName = lastName.trim().replaceAll(' ', '_').toLowerCase();
    return '$formattedFirstName $formattedLastName';
  }
}

