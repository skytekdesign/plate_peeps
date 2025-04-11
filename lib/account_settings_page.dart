import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final newEmailController = TextEditingController();
  final newPasswordController = TextEditingController();

  Future<void> updateEmail() async {
    try {
      await user?.updateEmail(newEmailController.text.trim());
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email updated! Check inbox to verify.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> updatePassword() async {
    try {
      await user?.updatePassword(newPasswordController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await user?.delete();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmailPasswordUser =
        user?.providerData.any((info) => info.providerId == 'password') ??
            false;

    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Logged in as: ${user?.email}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (isEmailPasswordUser) ...[
              const Text("Update Email"),
              TextField(
                  controller: newEmailController,
                  decoration: const InputDecoration(labelText: "New Email")),
              ElevatedButton(
                  onPressed: updateEmail, child: const Text("Update Email")),
              const SizedBox(height: 20),
              const Text("Update Password"),
              TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password")),
              ElevatedButton(
                  onPressed: updatePassword,
                  child: const Text("Update Password")),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: deleteAccount,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete Account"),
            ),
          ],
        ),
      ),
    );
  }
}
