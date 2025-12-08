import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';

/// Controller for bottom navigation
class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  /// Change tab
  void changeTab(int index) {
    if (index >= 0 && index < 4) {
      currentIndex.value = index;
    }
  }

  /// Navigate to Home tab
  void goToHome() => changeTab(NavigationTab.home.tabIndex);

  /// Navigate to Data tab
  void goToData() => changeTab(NavigationTab.data.tabIndex);

  /// Navigate to History tab
  void goToHistory() => changeTab(NavigationTab.history.tabIndex);

  /// Navigate to Profile tab
  void goToProfile() => changeTab(NavigationTab.profile.tabIndex);
}
