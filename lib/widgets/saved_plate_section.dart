import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class SavedPlateSection extends StatefulWidget {
  final String? savedPlate;
  final String? savedState;
  final List<String> states;
  final Function(String, String) onSave;
  final Function onDelete;

  const SavedPlateSection({
    Key? key,
    required this.savedPlate,
    required this.savedState,
    required this.states,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<SavedPlateSection> createState() => _SavedPlateSectionState();
}

class _SavedPlateSectionState extends State<SavedPlateSection> {
  final plateController = TextEditingController();
  late String selectedState;
  bool isExpanded = false;
  List<Map<String, String>> comments = [];

  @override
  void initState() {
    super.initState();
    selectedState = widget.savedState ?? 'California';
    if (widget.savedPlate != null && widget.savedState != null) {
      loadComments();
    }
  }

  Future<void> loadComments() async {
    final key =
        '${widget.savedState!.toUpperCase()}-${widget.savedPlate!.toUpperCase()}';
    final snapshot =
        await FirebaseFirestore.instance.collection('comments').doc(key).get();

    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      final raw = data['messages'];
      if (raw != null && raw is List) {
        setState(() {
          comments = raw
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.savedPlate == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Save Your Plate:"),
          DropdownButton<String>(
            value: selectedState,
            isExpanded: true,
            onChanged: (value) => setState(() => selectedState = value!),
            items: widget.states
                .map((state) =>
                    DropdownMenuItem(value: state, child: Text(state)))
                .toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: plateController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))
            ],
            decoration: const InputDecoration(labelText: "License Plate"),
          ),
          ElevatedButton(
            onPressed: () {
              final plate = plateController.text.trim().toUpperCase();
              if (plate.isNotEmpty) {
                widget.onSave(plate, selectedState);
              }
            },
            child: const Text("Save Plate"),
          ),
        ],
      );
    } else {
      return ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (value) => setState(() => isExpanded = value),
        title:
            Text("${widget.savedState!.toUpperCase()} - ${widget.savedPlate!}"),
        subtitle: const Text("Your Saved Plate"),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          tooltip: "Remove Saved Plate",
          onPressed: () => widget.onDelete(),
        ),
        children: comments
            .map((c) => ListTile(
                  title: Text(c['text'] ?? ''),
                  subtitle: Text('@${c['username']} • ${c['timestamp']}'),
                ))
            .toList(),
      );
    }
  }
}
