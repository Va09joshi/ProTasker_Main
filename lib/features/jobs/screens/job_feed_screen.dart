import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/job_provider.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../../shared/models/models.dart';
import '../models/job_post.dart';

class JobFeedScreen extends ConsumerWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Available Jobs', style: AppTextStyles.headingLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => ref.refresh(jobFeedProvider),
            child: Text(
              'Refresh',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSM),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No open jobs',
              subtitle: 'There are no available jobs right now. Check back later!',
            ));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingMD),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _JobFeedCard(job: job);
            },
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(jobFeedProvider)),
      ),
    );
  }
}

class _JobFeedCard extends ConsumerWidget {
  final JobPost job;

  const _JobFeedCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distanceAsync = ref.watch(jobDistanceProvider(job));
    final clientAsync = ref.watch(jobClientProvider(job.clientId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Text(
                    job.category,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(job.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              job.title,
              style: AppTextStyles.headingMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              job.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            clientAsync.when(
              data: (client) {
                if (client == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    AppAvatar(
                      name: client.name,
                      imageUrl: client.profilePhoto,
                      size: 24,
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Text(
                      client.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            const Divider(),
            const SizedBox(height: AppDimensions.paddingSM),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.locationDot, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: AppDimensions.paddingSM),
                distanceAsync.when(
                  data: (distance) {
                    if (distance == null) return const Text('Location unavailable');
                    return Text(
                      '${distance.toStringAsFixed(1)} km away',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('Error'),
                ),
                const Spacer(),
                AppButton(
                  label: 'Chat',
                  variant: ButtonVariant.text,
                  fullWidth: false,
                  onPressed: () async {
                    final user = currentUserAsync.value;
                    if (user == null) return;
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final chatRepo = ref.read(chatRepositoryProvider);
                      final chatId = await chatRepo.getOrCreateChat(
                        job.clientId,
                        user.uid,
                        job.id,
                      );
                      
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) context.push('/chat/$chatId');
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to start chat')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: AppDimensions.paddingSM),
                AppButton(
                  label: 'Details',
                  variant: ButtonVariant.secondary,
                  fullWidth: false,
                  onPressed: () {
                    context.push('/job/${job.id}');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
