import 'package:flutter/material.dart';
import 'modal_type.dart';

class ModalManager extends ChangeNotifier {
  ModalType? _currentModal;
  dynamic _data;

  ModalType? get currentModal => _currentModal;

  dynamic get data => _data;

  void show(ModalType modal, {dynamic data}) {
    _currentModal = modal;
    _data = data;
    notifyListeners();
  }

  void close() {
    _currentModal = null;
    _data = null;
    notifyListeners();
  }
}
