import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/profile_providers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PublicProviderProfileScreen extends ConsumerWidget {
  final String providerId;

  const PublicProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(publicProviderProfileProvider(providerId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      body: providerAsync.when(
        data: (provider) {
          if (provider == null) {
            return const Center(child: Text('Provider not found'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
              vertical: AppDimensions.paddingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        AppAvatar(
                          imageUrl: provider.profilePhoto,
                          name: provider.name,
                          size: 80,
                        ),
                        if (provider.isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.background, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppDimensions.paddingLG),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(provider.name, style: AppTextStyles.headingLarge),
                          const SizedBox(height: 4),
                          if (provider.address.city.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(provider.address.city, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                provider.rating.toStringAsFixed(1),
                                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' (${provider.totalReviews} reviews)',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Actions
                currentUserAsync.maybeWhen(
                  data: (user) {
                    if (user != null && user.role == UserRole.client) {
                      return Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Message',
                              variant: ButtonVariant.secondary,
                              icon: Icons.chat_bubble_outline_rounded,
                              onPressed: () async {
                                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                try {
                                  // For a direct chat without a specific job, we can pass an empty serviceId,
                                  // or we might need to rely on the general chat initialization.
                                  // The getOrCreateChat usually expects a serviceId, but we can pass 'direct_message'
                                  final chatId = await ref.read(chatRepositoryProvider).getOrCreateChat(user.uid, provider.uid, 'direct_message');
                                  if (context.mounted) Navigator.pop(context);
                                  if (context.mounted) context.push('/chat/$chatId');
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    SnackbarHelper.error(context, 'Failed to start chat: $e');
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingMD),
                          Expanded(
                            child: AppButton(
                              label: 'Book Now',
                              icon: Icons.calendar_month_rounded,
                              onPressed: () {
                                context.push('/client/book-provider/${provider.uid}');
                              },
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Bio
                if (provider.bio != null && provider.bio!.isNotEmpty) ...[
                  const Text('About', style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Text(provider.bio!, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],

                // Offered Services
                if (provider.offeredServices != null && provider.offeredServices!.isNotEmpty) ...[
                  const Text('Services Offered', style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.offeredServices!.map((service) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Text(service, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent)),
                    )).toList(),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],

                // Portfolio
                if (provider.portfolioImages != null && provider.portfolioImages!.isNotEmpty) ...[
                  const Text('Portfolio', style: AppTextStyles.headingLarge),
                  const SizedBox(height: AppDimensions.paddingMD),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.portfolioImages!.length,
                      itemBuilder: (context, index) {
                        final imageUrl = provider.portfolioImages![index];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(AppDimensions.paddingSM),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
                                    ),
                                    Positioned(
                                      top: 16, right: 16,
                                      child: IconButton(
                                        icon: const Icon(Icons.close_rounded, color: AppColors.background, size: 32),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: AppDimensions.paddingMD),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                ],
                
                // Joined Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Text('Joined ${DateFormat.yMMMM().format(provider.createdAt)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingXL),

                // Reviews Section
                const Divider(color: AppColors.border),
                const SizedBox(height: AppDimensions.paddingLG),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
                    const SizedBox(width: 8),
                    Text('${provider.rating.toStringAsFixed(1)} Rating', style: AppTextStyles.headingLarge),
                    const Spacer(),
                    Text('${provider.totalReviews} reviews', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                Consumer(
                  builder: (context, ref, _) {
                    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));
                    return reviewsAsync.when(
                      data: (reviews) {
                        if (reviews.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingXL),
                            child: Text('No reviews yet. Be the first to leave one!', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
                        );
                      },
                      loading: () => const LoadingShimmer(type: ShimmerType.list),
                      error: (e, _) => ErrorView(message: 'Failed to load reviews', onRetry: () => ref.refresh(providerReviewsProvider(providerId))),
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.profile),
        error: (err, st) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(publicProviderProfileProvider(providerId))),
      ),
    );
  }
}
