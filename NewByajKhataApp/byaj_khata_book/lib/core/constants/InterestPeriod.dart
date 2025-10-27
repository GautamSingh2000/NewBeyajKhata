import 'package:hive/hive.dart';

part 'InterestPeriod.g.dart';

@HiveType(typeId: 5) // pick another unique typeId
enum InterestPeriod {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  yearly,
}
