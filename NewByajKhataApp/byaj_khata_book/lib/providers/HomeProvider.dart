import 'dart:developer';
import 'dart:io';

import 'package:byaj_khata_book/core/constants/SharedPreferenceKeys.dart';
import 'package:byaj_khata_book/data/models/Contact.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/ServiceLocator.dart';
import '../core/utils/HomeScreenEnum.dart';

class HomeProvider with ChangeNotifier {
  final prefs = SPInstane<SharedPreferences>();
  bool _isWithInterest = false;

  List<Contact> _withoutInterestContacts = [];
  List<Contact> _withInterestContacts = [];

  bool get isWithInterest => _isWithInterest;
  List<Contact> get withoutInterestContacts => _withoutInterestContacts;
  List<Contact> get withInterestContacts => _withInterestContacts;

  String _searchQuery = '';
  String _interestViewMode = 'all'; // 'all', 'get', 'pay'
  FilterMode _filterMode = FilterMode.all; // 'All', 'You received', 'You paid'
  SortMode _sortMode = SortMode.recent;

  String get searchQuery => _searchQuery;
  String get interestViewMode => _interestViewMode;
  FilterMode get filterMode => _filterMode;
  SortMode get sortMode => _sortMode;


  void getData(){

  }

  void updateSearchQuery(String value) {
    if (value != _searchQuery) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  void updateInterestViewMode(String value) {
    if (value != _interestViewMode) {
      _interestViewMode = value;
      notifyListeners();
    }
  }

  void updateFilterMode(FilterMode value) {
    if (value != _filterMode) {
      _filterMode = value;
      notifyListeners();
    }
  }

  void updateSortMode(SortMode value) {
    if (value != _sortMode) {
      _sortMode = value;
      notifyListeners();
    }
  }

  /// Update only _isWithInterest
  void updateIsWithInterest(bool value) {
    _isWithInterest = value;
    print(_isWithInterest);
    notifyListeners();
  }

  /// Update only _withoutInterestContacts
  void updateWithoutInterestContacts(List<Contact> contacts) {
    _withoutInterestContacts = contacts;
    notifyListeners();
  }

  /// Update only _withInterestContacts
  void updateWithInterestContacts(List<Contact> contacts) {
    _withInterestContacts = contacts;
    notifyListeners();
  }

  // Add methods to handle QR code storage
  Future<String?> getStoredQRCodePath() async {
    return prefs.getString(SharedPreferenceKeys.PAYMENT_QR_CODE_PATH);
  }

  // Add methods to handle QR code storage
  Future<void> setQRCodePath(File imageFile) async {
    await prefs.setString(
      SharedPreferenceKeys.PAYMENT_QR_CODE_PATH,
      imageFile.path,
    );
  }

  // delete QR Code
  Future<bool> deleteQRCode() async {
    try {
      await prefs.remove(SharedPreferenceKeys.PAYMENT_QR_CODE_PATH);
      return true;
    } catch (e) {
      return false;
    }
  }

}
