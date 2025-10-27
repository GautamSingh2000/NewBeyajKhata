import 'package:hive/hive.dart';


part 'ContactType.g.dart';


@HiveType(typeId: 4) // pick a unique typeId not used yet
enum ContactType {
  @HiveField(0)
  borrower,//taker

  @HiveField(1)
  lender,//giver
}
