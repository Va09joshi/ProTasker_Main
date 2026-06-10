import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../providers/category_providers_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class CategoryProvidersScreen extends ConsumerWidget {
  final String category;

  const CategoryProvidersScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(categoryProvidersProvider(category));
    final userAsync = ref.watch(currentUserProvider);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/client/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/client/home');
              }
            },
          ),
          title: Text('${category.toUpperCase()} PROVIDERS', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      body: SafeArea(
        child: providersAsync.when(
        data: (providers) {
          if (providers.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Providers Found',
              subtitle: 'There are no providers offering this service near you (50km).',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingSM),
                child: Row(
                  children: [
                    Text('Showing ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    Text('${providers.length} provider(s) near you', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  itemCount: providers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.paddingMD),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    double? distanceInKm;
                    if (userAsync.value != null) {
                      final dist = Geolocator.distanceBetween(
                        userAsync.value!.address.lat,
                        userAsync.value!.address.lng,
                        provider.address.lat,
                        provider.address.lng,
                      );
                      distanceInKm = dist / 1000;
                    }

                    return CategoryProviderCard(
                      provider: provider,
                      distanceInKm: distanceInKm,
                      onBook: () => context.push('/client/book-provider/${provider.uid}?category=$category'),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(categoryProvidersProvider(category))),
      ), // Closes providersAsync.when
      ), // Closes SafeArea
      ), // Closes Scaffold
    ); // Closes PopScope
  }
}

class CategoryProviderCard extends StatelessWidget {
  final UserModel provider;
  final double? distanceInKm;
  final VoidCallback onBook;

  const CategoryProviderCard({
    super.key,
    required this.provider,
    this.distanceInKm,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  AppAvatar(
                    name: provider.name,
                    imageUrl: provider.profilePhoto,
                    size: 64,
                  ),
                  if (provider.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(provider.rating.toStringAsFixed(1), style: AppTextStyles.labelLarge),
                        Text(' (${provider.totalReviews})', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        if (distanceInKm != null) ...[
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text('${distanceInKm!.toStringAsFixed(1)} km', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.totalJobs} jobs completed',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          const Divider(),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Profile',
                  variant: ButtonVariant.secondary,
                  onPressed: () {
                    context.push('/provider/${provider.uid}');
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: AppButton(
                  label: 'Book Now',
                  onPressed: onBook,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
