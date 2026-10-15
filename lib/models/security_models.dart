class SecurityAuditLog {
  final String id;
  final String timestamp;
  final String user;
  final String role;
  final String action;
  final String target;
  final String ipAddress;
  final String status; // 'Sukses', 'Peringatan', 'Diblokir'

  const SecurityAuditLog({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.role,
    required this.action,
    required this.target,
    required this.ipAddress,
    required this.status,
  });
}

class UserRolePermission {
  final String roleName;
  final String description;
  final int memberCount;
  final List<String> permissions;

  const UserRolePermission({
    required this.roleName,
    required this.description,
    required this.memberCount,
    required this.permissions,
  });
}
