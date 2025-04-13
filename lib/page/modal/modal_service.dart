import 'package:flutter/cupertino.dart';

import 'modal_type.dart';

class ModalManager extends ChangeNotifier {
  ModalType? _currentModal;

  ModalType? get currentModal => _currentModal;

  void show(ModalType modal) {
    _currentModal = modal;
    notifyListeners();
  }

  void close() {
    _currentModal = null;
    notifyListeners();
  }
}
