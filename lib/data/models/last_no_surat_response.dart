import 'package:equatable/equatable.dart';

class LastNoSuratResponse extends Equatable {
  final int status;
  final String timestamp;
  final String lastNoSurat;
  final String nextNoSurat;

  const LastNoSuratResponse({
    required this.status,
    required this.timestamp,
    required this.lastNoSurat,
    required this.nextNoSurat,
  });

  factory LastNoSuratResponse.fromJson(Map<String, dynamic> json) {
    final int status = (json['status'] is int)
        ? json['status'] as int
        : int.tryParse(json['status']?.toString() ?? '') ?? 0;
    final String timestamp = json['timestamp']?.toString() ?? '';
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : {};
    final String last = data['last_no_surat']?.toString() ?? '';
    final String next = data['next_no_surat']?.toString() ?? '';

    return LastNoSuratResponse(
      status: status,
      timestamp: timestamp,
      lastNoSurat: last,
      nextNoSurat: next,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': {
        'last_no_surat': lastNoSurat,
        'next_no_surat': nextNoSurat,
      },
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [status, timestamp, lastNoSurat, nextNoSurat];
}
