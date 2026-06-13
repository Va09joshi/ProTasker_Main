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
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(myJobPostsProvider),
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          child: myPostsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    const Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingLG),
                      child: EmptyState(
                        title: 'No Posts Found',
                        subtitle: 'You haven\'t posted any jobs yet.',
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.paddingMD),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  post.category,
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(post.createdAt),
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: post.status == 'open' 
                                      ? const Color(0xFFD1FAE5) 
                                      : post.status == 'inProgress' 
                                          ? const Color(0xFFFEF3C7) 
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  post.status == 'inProgress' ? 'IN_PROGRESS' : post.status.toUpperCase(),
                                  style: TextStyle(
                                    color: post.status == 'open' 
                                        ? const Color(0xFF059669) 
                                        : post.status == 'inProgress' 
                                            ? const Color(0xFFD97706) 
                                            : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  minimumSize: const Size(0, 0),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  context.push('/job/${post.id}');
                                },
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  child: ErrorView(
                    message: 'Failed to load your posts',
                    onRetry: () => ref.refresh(myJobPostsProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
