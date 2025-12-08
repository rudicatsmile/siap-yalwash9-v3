import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Meeting list screen showing documents scheduled for meetings
class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  final _isLoading = false.obs;
  final _meetingDocuments = <DocumentModel>[].obs;

  @override
  void initState() {
    super.initState();
    _loadMeetingDocuments();
  }

  Future<void> _loadMeetingDocuments() async {
    _isLoading.value = true;
    try {
      // TODO: Call document repository to get meeting documents
      // Filter: (status = 1 OR status = 8) AND status_rapat = 1
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Sample data - replace with actual API call
      _meetingDocuments.value = [];
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data rapat: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshMeetingDocuments() async {
    await _loadMeetingDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Rapat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMeetingDocuments,
          ),
        ],
      ),
      body: Obx(
        () {
          if (_isLoading.value && _meetingDocuments.isEmpty) {
            return const LoadingWidget(message: 'Memuat daftar rapat...');
          }

          if (_meetingDocuments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event_busy,
              title: 'Tidak Ada Rapat',
              message: 'Belum ada dokumen yang dijadwalkan untuk rapat',
              actionLabel: 'Muat Ulang',
              onActionPressed: _refreshMeetingDocuments,
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshMeetingDocuments,
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _meetingDocuments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = _meetingDocuments[index];
                return _buildMeetingCard(document);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(DocumentModel document) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToMeetingDetail(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      document.documentNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildStatusBadge(document),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                document.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Submitter and department info
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      document.userName ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (document.departemenName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        document.departemenName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Meeting indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.statusMeeting.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: AppTheme.statusMeeting,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Rapat Dijadwalkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.statusMeeting,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DocumentModel document) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getStatusColor(document.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getStatusColor(document.status),
        ),
      ),
      child: Text(
        document.status.displayName,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.getStatusColor(document.status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToMeetingDetail(DocumentModel document) {
    Get.toNamed('/meetings/detail', arguments: document);
  }
}
