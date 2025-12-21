import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../controllers/auth_controller.dart';
import 'data_tab.dart';

/// Home tab with profile card and information slider
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Obx(
        () {
          final user = authController.currentUser.value;
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.namaLengkap,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${user.jabatan} • ${user.role.displayName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                              Text(
                                user.instansiName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Information Slider Placeholder
                Text(
                  'Informasi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 150,
                  child: PageView(
                    children: [
                      _buildInfoCard('Selamat Datang di SIAP',
                          'Sistem Informasi Administrasi Protokoler'),
                      _buildInfoCard(
                          'Info', 'Kelola dokumen administrasi dengan mudah'),
                      _buildInfoCard('Panduan', 'Ikuti alur pengajuan dokumen'),
                    ],
                  ),
                ),

                Builder(
                  builder: (context) {
                    final visibleStats = _gridStats.where((s) {
                      final code = user.role.code;
                      switch (s.qParam) {
                        case '1':
                          return code == 'dept_head' ||
                              code == 'general_head' ||
                              code == 'super_admin';
                        case '2':
                          return code == 'user' ||
                              code == 'coordinator' ||
                              code == 'main_leader' ||
                              code == 'super_admin';
                        case '3':
                          return code == 'general_head' ||
                              code == 'coordinator' ||
                              code == 'main_leader' ||
                              code == 'super_admin';
                        case '4':
                        case '5':
                        case '6':
                          return code == 'general_head' ||
                              code == 'super_admin';
                        case '7':
                        case '8':
                        case '9':
                          return code == 'main_leader' ||
                              code == 'coordinator' ||
                              code == 'super_admin';
                        case '10':
                          return code == 'dept_head' || code == 'super_admin';
                        case '11':
                          return code == 'user' || code == 'super_admin';
                        case '12':
                          return code == 'dept_head' || code == 'super_admin';
                        case '13':
                          return code == 'user' || code == 'super_admin';
                        case '14':
                          return code == 'dept_head' || code == 'super_admin';
                        case '15':
                          return code == 'user' || code == 'super_admin';
                        case '16':
                          return code == 'dept_head' || code == 'super_admin';
                        case '17':
                          return code == 'user' || code == 'super_admin';
                        case '18':
                          return code == 'dept_head' || code == 'super_admin';
                        case '19':
                          return code == 'user' || code == 'super_admin';
                        case '20':
                          return code == 'dept_head' ||
                              code == 'user' ||
                              code == 'super_admin';
                        default:
                          return true;
                      }
                    }).toList();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 1.0,
                        crossAxisSpacing: 1.0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: visibleStats.length,
                      itemBuilder: (context, index) {
                        final stat = visibleStats[index];
                        final bg = _cardColors[index % _cardColors.length];
                        final onBg = Colors.black;
                        return Card(
                          color: bg,
                          margin: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Get.to(() => DataTab(
                                  qParam: stat.qParam, title: stat.label));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${stat.value}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      stat.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: onBg),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Card(
      color: AppTheme.primaryLightColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStat {
  final int value;
  final String label;
  final String qParam;

  const _HomeStat(this.value, this.label, this.qParam);
}

const List<Color> _cardColors = <Color>[
  AppTheme.primaryLightColor,
  AppTheme.secondaryLightColor,
  Color(0xFFE3F2FD),
  Color(0x000FF3E0),
  Color(0xFFE8F5E9),
  Color(0xFFFCE4EC),
  Color(0xFFEDE7F6),
  Color(0xFFE0F7FA),
  Color(0xFFFFEBEE),
];

const List<_HomeStat> _gridStats = <_HomeStat>[
  _HomeStat(1, 'Buat Berkas', '1'), //dept_head, dept_head,general_head
  _HomeStat(2, 'Buat Berkas', '2'), //user, coordinator

  _HomeStat(4, 'Berkas Masuk', '4'), //general_head
  _HomeStat(5, 'Berkas naik', '5'), //general_head
  _HomeStat(6, 'Agenda Rapat', '6'), //general_head

  _HomeStat(7, 'Berkas Masuk', '7'), //coordinator
  _HomeStat(8, 'Pengajuan Rapat', '8'), //coordinator
  _HomeStat(9, 'Agenda Rapat', '9'), //coordinator
  _HomeStat(3, 'Arsip Digital', '3'), //general_head, coordinator

  _HomeStat(10, 'Berkas naik', '10'), //dept_head, dept_head
  _HomeStat(11, 'Berkas naik', '11'), //user

  _HomeStat(12, 'Pengajuan Rapat', '12'), //dept_head, dept_head
  _HomeStat(13, 'Pengajuan Rapat', '13'), //user

  _HomeStat(16, 'Koreksi Berkas', '16'), //dept_head, dept_head
  _HomeStat(17, 'Koreksi Berkas', '17'), //user

  _HomeStat(18, 'Di tolak', '18'), //dept_head, dept_head
  _HomeStat(19, 'Di tolak', '19'), //user

  _HomeStat(20, 'Informasi', '20'), //dept_head, dept_head
  _HomeStat(20, 'Informasi', '20'), //user

  _HomeStat(14, 'Arsip Digital', '14'), //dept_head, dept_head
  _HomeStat(15, 'Arsip Digital', '15'), //user
];
