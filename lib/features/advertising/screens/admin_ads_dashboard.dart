import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/custom_ad_model.dart';
import '../providers/custom_ad_provider.dart';
import '../repositories/custom_ad_repository.dart';

class AdminAdsDashboardScreen extends ConsumerWidget {
  const AdminAdsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(allAdsAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ads Management', style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/admin/ads/edit'),
          ),
        ],
      ),
      body: adsAsync.when(
        data: (ads) {
          if (ads.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No Ads Created',
              subtitle: 'Click the + button to create your first ad campaign.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingMD),
            itemBuilder: (context, index) {
              final ad = ads[index];
              return _AdminAdCard(ad: ad);
            },
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, st) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(allAdsAdminProvider)),
      ),
    );
  }
}

class _AdminAdCard extends ConsumerWidget {
  final CustomAdModel ad;

  const _AdminAdCard({required this.ad});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpired = ad.endDate.isBefore(DateTime.now());
    final isPending = ad.startDate.isAfter(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceAlt,
                  child: const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: AppTextStyles.headingMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: ad.isActive,
                      activeColor: AppColors.success,
                      onChanged: (val) {
                        ref.read(customAdRepositoryProvider).updateAd(ad.copyWith(isActive: val));
                      },
                    ),
                  ],
                ),
                Text(ad.description, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppDimensions.paddingMD),
                Row(
                  children: [
                    _buildStatChip(Icons.visibility, '${ad.impressions} Views', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.touch_app, '${ad.clicks} Clicks', AppColors.accent),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                const Divider(),
                const SizedBox(height: AppDimensions.paddingSM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start: ${DateFormat.yMMMd().format(ad.startDate)}', style: AppTextStyles.caption),
                        Text('End: ${DateFormat.yMMMd().format(ad.endDate)}', style: AppTextStyles.caption),
                      ],
                    ),
                    Row(
                      children: [
                        if (isExpired)
                          Text('EXPIRED', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error))
                        else if (isPending)
                          Text('PENDING', style: AppTextStyles.labelLarge.copyWith(color: AppColors.warning))
                        else
                          Text('ACTIVE', style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
                        const SizedBox(width: AppDimensions.paddingSM),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                          onPressed: () => context.push('/admin/ads/edit', extra: ad),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
