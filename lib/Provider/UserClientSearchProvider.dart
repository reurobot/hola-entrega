import 'package:eshop_multivendor/Helper/debounce.dart';
import 'package:eshop_multivendor/Model/user_client_search.dart';
import 'package:eshop_multivendor/repository/userClientSearchRepository.dart';
import 'package:flutter/material.dart';

enum SearchIconState {
  normal,
  loading,
  clear,
}

enum SearchPrefixState {
  normal,
  notFound,
  found,
}

class UserClientSearchProvider extends ChangeNotifier {
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));
  final TextEditingController searchController = TextEditingController();

  List<UserClient> _users = [];
  bool _isLoading = false;
  bool _showResults = false;
  String? _errorMessage;
  UserClient? _selectedUser;

  // Getters
  List<UserClient> get users => _users;
  bool get isLoading => _isLoading;
  bool get showResults => _showResults;
  String? get errorMessage => _errorMessage;
  UserClient? get selectedUser => _selectedUser;

  SearchIconState get iconState {
    if (_isLoading) return SearchIconState.loading;
    // Mostrar X si hay texto o usuario seleccionado
    if (searchController.text.isNotEmpty || _selectedUser != null) {
      return SearchIconState.clear;
    }
    return SearchIconState.normal;
  }

  SearchPrefixState get prefixState {
    // Usuario seleccionado = verde
    if (_selectedUser != null) {
      return SearchPrefixState.found;
    }
    // Búsqueda sin resultados (no loading, tiene texto, lista vacía, no hay error)
    if (!_isLoading && searchController.text.length >= 2 && _users.isEmpty && !_showResults) {
      return SearchPrefixState.notFound;
    }
    // Mostró resultados vacíos
    if (!_isLoading && _showResults && _users.isEmpty && _errorMessage == null) {
      return SearchPrefixState.notFound;
    }
    return SearchPrefixState.normal;
  }

  /// Evento 1: Se activa inmediatamente al escribir (pone loading)
  void onTextChanged(String value) {
    if (value.length >= 2) {
      _isLoading = true;
      _showResults = true;
      _errorMessage = null;
      _selectedUser = null;
      notifyListeners();

      // Evento 2: Debouncer que ejecuta la búsqueda real
      _debounce.call(() => _performSearch(value));
    } else {
      _debounce.cancel();
      _isLoading = false;
      _showResults = false;
      _users = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Búsqueda real con el API
  Future<void> _performSearch(String query) async {
    try {
      final users = await UserClientSearchRepository.fetchUsersByName(name: query);
      _users = users;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _users = [];
      _isLoading = false;
      _errorMessage = 'Error al buscar';
      notifyListeners();
    }
  }

  void selectUser(UserClient user) {
    _selectedUser = user;
    searchController.text = user.username ?? '';
    _showResults = false;
    _users = [];
    notifyListeners();
  }

  void clearSearch() {
    _debounce.cancel();
    _selectedUser = null;
    searchController.clear();
    _showResults = false;
    _users = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void hideResults() {
    if (_users.isEmpty) {
      _showResults = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce.cancel();
    searchController.dispose();
    super.dispose();
  }
}
