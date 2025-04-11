import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // for PlatePeepsHome if it's there

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({Key? key}) : super(key: key);

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;

  Future<void> saveUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': FirebaseAuth.instance.currentUser!.email,
      });
    }

    setState(() => isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PlatePeepsHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose a Username")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Pick a unique username for your PlatePeeps profile."),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveUsername,
                    child: const Text("Save Username"),
                  ),
          ],
        ),
      ),
    );
  }
}
