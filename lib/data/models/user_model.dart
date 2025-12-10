import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// User model representing user data from tbl_user
class UserModel extends Equatable {
  final int id;
  final String username;
  final String namaLengkap;
  final String jabatan;
  final String instansi;
  final int? departemenId;
  final String? email;
  final String? alamat;
  final String? telp;
  final String? pengalaman;
  final UserRole role;
  final int status;
  final DateTime? tglDaftar;
  final DateTime? terakhirLogin;
  final String? token;
  final String? fcmToken;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.jabatan,
    required this.instansi,
    this.departemenId,
    this.email,
    this.alamat,
    this.telp,
    this.pengalaman,
    required this.role,
    required this.status,
    this.tglDaftar,
    this.terakhirLogin,
    this.token,
    this.fcmToken,
    this.avatarUrl,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is String) {
        final parsed = int.tryParse(v.trim());
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    String _asString(dynamic v, {String fallback = ''}) {
      if (v is String) return v;
      if (v != null) return v.toString();
      return fallback;
    }

    return UserModel(
      id: _asInt(json['id'] ?? json['id_user'] ?? 0),
      username: _asString(json['username']),
      namaLengkap: _asString(json['nama_lengkap']),
      jabatan: _asString(json['jabatan']),
      instansi: _asString(json['instansi']),
      departemenId:
          json['departemen_id'] != null ? _asInt(json['departemen_id']) : null,
      email: json['email']?.toString(),
      alamat: json['alamat']?.toString(),
      telp: json['telp']?.toString(),
      pengalaman: json['pengalaman']?.toString(),
      role: json['role'] != null
          ? UserRole.fromCode(json['role'].toString())
          : UserRole.user,
      status: _asInt(json['status'] ?? 1, fallback: 1),
      tglDaftar: json['tgl_daftar'] != null
          ? DateTime.tryParse(json['tgl_daftar'])
          : null,
      terakhirLogin: json['terakhir_login'] != null
          ? DateTime.tryParse(json['terakhir_login'])
          : null,
      token: json['token'],
      fcmToken: json['fcm_token'],
      avatarUrl: json['avatar_url'],
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama_lengkap': namaLengkap,
      'jabatan': jabatan,
      'instansi': instansi,
      'departemen_id': departemenId,
      'email': email,
      'alamat': alamat,
      'telp': telp,
      'pengalaman': pengalaman,
      'role': role.code,
      'status': status,
      'tgl_daftar': tglDaftar?.toIso8601String(),
      'terakhir_login': terakhirLogin?.toIso8601String(),
      'token': token,
      'fcm_token': fcmToken,
      'avatar_url': avatarUrl,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? namaLengkap,
    String? jabatan,
    String? instansi,
    int? departemenId,
    String? email,
    String? alamat,
    String? telp,
    String? pengalaman,
    UserRole? role,
    int? status,
    DateTime? tglDaftar,
    DateTime? terakhirLogin,
    String? token,
    String? fcmToken,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      jabatan: jabatan ?? this.jabatan,
      instansi: instansi ?? this.instansi,
      departemenId: departemenId ?? this.departemenId,
      email: email ?? this.email,
      alamat: alamat ?? this.alamat,
      telp: telp ?? this.telp,
      pengalaman: pengalaman ?? this.pengalaman,
      role: role ?? this.role,
      status: status ?? this.status,
      tglDaftar: tglDaftar ?? this.tglDaftar,
      terakhirLogin: terakhirLogin ?? this.terakhirLogin,
      token: token ?? this.token,
      fcmToken: fcmToken ?? this.fcmToken,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  bool get isActive => status == 1;

  String get initials {
    final names = namaLengkap.split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0].substring(0, 1).toUpperCase();
    return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        username,
        namaLengkap,
        jabatan,
        instansi,
        departemenId,
        email,
        alamat,
        telp,
        pengalaman,
        role,
        status,
        tglDaftar,
        terakhirLogin,
        token,
        fcmToken,
        avatarUrl,
      ];
}
