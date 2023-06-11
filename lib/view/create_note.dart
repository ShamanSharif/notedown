import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  final TextEditingController titleController = TextEditingController();
  String title = "Untitled Document";

  @override
  void initState() {
    titleController.text = title;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => print("Save"),
            icon: const Icon(Ionicons.save),
          ),
          IconButton(
            onPressed: () => print("menu"),
            icon: const Icon(Ionicons.ellipsis_vertical),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          child: TextFormField(
            maxLines: 999,
            minLines: 10,
            decoration: const InputDecoration(
              border: InputBorder.none,
              // labelText: "John Cena's Name",
            ),
          ),
        ),
      ),
    );
  }
}
