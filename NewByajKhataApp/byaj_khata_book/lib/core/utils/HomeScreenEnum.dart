enum InterestViewMode { all, get, pay }

enum FilterMode { all, youReceived, youPaid }
extension FilterModeText on FilterMode {
  String get label {
    switch (this) {
      case FilterMode.all:
        return "All";
      case FilterMode.youReceived:
        return "You received";
      case FilterMode.youPaid:
        return "You paid";
    }
  }
}

enum SortMode { recent, highToLow, lowToHigh, byName }
extension SortModeText on SortMode {
  String get label {
    switch (this) {
      case SortMode.recent:
        return "Recent";
      case SortMode.highToLow:
        return "High to Low";
      case SortMode.lowToHigh:
        return "Low to High";
      case SortMode.byName:
        return "By Name";
    }
  }
}


enum BottomBarItems {
  // home(id: 'home', title: 'Home'),
  // loans(id: 'loans', title: 'Loans'),
  // cards(id: 'cards', title: 'Cards'),
  // billDiary(id: 'bill_diary', title: 'Bills'),
  // emiCalc(id: 'emi_calc', title: 'EMI Calc'),
  // sipCalc(id: 'sip_calc', title: 'SIP Calc'),
  // taxCalc(id: 'tax_calc', title: 'Tax Calc'),
  // milkDiary(id: 'milk_diary', title: 'Milk'),
  // workDiary(id: 'work_diary', title: 'Work'),
  // teaDiary(id: 'tea_diary', title: 'Tea'),
  // tools(id: 'tools', title: 'tools');

  home(id: 'home', title: 'Home'),
  loans(id: 'loans', title: 'Loans'),
  emiCalc(id: 'emi_calc', title: 'EMI Calc'),
  profile(id: 'profile', title: 'Profile');

  final String id;
  final String title;

  const BottomBarItems({required this.id, required this.title});
}
