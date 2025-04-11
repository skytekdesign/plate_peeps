import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'account_settings_page.dart';
import 'package:plate_peeps/widgets/saved_plate_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? savedPlate;
  String? savedState;
  List<Map<String, String>> comments = [];
  List<Map<String, String>> followedPlates = [];
  Map<String, List<Map<String, String>>> followedComments = {};
  final plateController = TextEditingController();
  String selectedState = 'California';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final List<String> states = [
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
  ];

  @override
  void initState() {
    super.initState();
    loadSavedPlate();
    loadFollowedPlates();
  }

  Future<void> loadSavedPlate() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    final data = doc.data();

    if (data != null && data.containsKey('savedPlate')) {
      savedPlate = data['savedPlate'];
      savedState = data['savedState'];
    }
    setState(() {});
  }

  Future<void> loadFollowedPlates() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    final data = doc.data();
    if (data != null && data.containsKey('followedPlates')) {
      final rawList = List<dynamic>.from(data['followedPlates']);
      followedPlates = rawList.map<Map<String, String>>((e) {
        final entry = Map<String, dynamic>.from(e);
        return {
          'plate': entry['plate']?.toString() ?? '',
          'state': entry['state']?.toString() ?? '',
        };
      }).toList();

      for (var plateInfo in followedPlates) {
        final key =
            '${plateInfo['state']!.toUpperCase()}-${plateInfo['plate']!.toUpperCase()}';
        final snapshot = await FirebaseFirestore.instance
            .collection('comments')
            .doc(key)
            .get();
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final raw = data['messages'];
          if (raw != null && raw is List) {
            followedComments[key] = raw
                .whereType<Map<String, dynamic>>()
                .map((e) => {
                      'text': e['text']?.toString() ?? '',
                      'username': e['username']?.toString() ?? 'Anonymous',
                      'timestamp': (e['timestamp'] is Timestamp)
                          ? (e['timestamp'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')[0]
                          : '',
                    })
                .toList();
          }
        }
      }
      setState(() {});
    }
  }

  Future<void> savePlate(String plate, String state) async {
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
      'savedPlate': plate,
      'savedState': state,
    }, SetOptions(merge: true));

    savedPlate = plate;
    savedState = state;
    setState(() {});
  }

  Future<void> deleteSavedPlate() async {
    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
      'savedPlate': FieldValue.delete(),
      'savedState': FieldValue.delete(),
    });
    savedPlate = null;
    savedState = null;
    setState(() {});
  }

  Future<void> updateEmailAndPassword() async {
    try {
      if (emailController.text.isNotEmpty) {
        await user?.updateEmail(emailController.text.trim());
      }
      if (passwordController.text.isNotEmpty) {
        await user?.updatePassword(passwordController.text.trim());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account updated successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .delete();
      await user?.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account deletion failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Account Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AccountSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SavedPlateSection(
              savedPlate: savedPlate,
              savedState: savedState,
              states: states,
              onSave: savePlate,
              onDelete: deleteSavedPlate,
            ),
            if (followedPlates.isNotEmpty) ...[
              const Divider(height: 32),
              const Text("Followed Plates:"),
              const SizedBox(height: 8),
              ...followedPlates.map((plateInfo) {
                final key =
                    '${plateInfo['state']!.toUpperCase()}-${plateInfo['plate']!.toUpperCase()}';
                final commentsList = followedComments[key] ?? [];
                return ExpansionTile(
                  title: Text("${plateInfo['state']} - ${plateInfo['plate']}"),
                  children: commentsList
                      .map((c) => ListTile(
                            title: Text(c['text'] ?? ''),
                            subtitle:
                                Text('@${c['username']} • ${c['timestamp']}'),
                          ))
                      .toList(),
                );
              })
            ],
            const Divider(height: 32),
            const Text("Update Email or Password:"),
            TextField(
              controller: emailController,
              decoration:
                  const InputDecoration(labelText: 'New Email (optional)'),
            ),
            TextField(
              controller: passwordController,
              decoration:
                  const InputDecoration(labelText: 'New Password (optional)'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: updateEmailAndPassword,
              child: const Text("Update Account"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: deleteAccount,
              child: const Text("Delete Account"),
            ),
          ],
        ),
      ),
    );
  }
}
