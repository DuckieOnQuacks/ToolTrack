import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../classes/tool_class.dart';

class UserInspectToolScreen extends StatefulWidget {
  final Tool tool;

  const UserInspectToolScreen({super.key, required this.tool});

  @override
  _UserInspectToolScreenState createState() => _UserInspectToolScreenState();
}

class _UserInspectToolScreenState extends State<UserInspectToolScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.blueAccent,
            iconSize: 100.0,
            onPressed: () =>
                _showImageFullscreen(context, widget.tool.imagePath),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
              children: <TextSpan>[
                const TextSpan(
                  text: 'Tool Name: ',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextSpan(text: widget.tool.toolName),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
              children: <TextSpan>[
                const TextSpan(
                  text: "Located At Machine: ",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: widget.tool.whereBeingUsed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
              children: <TextSpan>[
                const TextSpan(
                  text: "Checked Out To: ",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: widget.tool.personCheckedTool,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18.0, color: Colors.black),
              children: <TextSpan>[
                const TextSpan(
                  text: "Check Out Date: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: widget.tool.dateCheckedOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }


  void _showImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          Scaffold(
            appBar: AppBar(
              title: const Text('Tool Image'),
              leading: const BackButton(), // Uses default back button
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
    ));
  }
}
