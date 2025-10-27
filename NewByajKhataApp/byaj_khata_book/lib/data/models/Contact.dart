import 'dart:ui';

import 'package:hive/hive.dart';

import '../../core/constants/ContactType.dart';
import '../../core/constants/InterestPeriod.dart';
import '../../core/constants/InterestType.dart';

part 'Contact.g.dart';

@HiveType(typeId: 0)
class Contact {
  @HiveField(0)
  String contactId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double interestRate;

  @HiveField(3)
  InterestPeriod? interestPeriod;

  @HiveField(4)
  ContactType contactType; // borrower / lender

  @HiveField(5)
  int? colorValue; // store as int

  @HiveField(6)
  DateTime lastEditedAt;

  @HiveField(7)
  InterestType interestType;

  @HiveField(8)
  double interestDue;

  @HiveField(9)
  double principal;

  @HiveField(10)
  double displayAmount;

  @HiveField(11)
  String initials;

  @HiveField(12)
  int dayAgo;

  @HiveField(13)
  bool isGet;

  @HiveField(14)
  String? displayPhone;

  @HiveField(15)
  String category;

  @HiveField(16)
  bool isNewContact;

  @HiveField(17)
  String? profileImage;

  Contact({
    //contactId is the combination of phoneNo_name or phoneNo_InterestType
    required this.contactId,
    required this.name,
    this.displayPhone,
    this.initials = "AA",
    this.interestRate = 0,
    this.interestPeriod,
    this.contactType = ContactType.borrower,
    this.colorValue,
    this.dayAgo = 0,
    DateTime? lastEditedAt,
    this.interestType = InterestType.withoutInterest,
    this.interestDue = 0,
    this.isGet = false,
    this.isNewContact = false,
    this.profileImage,
    this.principal = 0,
    this.displayAmount = 0,
    this.category = 'Personal',
  }) : lastEditedAt = lastEditedAt ?? DateTime.now();

  Color? get color => colorValue != null ? Color(colorValue!) : null;
  set color(Color? c) => colorValue = c?.value;

}

