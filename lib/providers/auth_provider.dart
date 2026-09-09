import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/branch.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _token;
  String _role = 'cashier'; // default role
  Map<String, dynamic>? _user;
  Map<String, dynamic> _permissions = {};

  List<Branch> _branches = [];
  Branch? _activeBranch;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String get role => _role;
  bool get isOwner => _role == 'owner';
  bool get isCashier => _role == 'cashier';

  List<Branch> get branches => _branches;
  Branch? get activeBranch => _activeBranch;
  int get activeBranchId => _activeBranch?.id ?? 1;
  String get activeBranchName => _activeBranch?.name ?? 'Cabang Ring Road';

  bool can(String feature) {
    if (_permissions.containsKey(feature)) {
      return _permissions[feature][_role] == true ||
          _permissions[feature][_role] == 1;
    }
    return false;
  }

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    final storedBranchId = prefs.getInt('active_branch_id');
    final storedBranchName = prefs.getString('active_branch_name');
    if (storedBranchId != null && storedBranchName != null) {
      _activeBranch = Branch(id: storedBranchId, name: storedBranchName);
    }

    if (_token != null) {
      _apiService.setToken(_token!);
      await fetchUser();
    } else {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    developer.log('Attempting login for: $email');
    try {
      final response = await _apiService.login(email, password);
      if (response != null && response['access_token'] != null) {
        developer.log('Login success, parsing user data...');
        _token = response['access_token'];
        _user = response['user'];
        _role = response['user']?['role'] ?? 'cashier';
        developer.log('Set role to: $_role');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        _apiService.setToken(_token!);

        // Parse branches
        if (response['branches'] != null && response['branches'] is List) {
          final list = response['branches'] as List;
          _branches = list.map((item) => Branch.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          _branches = await _apiService.getBranches();
        }

        // If user has only 1 branch, select it automatically
        if (_branches.length == 1) {
          await setActiveBranch(_branches.first, notify: false);
        } else if (_branches.isNotEmpty && _activeBranch != null) {
          // Check if previously active branch is still in branches list
          final found = _branches.where((b) => b.id == _activeBranch!.id).firstOrNull;
          if (found != null) {
            await setActiveBranch(found, notify: false);
          } else {
            _activeBranch = null;
          }
        } else {
          _activeBranch = null;
        }

        _isAuthenticated = true;

        developer.log('Fetching permissions...');
        await fetchPermissions();
        developer.log('Ready! Notifying listeners.');
        notifyListeners();
        return true;
      } else {
        developer.log('Login response was null or missing token.');
      }
    } catch (e) {
      developer.log('Login Exception: $e');
    }
    return false;
  }

  Future<void> setActiveBranch(Branch branch, {bool notify = true}) async {
    _activeBranch = branch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_branch_id', branch.id);
    await prefs.setString('active_branch_name', branch.name);
    await CacheService.invalidateAll();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> switchBranch(Branch branch) async {
    await setActiveBranch(branch, notify: true);
  }

  Future<void> fetchUser() async {
    try {
      _user = await _apiService.getUser();
      if (_user != null) {
        _isAuthenticated = true;
        _role = _user?['role'] ?? 'cashier';

        // Update branches
        if (_user?['branches'] != null && _user!['branches'] is List) {
          final list = _user!['branches'] as List;
          _branches = list.map((item) => Branch.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          _branches = await _apiService.getBranches();
        }

        final prefs = await SharedPreferences.getInstance();
        final storedBranchId = prefs.getInt('active_branch_id');
        if (storedBranchId != null && _branches.isNotEmpty) {
          _activeBranch = _branches.firstWhere(
            (b) => b.id == storedBranchId,
            orElse: () => _branches.first,
          );
        } else if (_branches.isNotEmpty) {
          await setActiveBranch(_branches.first, notify: false);
        }

        await fetchPermissions();
      } else {
        await logout();
      }
      notifyListeners();
    } catch (e) {
      developer.log('Fetch user error: $e');
      await logout();
    }
  }

  Future<void> fetchPermissions() async {
    try {
      final perms = await _apiService.getPermissions();
      if (perms != null) {
        _permissions = perms;
      }
    } catch (e) {
      developer.log('Fetch permissions error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      developer.log('Logout error: $e');
    }
    _token = null;
    _user = null;
    _permissions = {};
    _branches = [];
    _activeBranch = null;
    _isAuthenticated = false;
    _apiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('active_branch_id');
    await prefs.remove('active_branch_name');
    await CacheService.invalidateAll();

    notifyListeners();
  }
}
