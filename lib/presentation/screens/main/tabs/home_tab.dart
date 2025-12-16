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
                                user.jabatan,
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

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _gridStats.length,
                  itemBuilder: (context, index) {
                    final stat = _gridStats[index];
                    final bg = _cardColors[index % _cardColors.length];
                    final onBg = Colors.white;
                    return Card(
                      color: bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Get.to(() => DataTab(qParam: stat.qParam));
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
  Color(0xFFFFF3E0),
  Color(0xFFE8F5E9),
  Color(0xFFFCE4EC),
  Color(0xFFEDE7F6),
  Color(0xFFE0F7FA),
  Color(0xFFFFEBEE),
];

const List<_HomeStat> _gridStats = <_HomeStat>[
  _HomeStat(12, 'Buat Berkas', '1'),
  _HomeStat(7, 'Berkas Masuk', '2'),
  _HomeStat(3, 'Berkas naik', '3'),
  _HomeStat(5, 'Agenda Rapat', '4'),
  _HomeStat(9, 'Arsip Digital', '5'),
  _HomeStat(4, 'Laporan', '6'),
  _HomeStat(6, 'Menunggu', '7'),
  _HomeStat(2, 'Diteruskan', '8'),
  _HomeStat(1, 'Dikembalikan', '9'),
];
