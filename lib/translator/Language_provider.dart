import 'package:flutter/cupertino.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isMarathi = false;
  bool get isMarathi => _isMarathi;

  void toggle() {
    _isMarathi = !_isMarathi;
    notifyListeners();
  }
}

