import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'username_screen.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //this will test the log for firebase to be initialized
  print("Firebase initialized");
  runApp(const PlatePeepsApp());
}

class PlatePeepsApp extends StatelessWidget {
  const PlatePeepsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlatePeeps',
      theme: ThemeData.dark(),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        //this is the username info
        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;

              if (userData == null || !userData.containsKey('username')) {
                return const UsernameScreen(); // 🚀 Launch the username setup screen
              }

              return const PlatePeepsHome();
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const PlatePeepsHome(); // User is signed in
        } else {
          return const AuthScreen(); // Show sign-in/register// Show login screen
        }
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isRegistering = false;

  Future<void> handleEmailAuth() async {
    try {
      if (isRegistering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google sign-in failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Error: $e")),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // User canceled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegistering ? "Register" : "Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: handleGoogleSignIn,
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
            ),
            const Divider(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleEmailAuth,
              child: Text(isRegistering ? 'Register with Email' : 'Sign In'),
            ),
            TextButton(
              onPressed: () {
                setState(() => isRegistering = !isRegistering);
              },
              child: Text(
                isRegistering
                    ? "Already have an account? Sign in"
                    : "No account? Register here",
              ),
            ),
            //Forgot password button and link
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter your email above first.")),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password reset link sent!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Forgot Password?"),
            ),
          ],
        ),
      ),
    );
  }
}

class PlatePeepsHome extends StatefulWidget {
  const PlatePeepsHome({Key? key}) : super(key: key);

  @override
  State<PlatePeepsHome> createState() => _PlatePeepsHomeState();
}

class _PlatePeepsHomeState extends State<PlatePeepsHome> {
  bool followThisPlate = false;
  bool isAlreadyFollowing = false;
// 👈🏽 Add this here
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

  String selectedState = 'California';
  String licensePlate = '';
  String comment = '';

  final TextEditingController plateController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  @override
  void dispose() {
    plateController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadComments() async {
    if (licensePlate.isEmpty) return;

    final key = '${selectedState.toUpperCase()}-${licensePlate.toUpperCase()}';
    final snapshot =
        await FirebaseFirestore.instance.collection('comments').doc(key).get();

    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      final raw = data['messages'];

      if (raw != null && raw is List) {
        final cleaned = raw.whereType<Map>().map((item) {
          return {
            'text': item['text'] ?? '',
            'timestamp': item['timestamp'] ?? Timestamp.now(),
            'username': item['username'] ?? 'Anonymous',
          };
        }).toList();

        // 🔽 Sort comments by timestamp (descending = newest first)
        cleaned.sort((a, b) {
          final ta = a['timestamp'] as Timestamp;
          final tb = b['timestamp'] as Timestamp;
          return tb.compareTo(ta);
        });

        setState(() {
          comments = List<Map<String, dynamic>>.from(cleaned);
        });
      }
    } else {
      setState(() => comments = []);
    }
  }

  Future<void> submitComment() async {
    print("🔹 submitComment() called");

    if (licensePlate.isEmpty || comment.isEmpty) {
      print("❌ Cannot submit: licensePlate or comment is empty");
      return;
    }

    final key = '${selectedState.toUpperCase()}-${licensePlate.toUpperCase()}';
    final docRef = FirebaseFirestore.instance.collection('comments').doc(key);

    try {
      final snapshot = await docRef.get();
      List<Map<String, dynamic>> existingComments = [];

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final raw = data['messages'];
        if (raw != null && raw is List) {
          // 🔧 Convert list items to map if possible
          existingComments = raw.whereType<Map>().map((item) {
            return {
              'text': item['text'] ?? '',
              'timestamp': item['timestamp'] ?? Timestamp.now(),
            };
          }).toList();
          print(
              "📥 Loaded existing valid comments: ${existingComments.length}");
        }
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      final newComment = {
        'text': comment,
        'timestamp': Timestamp.now(),
        'username': username,
      };

      existingComments.add(newComment);

      await docRef.set({'messages': existingComments});
      print("✅ Comment submitted to Firestore for $key");

      setState(() {
        comment = '';
        commentController.clear();
      });

      await loadComments(); // Refresh comments
    } catch (e) {
      print("❌ Firestore write error: $e");
    }
    // ... existing comment submission code ...

// ✅ Follow plate if checkbox is selected
    final currentUser = FirebaseAuth.instance.currentUser;
    if (followThisPlate && currentUser != null) {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final userSnapshot = await userDocRef.get();
      final existingList = userSnapshot.data()?['followedPlates'] ?? [];

      final plateEntry = {
        'plate': licensePlate.toUpperCase(),
        'state': selectedState,
      };

      // Only add if not already in list
      final alreadyFollowing = existingList.any((e) =>
          e['plate'] == plateEntry['plate'] &&
          e['state'] == plateEntry['state']);

      if (!alreadyFollowing) {
        await userDocRef.update({
          'followedPlates': FieldValue.arrayUnion([plateEntry]),
        });
        print("✅ Plate followed: $plateEntry");
      }
    }
  }

  Future<void> checkIfFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || licensePlate.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final followed = userDoc.data()?['followedPlates'] ?? [];

    setState(() {
      isAlreadyFollowing = followed.any((p) =>
          p['plate'] == licensePlate.toUpperCase() &&
          p['state'] == selectedState);
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = '${selectedState.toUpperCase()}-${licensePlate.toUpperCase()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlatePeeps'),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final username = userData?['username'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    '@$username',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
          //profile button
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Image.asset(
                'assets/plate_peeps_logo.png',
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select State:'),
            DropdownButton<String>(
              value: selectedState,
              isExpanded: true,
              onChanged: (value) {
                setState(() => selectedState = value!);
                checkIfFollowing();
                loadComments(); // refresh comments when state changes
              },
              items: states.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('License Plate (alphanumeric only):'),
            TextField(
              controller: plateController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: (value) {
                setState(() => licensePlate = value.toUpperCase());
                checkIfFollowing();
                loadComments();
              },
              decoration: const InputDecoration(
                hintText: 'ABC1234',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Leave a Comment (max 250 characters):'),
            TextField(
              controller: commentController,
              maxLength: 250,
              onChanged: (value) {
                setState(() => comment = value);
              },
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Your comment here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            //Checkbox to follow this plate
            if (!isAlreadyFollowing) ...[
              CheckboxListTile(
                value: followThisPlate,
                onChanged: (value) {
                  setState(() {
                    followThisPlate = value ?? false;
                  });
                },
                title: const Text("Follow this plate"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            ElevatedButton(
              onPressed: () {
                final plate = plateController.text.trim().toUpperCase();
                final note = commentController.text.trim();

                if (plate.isNotEmpty && note.isNotEmpty) {
                  setState(() {
                    licensePlate = plate;
                    comment = note;
                  });
                  submitComment();
                } else {
                  print("One or both fields are empty");
                }
              },
              child: const Text('Submit Comment'),
            ),
            const Divider(height: 40),
            Text(
              'Comments for $key:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...comments.map((c) {
              final text = c['text'] ?? '';
              final username = c['username'] ?? 'Anonymous';
              final timestamp = c['timestamp'];
              String dateStr = '';

              if (timestamp is Timestamp) {
                final dt = timestamp.toDate();
                dateStr = '${dt.month}/${dt.day}/${dt.year}';
              }

              return Card(
                child: ListTile(
                  title: Text(text),
                  subtitle: Text(
                      '@$username ${dateStr.isNotEmpty ? " • $dateStr" : ""}'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
