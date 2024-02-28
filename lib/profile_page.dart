import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/backend/user_helper.dart';

import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 50.0,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(height: 20.0),
            RichText(
              text: const TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "User Name: ",
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "name",
                  ),
                ],
              ),
            ),
            const Text(
              'User Name',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              'user@example.com',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      buttonPadding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      title: const Row(
                          children:[
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
                          ]
                      ),
                      content: const Text(
                          'Are you sure you want to log out of your account?'),
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
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (
                                    BuildContext context) {
                                  return const LoginPage();
                                })
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
                ).then((value) {
                  if (value != null && value == true) {
                    // Perform deletion logic here
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
