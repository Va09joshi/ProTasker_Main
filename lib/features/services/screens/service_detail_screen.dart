import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/service_detail_provider.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return Scaffold(
              appBar: AppBar(backgroundColor: AppColors.background),
              body: const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Service Not Found',
                subtitle: 'The service you are looking for might have been removed or is unavailable.',
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, service),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTitleAndPrice(service),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildProviderCard(context, ref, service),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildDescription(service),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildReviews(context, ref, service),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildSimilarServices(context, ref, service),
                          const SizedBox(height: 100), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildStickyBottomBar(context, service),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: LoadingShimmer(type: ShimmerType.profile)),
        error: (e, _) => Scaffold(body: ErrorView(message: e.toString(), onRetry: () => ref.refresh(serviceDetailProvider(serviceId)))),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ServiceModel service) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          itemCount: service.images.isNotEmpty ? service.images.length : 1,
          itemBuilder: (context, index) {
            if (service.images.isEmpty) {
              return Container(color: AppColors.surfaceAlt, child: const Icon(Icons.image_outlined, size: 64, color: AppColors.textTertiary));
            }
            return CachedNetworkImage(
              imageUrl: service.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppColors.surfaceAlt, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(color: AppColors.surfaceAlt, child: const Icon(Icons.broken_image_outlined, color: AppColors.textTertiary)),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildTitleAndPrice(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Text(
                service.category.name.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(service.rating.toStringAsFixed(1), style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning)),
                  Text(' (${service.totalReviews})', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingLG),
        Text(service.title, style: AppTextStyles.displayLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${service.basePrice.toStringAsFixed(2)}', style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('/ starting price', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderCard(BuildContext context, WidgetRef ref, ServiceModel service) {
    final providerAsync = ref.watch(providerProfileProvider(service.providerId));

    return InkWell(
      onTap: () {
        // stub: context.push('/provider/${service.providerId}');
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            AppAvatar(
              name: service.providerName,
              imageUrl: service.providerPhoto,
              size: 56,
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(service.providerName, style: AppTextStyles.headingLarge),
                      const SizedBox(width: 4),
                      providerAsync.when(
                        data: (user) => user?.isVerified == true
                            ? const Icon(Icons.verified_rounded, color: AppColors.info, size: 18)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  providerAsync.when(
                    data: (user) => Text(
                      '${user?.totalJobs ?? 0} jobs completed',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    loading: () => const SizedBox(height: 10, width: 80, child: LinearProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('About this service', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        Text(service.description, style: AppTextStyles.bodyLarge.copyWith(height: 1.6, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildReviews(BuildContext context, WidgetRef ref, ServiceModel service) {
    final reviewsAsync = ref.watch(serviceReviewsProvider(service.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: AppTextStyles.headingLarge),
            if (service.totalReviews > 5)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: const Text('See All', style: AppTextStyles.labelLarge),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMD),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLG), border: Border.all(color: AppColors.border)),
                child: const Text('No reviews yet.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return Column(
              children: reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
                child: ReviewCard(review: r),
              )).toList(),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.list),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(serviceReviewsProvider(service.id))),
        ),
      ],
    );
  }

  Widget _buildSimilarServices(BuildContext context, WidgetRef ref, ServiceModel service) {
    final similarAsync = ref.watch(similarServicesProvider(service));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Similar Services', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        similarAsync.when(
          data: (services) {
            if (services.isEmpty) return const Text('No similar services found.', style: TextStyle(color: AppColors.textSecondary));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: services.map((s) => Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
                  child: SizedBox(
                    width: 200,
                    child: ServiceCard(
                      service: s,
                      onTap: () => context.push('/service/${s.id}'),
                    ),
                  ),
                )).toList(),
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.list),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(similarServicesProvider(service))),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          label: 'Book Now',
          onPressed: () {
            // context.push('/booking-flow/${service.id}');
          },
        ),
      ),
    );
  }
}
