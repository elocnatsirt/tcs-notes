import 'package:hive/hive.dart';

part 'hive_database.g.dart';

@HiveType(typeId: 0)
class Note {
  @HiveField(0)
  String title;
  @HiveField(1)
  String body;
  @HiveField(2)
  String imageLocation;

  Note(this.title, this.body, this.imageLocation);
}
