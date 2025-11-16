// role_service.dart
import '../models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleService {
  static const String _roleKey = 'userRole';
  static const String _userRoleNameKey = 'userRoleName';
  
  /// Get user role from SharedPreferences
  static Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_roleKey);
    return UserRoleExtension.fromString(roleString);
  }

  /// Save user role to SharedPreferences
  static Future<void> setUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name.toLowerCase());
    await prefs.setString(_userRoleNameKey, role.name);
  }

  /// Check if user has permission to edit clients
  static Future<bool> canEditClients() async {
    final role = await getUserRole();
    return role.canEditClients();
  }

  /// Check if user can view all towns
  static Future<bool> canViewAllTowns() async {
    final role = await getUserRole();
    return role.canViewAllTowns();
  }

  /// Check if user can process payments
  static Future<bool> canProcessPayments() async {
    final role = await getUserRole();
    return role.canProcessPayments();
  }

  /// Check if user can manage other users
  static Future<bool> canManageUsers() async {
    final role = await getUserRole();
    return role.canManageUsers();
  }

  /// Check if user can delete clients
  static Future<bool> canDeleteClients() async {
    final role = await getUserRole();
    return role.canDeleteClients();
  }

  /// Get role display name
  static Future<String> getRoleName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleNameKey) ?? 'Collector';
  }
}

