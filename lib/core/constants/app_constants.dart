/// Application-wide constants
class AppConstants {
  // Application Info
  static const String appName = 'SIAP';
  static const String appFullName = 'Sistem Informasi Administrasi Protokoler';
  static const String appTagline = 'Sistem Administrasi Protokoler Terpadu';
  
  // Pagination
  static const int documentsPerPage = 20;
  static const int historyItemLimit = 10;
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int splashDuration = 3; // seconds
  
  // Security
  static const int maxLoginAttempts = 5;
  static const int accountLockDurationMinutes = 15;
  
  // Cache Expiration
  static const int cacheExpirationHours = 24;
  
  // Storage Keys
  static const String storageAuthToken = 'auth_token';
  static const String storageUserData = 'user_data';
  static const String storageFcmToken = 'fcm_token';
  static const String storageRememberMe = 'remember_me';
  
  // Date Format
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Document Status Messages
  static const Map<int, String> statusMessages = {
    0: 'Ditolak',
    1: 'Diajukan',
    2: 'Diteruskan ke Koordinator',
    3: 'Disetujui',
    8: 'Rapat Koordinator',
    9: 'Diteruskan ke Pimpinan Utama',
    20: 'Dikembalikan',
  };
  
  // Meeting Status Messages
  static const Map<int, String> meetingStatusMessages = {
    0: 'Tidak Ada Rapat',
    1: 'Dijadwalkan Rapat',
  };
}

/// User roles in the system
enum UserRole {
  user('user', 'User', 1),
  deptHead('dept_head', 'Kepala Lembaga/Sekolah/Departemen', 2),
  protocolHead('protocol_head', 'Kepala Protokoler', 3),
  generalHead('general_head', 'Kepala Bagian Umum', 4),
  coordinator('coordinator', 'Koordinator', 5),
  mainLeader('main_leader', 'Pimpinan Utama', 6);

  final String code;
  final String displayName;
  final int level;
  
  const UserRole(this.code, this.displayName, this.level);
  
  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.user,
    );
  }
  
  static UserRole fromLevel(int level) {
    return UserRole.values.firstWhere(
      (role) => role.level == level,
      orElse: () => UserRole.user,
    );
  }
  
  bool get canSubmitDocuments => level <= 4; // user, dept_head, protocol_head, general_head
  bool get canApproveDocuments => level >= 4; // general_head, coordinator, main_leader
  bool get canManageMeetings => this == UserRole.protocolHead || this == UserRole.generalHead;
  bool get canForwardToCoordinator => this == UserRole.generalHead;
  bool get canForwardToMainLeader => this == UserRole.coordinator;
  bool get canReturnDocuments => this == UserRole.generalHead;
}

/// Document status codes
enum DocumentStatus {
  rejected(0, 'Ditolak'),
  pending(1, 'Diajukan'),
  forwardedToCoordinator(2, 'Diteruskan ke Koordinator'),
  approved(3, 'Disetujui'),
  coordinatorMeeting(8, 'Rapat Koordinator'),
  forwardedToMainLeader(9, 'Diteruskan ke Pimpinan Utama'),
  returned(20, 'Dikembalikan');

  final int code;
  final String displayName;
  
  const DocumentStatus(this.code, this.displayName);
  
  static DocumentStatus fromCode(int code) {
    return DocumentStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => DocumentStatus.pending,
    );
  }
  
  bool get isFinal => this == DocumentStatus.approved || this == DocumentStatus.rejected;
  bool get canEdit => this == DocumentStatus.pending || this == DocumentStatus.returned;
}

/// Meeting status codes
enum MeetingStatus {
  noMeeting(0, 'Tidak Ada Rapat'),
  scheduled(1, 'Dijadwalkan Rapat');

  final int code;
  final String displayName;
  
  const MeetingStatus(this.code, this.displayName);
  
  static MeetingStatus fromCode(int code) {
    return MeetingStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => MeetingStatus.noMeeting,
    );
  }
}

/// Navigation tabs
enum NavigationTab {
  home(0, 'Home'),
  data(1, 'Data'),
  history(2, 'History'),
  profile(3, 'Profil');

  final int tabIndex;
  final String label;
  
  const NavigationTab(this.tabIndex, this.label);
}
