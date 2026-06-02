import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/supabase_service.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuItem> _items = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<MenuItem> get items => _items;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final cats = _items.map((item) => item.category).toSet().toList();
    return ['All', ...cats.cast<String>()];
  }

  String get searchQuery => _searchQuery;

  List<MenuItem> get filteredItems {
    var list = _selectedCategory == 'All'
        ? _items
        : _items.where((item) => item.category == _selectedCategory).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((item) =>
              item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseService.client
          .from(SupabaseService.tableMenuItems)
          .select()
          .eq('available', true)
          .order('category');

      _items = (response as List)
          .map((json) => MenuItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching menu: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  MenuItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
