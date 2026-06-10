import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import '../../../core/theme/theme.dart';
import '../models/custom_ad_model.dart';
import '../providers/custom_ad_provider.dart';
import '../repositories/custom_ad_repository.dart';

class CustomAdBanner extends ConsumerStatefulWidget {
  const CustomAdBanner({super.key});

  @override
  ConsumerState<CustomAdBanner> createState() => _CustomAdBannerState();
}

class _CustomAdBannerState extends ConsumerState<CustomAdBanner> {
  final Set<String> _recordedImpressions = {};
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(activeAdsProvider);

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
          width: double.infinity,
          height: 120, // Banner height
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final ad = ads[index % ads.length]; // Infinite loop

              // Record impression only once per ad load
              if (!_recordedImpressions.contains(ad.id)) {
                _recordedImpressions.add(ad.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(customAdRepositoryProvider).incrementImpression(ad.id);
                });
              }

              return GestureDetector(
                onTap: () async {
                  // Record click
                  ref.read(customAdRepositoryProvider).incrementClick(ad.id);
                  
                  // Open URL
                  if (ad.targetUrl.isNotEmpty) {
                    try {
                      final uri = Uri.parse(ad.targetUrl);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Could not launch ${ad.targetUrl}: $e');
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: ad.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => _buildFallbackAd(ad),
                        ),
                        // Gradient Overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // Ad Tag
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Ad',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                        // Title & Description
                        Positioned(
                          bottom: 12,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ad.title,
                                style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ad.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  ad.description,
                                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildFallbackAd(CustomAdModel ad) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('Sponsored', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
