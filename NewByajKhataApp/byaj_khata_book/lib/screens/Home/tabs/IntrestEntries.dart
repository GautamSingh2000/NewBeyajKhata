import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/HomeScreenEnum.dart';
import '../../../data/models/Contact.dart';
import '../../../providers/HomeProvider.dart';
import '../../../providers/TransactionProviderr.dart';
import '../../../widgets/HomeScreenContactList.dart';
import 'StandardEntries.dart';

class InterestEntries extends StatefulWidget {
  const InterestEntries({super.key});

  @override
  State<InterestEntries> createState() => _InterestEntriesState();
}

class _InterestEntriesState extends State<InterestEntries> {
  bool _isWithInterest = true;

  String _searchQuery = '';
  String _interestViewMode = 'all';
  FilterMode _filterMode = FilterMode.all;
  SortMode _sortMode = SortMode.recent;

  List<Contact> _filteredContacts = [];

  HomeProvider? _provider; // ✅ make nullable
  VoidCallback? _providerListener; // ✅ make nullable

  @override
  void initState() {
    super.initState();

    // Initialize provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _provider = Provider.of<HomeProvider>(context, listen: false);

      _searchQuery = _provider?.searchQuery ?? '';
      _interestViewMode = _provider?.interestViewMode ?? 'all';
      _filterMode = _provider?.filterMode ?? FilterMode.all;
      _sortMode = _provider?.sortMode ?? SortMode.recent;

      _providerListener = () {
        if (!mounted) return;
        setState(() {
          _searchQuery = _provider?.searchQuery ?? '';
          _interestViewMode = _provider?.interestViewMode ?? 'all';
          _filterMode = _provider?.filterMode ?? FilterMode.all;
          _sortMode = _provider?.sortMode ?? SortMode.recent;
        });
      };

      _provider?.addListener(_providerListener!);
    });
  }

  @override
  void dispose() {
    // ✅ null-safe cleanup
    if (_provider != null && _providerListener != null) {
      _provider!.removeListener(_providerListener!);
    }
    _provider = null;
    _providerListener = null;
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProviderr>(context);
    _filteredContacts = transactionProvider.getFilteredAndSortedContacts(
      isWithInterest: _isWithInterest,
      filterMode: _filterMode,
      sortMode: _sortMode,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: homeScreenContactsList(
              _filteredContacts,
              _searchQuery,
              _isWithInterest,
            ),
          ),
        ],
      ),
    );
  }
}
