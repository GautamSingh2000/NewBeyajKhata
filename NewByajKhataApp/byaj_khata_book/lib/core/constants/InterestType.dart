import 'package:hive/hive.dart';

part 'InterestType.g.dart';

@HiveType(typeId: 3)
enum InterestType {
  @HiveField(0)
  withInterest,

  @HiveField(1)
  withoutInterest,
}