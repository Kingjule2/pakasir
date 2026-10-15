import 'package:flutter/material.dart';
import '../../models/security_models.dart';
import '../../services/inventory_store.dart';
import '../../theme/app_colors.dart';

class PrivacyView extends StatelessWidget {
  final InventoryStore store;

  const PrivacyView({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Security Status Banner
          _buildSecurityBanner(context),

          const SizedBox(height: 20),

          // 2. Section: Access Control & Role Permissions (RBAC)
          _buildRolesSection(context),

          const SizedBox(height: 20),

          // 3. Section: Authentication & Privacy Controls
          _buildAuthPrivacyCard(context),

          const SizedBox(height: 20),

          // 4. Section: Security Audit Log Table
          _buildAuditLogCard(context),

          const SizedBox(height: 20),

          // 5. Section: Backup & Compliance UU PDP
          _buildBackupComplianceCard(context),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 22,
                  color: AppColors.statusSuccess,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Privasi, Keamanan & Hak Akses (RBAC)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tingkat Keamanan: Grade A+ • Enkripsi AES-256 Aktif • Kepatuhan UU PDP No. 27/2022',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOnDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cadangan database terenkripsi (vault_backup_2026.enc) berhasil diunduh!'),
                      backgroundColor: AppColors.cardDark,
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download_outlined, size: 15),
                label: const Text('Backup Database Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandLime,
                  foregroundColor: AppColors.cardDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Log audit keamanan 30 hari terakhir berhasil diekspor ke CSV terenkripsi.'),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Colors.white),
                label: const Text('Export Audit Log', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peran Pengguna & Pembagian Wewenang (RBAC)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Batasi akses kasir, manajer cabang, dan staff logistik sesuai peran',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandLimeSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${store.userRoles.length} Peran Dikonfigurasi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cardDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 850
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: store.userRoles.map((role) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildRoleCard(context, role),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, UserRolePermission role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.roleName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${role.memberCount} Pengguna',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: role.permissions.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPrivacyCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan Keamanan Akun & Sesi Login',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Amankan data toko dari akses tidak sah dengan multi-faktor autentikasi',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Otentikasi Dua Faktor (2FA)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Wajibkan kode OTP Authenticator (Google/Microsoft) setiap kali login perangkat baru',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            value: store.twoFactorAuthEnabled,
            activeTrackColor: AppColors.cardDark,
            onChanged: (val) => store.toggleTwoFactorAuth(),
          ),
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Login Biometrik / Face ID Cepat untuk Kasir',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Kasir dapat membuka shift dengan sidik jari pada mesin POS tablet',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            value: store.biometricLoginEnabled,
            activeTrackColor: AppColors.cardDark,
            onChanged: (val) => store.toggleBiometricLogin(),
          ),
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Anonimisasi Data Pelanggan (UU Perlindungan Data Pribadi)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Menyamarkan nomor telepon dan email saat diekspor oleh staff biasa',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            value: store.customerDataAnonymized,
            activeTrackColor: AppColors.cardDark,
            onChanged: (val) => store.toggleCustomerDataAnonymized(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Aktivitas Keamanan Realtime (Audit Logs)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Merekam setiap perubahan harga, restock, void kasir, dan upaya login',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: store.auditLogs.length,
            separatorBuilder: (context, index) => const Divider(height: 14),
            itemBuilder: (context, index) {
              final log = store.auditLogs[index];
              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getLogStatusColor(log.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLogStatusIcon(log.status),
                      size: 16,
                      color: _getLogStatusColor(log.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.action,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Oleh: ${log.user} (${log.role}) • Target: ${log.target} • IP: ${log.ipAddress}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getLogStatusColor(log.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.status,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _getLogStatusColor(log.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log.timestamp,
                        style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackupComplianceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zona Pemeliharaan & Data Protection (UU PDP)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadangan snapshot otomatis tersimpan di cloud region Jakarta dengan enkripsi end-to-end',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache sesi lokal berhasil dibersihkan.')),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services_rounded, size: 14),
                  label: const Text('Bersihkan Cache Lokal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cardDark,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permintaan ekspor data UU PDP telah dikirim.')),
                    );
                  },
                  icon: const Icon(Icons.download_for_offline_rounded, size: 14),
                  label: const Text('Unduh Portabilitas Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cardDark,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getLogStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
        return AppColors.statusSuccess;
      case 'peringatan':
        return AppColors.statusWarning;
      case 'diblokir':
        return AppColors.statusDanger;
      default:
        return AppColors.statusInfo;
    }
  }

  static IconData _getLogStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sukses':
        return Icons.check_circle_outline_rounded;
      case 'peringatan':
        return Icons.warning_amber_rounded;
      case 'diblokir':
        return Icons.block_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
