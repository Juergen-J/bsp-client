import 'package:flutter/material.dart';
import 'modal_type.dart';

class ModalEntry {
  final ModalType type;
  final dynamic data;

  ModalEntry(this.type, this.data);
}

class ModalManager extends ChangeNotifier {
  final List<ModalEntry> _stack = [];

  List<ModalEntry> get stack => List.unmodifiable(_stack);

  ModalType? get currentModal => _stack.isNotEmpty ? _stack.last.type : null;

  dynamic get data => _stack.isNotEmpty ? _stack.last.data : null;

  void show(ModalType modal, {dynamic data}) {
    _stack.add(ModalEntry(modal, data));
    notifyListeners();
  }

  void close() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  void closeAll() {
    _stack.clear();
    notifyListeners();
  }
}
