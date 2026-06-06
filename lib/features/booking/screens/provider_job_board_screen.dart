import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';

class ProviderJobBoardScreen extends ConsumerStatefulWidget {
  const ProviderJobBoardScreen({super.key});

  @override
  ConsumerState<ProviderJobBoardScreen> createState() => _ProviderJobBoardScreenState();
}

class _ProviderJobBoardScreenState extends ConsumerState<ProviderJobBoardScreen> {
  Future<void> _applyForJob(String jobId) async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      
      await FirebaseFirestore.instance.collection('task_requests').doc(jobId).update({
        'status': TaskRequestStatus.assigned.name,
        'assignedProviderId': user.uid,
        'updatedAt': Timestamp.now(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Job Board'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('task_requests')
            .where('status', isEqualTo: TaskRequestStatus.open.name)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No open jobs available right now.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final job = TaskRequestModel.fromFirestore(docs[index]);
              
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: AppTextStyles.headingMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Open',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingSM),
                      Text(
                        job.description,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Lat: ${job.latitude.toStringAsFixed(2)}, Lng: ${job.longitude.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () => _applyForJob(job.id),
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
