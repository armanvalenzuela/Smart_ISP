// user_role.dart
enum UserRole {
  admin,      // Full access, all towns
  manager,    // Can oversee multiple towns
  collector,  // Only assigned town
  viewer,     // Read-only access
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.collector:
        return 'Collector';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  bool canEditClients() {
    return this == UserRole.admin || 
           this == UserRole.manager || 
           this == UserRole.collector;
  }

  bool canViewAllTowns() {
    return this == UserRole.admin || this == UserRole.manager;
  }

  bool canProcessPayments() {
    return this == UserRole.admin || 
           this == UserRole.manager || 
           this == UserRole.collector;
  }

  bool canManageUsers() {
    return this == UserRole.admin;
  }

  bool canDeleteClients() {
    return this == UserRole.admin;
  }

  static UserRole fromString(String? roleString) {
    if (roleString == null) return UserRole.collector;
    
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'collector':
        return UserRole.collector;
      case 'viewer':
        return UserRole.viewer;
      default:
        return UserRole.collector;
    }
  }
}

