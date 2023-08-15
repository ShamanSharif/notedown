import 'package:hive/hive.dart';

import '../model/note.dart';

class Boxes {
  static Box<Note> getNotes() => Hive.box<Note>('notes');
}
