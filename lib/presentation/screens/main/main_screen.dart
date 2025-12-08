import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import 'tabs/home_tab.dart';
import 'tabs/data_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/profile_tab.dart';

/// Main screen with bottom navigation
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationController = Get.put(NavigationController());

    final tabs = [
      const HomeTab(),
      const DataTab(),
      const HistoryTab(),
      const ProfileTab(),
    ];

    return Obx(
      () => Scaffold(
        body: tabs[navigationController.currentIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationController.currentIndex.value,
          onTap: navigationController.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Data',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
