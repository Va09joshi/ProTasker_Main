import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/providers/home_providers.dart';

class ClientJobsScreen extends ConsumerWidget {
  const ClientJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPostsAsync = ref.watch(myJobPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Job Posts', style: AppTextStyles.headingMedium),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: myPostsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingLG),
                  child: EmptyState(
                    title: 'No Posts Found',
                    subtitle: 'You haven\'t posted any jobs yet.',
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(myJobPostsProvider),
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.paddingMD),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      side: BorderSide(color: AppColors.border, width: 1),
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
                                  post.category,
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                                ),
                              ),
                              Text(
                                DateFormat.yMMMd().format(post.createdAt),
                                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingSM),
                          Text(
                            post.title,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingSM),
                          Text(
                            post.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppDimensions.paddingMD),
                          const Divider(),
                          const SizedBox(height: AppDimensions.paddingSM),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: post.status == 'open' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text(
                                  post.status.toUpperCase(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: post.status == 'open' ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              AppButton(
                                label: 'Details',
                                variant: ButtonVariant.secondary,
                                fullWidth: false,
                                onPressed: () {
                                  context.push('/job/${post.id}');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.list),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: ErrorView(
              message: 'Failed to load your posts',
              onRetry: () => ref.refresh(myJobPostsProvider),
            ),
          ),
        ),
      ),
    );
  }
}
