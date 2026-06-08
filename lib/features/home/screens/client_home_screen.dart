import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/router/route_names.dart';
import '../providers/home_providers.dart';
import '../../location/screens/map_picker_screen.dart';
import '../../jobs/models/job_post.dart';
import '../widgets/auto_sliding_banner.dart';
import '../../../core/services/location_service.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  bool _hasCheckedLocation = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final popularServicesAsync = ref.watch(popularServicesProvider);
    final bookAgainAsync = ref.watch(bookAgainProvider);
    final myPostsAsync = ref.watch(myJobPostsProvider);
    final nearbyProvidersAsync = ref.watch(nearbyProvidersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pushNamed(RouteNames.postJob),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.post_add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Post',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text('User not found'));
            
            if (!_hasCheckedLocation) {
              _hasCheckedLocation = true;
              if (user.address.lat == 0.0 && user.address.lng == 0.0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fetchDeviceLocation(context, user.uid);
                });
              }
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(popularServicesProvider);
                ref.invalidate(bookAgainProvider);
                ref.invalidate(currentUserProvider);
              },
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 70,
                    collapsedHeight: 70,
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    surfaceTintColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    systemOverlayStyle: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                    ),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, ${user.name.split(' ').first}', 
                          style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        GestureDetector(
                          onTap: () => _showLocationBottomSheet(context, user.uid, user.address.city),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                user.address.city.isNotEmpty ? user.address.city : 'Set your city',
                                style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.paddingLG),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                              ),
                              child: AppAvatar(
                                name: user.name,
                                imageUrl: user.profilePhoto,
                                size: 40,
                                textColor: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                        vertical: AppDimensions.paddingLG,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(context),
                          const SizedBox(height: AppDimensions.paddingXL),
                          const AutoSlidingBanner(),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildPostProblemBanner(context),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildMyPosts(context, ref, myPostsAsync),
                          _buildCategories(context),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildNearbyProviders(context, ref, nearbyProvidersAsync),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildPopularNearYou(context, ref, popularServicesAsync),
                          const SizedBox(height: AppDimensions.paddingXL),
                          _buildBookAgain(ref, bookAgainAsync),
                          const SizedBox(height: AppDimensions.paddingLG),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.profile),
          error: (err, st) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(currentUserProvider)),
        ),
    );
  }

  void _showLocationBottomSheet(BuildContext context, String uid, String currentCity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = TextEditingController(text: currentCity);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppDimensions.paddingLG,
            right: AppDimensions.paddingLG,
            top: AppDimensions.paddingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: AppDimensions.paddingMD),
              const Text('Change City', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppDimensions.paddingMD),
              AppTextField(
                controller: controller,
                label: 'Current City',
                prefixIcon: const Icon(Icons.location_city_outlined),
                enabled: false,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppButton(
                label: 'Choose on Map',
                onPressed: () async {
                  final result = await context.pushNamed<dynamic>(RouteNames.mapPicker);
                  if (result != null && result is MapPickerResult) {
                    final pm = result.placemark;
                    if (pm.locality != null) {
                      FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'address.city': pm.locality,
                        'address.lat': result.latitude,
                        'address.lng': result.longitude,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  }
                },
              ),
              const SizedBox(height: AppDimensions.paddingLG),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: AppDimensions.paddingSM),
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            const SizedBox(width: AppDimensions.paddingMD),
            Text('Search for services...', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostProblemBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.postJob),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Got a problem?',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a post to let locals help!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Text(
                      'Create a Post',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Image.asset(
              'assets/images/list-check.png',
              width: 56,
              height: 56,
              color: AppColors.primary,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.post_add_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = ServiceCategory.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categories', style: AppTextStyles.headingLarge),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppDimensions.paddingMD),
        LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 16.0;
            final double itemWidth = (constraints.maxWidth - 2 * spacing) / 3;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[0], context)),
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[1], context)),
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[2], context)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[3], context)),
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[4], context)),
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[5], context)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[6], context)),
                    const SizedBox(width: spacing),
                    SizedBox(width: itemWidth, child: _buildCategoryGridItem(categories[7], context)),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryGridItem(ServiceCategory category, BuildContext context) {
    String assetPath;
    String label;
    
    switch (category) {
      case ServiceCategory.cleaning:
        assetPath = 'assets/images/cleaning.png';
        label = 'Cleaning';
        break;
      case ServiceCategory.plumbing:
        assetPath = 'assets/images/plumber.png';
        label = 'Plumbing';
        break;
      case ServiceCategory.electrical:
        assetPath = 'assets/images/electrician.png';
        label = 'Electrician';
        break;
      case ServiceCategory.painting:
        assetPath = 'assets/images/painter.png';
        label = 'Painting';
        break;
      case ServiceCategory.carpentry:
        assetPath = 'assets/images/carpentar.png';
        label = 'Carpentry';
        break;
      case ServiceCategory.appliance:
        assetPath = 'assets/images/appliances_home.png';
        label = 'Appliance Repair';
        break;
      case ServiceCategory.shifting:
        assetPath = 'assets/images/moving.png';
        label = 'Moving';
        break;
      case ServiceCategory.other:
        assetPath = 'assets/images/handyman.png';
        label = 'Other';
        break;
    }

    return GestureDetector(
      onTap: () {
        context.push('/client/category-providers/${category.name}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularNearYou(BuildContext context, WidgetRef ref, AsyncValue<List<ServiceModel>> popularServicesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Popular Near You', style: AppTextStyles.headingLarge),
            GestureDetector(
              onTap: () => context.push('/search'),
              child: Text('See All', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppDimensions.paddingMD),
        popularServicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return const EmptyState(
                title: 'No services found',
                subtitle: 'There are no popular services in your area yet. Try searching manually!',
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: services.map((service) {
                  return ServiceCard(
                    service: service,
                    onTap: () {},
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.card),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(popularServicesProvider)),
        ),
      ],
    );
  }

  Widget _buildBookAgain(WidgetRef ref, AsyncValue<List<BookingModel>> bookAgainAsync) {
    return bookAgainAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Again', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.paddingMD),
            Column(
              children: bookings.map((booking) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.padding12),
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: booking.providerName,
                        imageUrl: booking.providerPhoto,
                        size: 48,
                      ),
                      const SizedBox(width: AppDimensions.paddingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.serviceTitle, style: AppTextStyles.labelLarge, maxLines: 1),
                            const SizedBox(height: 2),
                            Text(booking.providerName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Re-book',
                        variant: ButtonVariant.secondary,
                        fullWidth: false,
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.list),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(bookAgainProvider)),
    );
  }

  Widget _buildMyPosts(BuildContext context, WidgetRef ref, AsyncValue<List<JobPost>> myPostsAsync) {
    return myPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Active Posts', style: AppTextStyles.headingLarge),
                GestureDetector(
                  onTap: () => context.push('/my-jobs'), // Assuming this route exists or we can just ignore for now if it doesn't
                  child: Text('Track All', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.paddingMD),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: posts.map((post) {
                  String assetPath = 'assets/images/handyman.png';
                  final catLower = post.category.toLowerCase();
                  if (catLower.contains('clean')) assetPath = 'assets/images/cleaning.png';
                  else if (catLower.contains('plumb')) assetPath = 'assets/images/plumber.png';
                  else if (catLower.contains('electric')) assetPath = 'assets/images/electrician.png';
                  else if (catLower.contains('paint')) assetPath = 'assets/images/painter.png';
                  else if (catLower.contains('carpent')) assetPath = 'assets/images/carpentar.png';
                  else if (catLower.contains('appliance')) assetPath = 'assets/images/appliances_home.png';
                  else if (catLower.contains('shift') || catLower.contains('mov')) assetPath = 'assets/images/moving.png';

                  return GestureDetector(
                    onTap: () => context.push('/job/${post.id}'),
                    child: Container(
                      width: 220,
                      height: 68,
                      margin: const EdgeInsets.only(right: AppDimensions.paddingMD),
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(color: AppColors.border, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                ),
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: post.status == 'open' ? AppColors.success : AppColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppDimensions.paddingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  post.title,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.status == 'open' ? 'Open' : 'In Progress',
                                  style: AppTextStyles.caption.copyWith(
                                    color: post.status == 'open' ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(myJobPostsProvider)),
    );
  }

  Widget _buildNearbyProviders(BuildContext context, WidgetRef ref, AsyncValue<List<UserModel>> nearbyProvidersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available Near You', style: AppTextStyles.headingLarge),
            GestureDetector(
              onTap: () => context.push('/search'),
              child: Text('See All', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppDimensions.paddingMD),
        nearbyProvidersAsync.when(
          data: (providers) {
            if (providers.isEmpty) {
              return const EmptyState(
                title: 'No providers yet',
                subtitle: 'We couldn\'t find any active providers in your city right now.',
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: providers.map((provider) {
                  return GestureDetector(
                    onTap: () => context.push('/provider/${provider.uid}'),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: AppDimensions.paddingMD),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                          side: const BorderSide(color: AppColors.border, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingMD),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                AppAvatar(
                                  imageUrl: provider.profilePhoto,
                                  name: provider.name,
                                  size: 72,
                                ),
                                if (provider.isOnline)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
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
                            const SizedBox(height: AppDimensions.paddingMD),
                            Text(
                              provider.name,
                              style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (provider.offeredServices != null && provider.offeredServices!.isNotEmpty)
                              Text(
                                provider.offeredServices!.first,
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  provider.rating.toStringAsFixed(1),
                                  style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  ' (${provider.totalReviews})',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              ),
            );
          },
          loading: () => const LoadingShimmer(type: ShimmerType.card),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(nearbyProvidersProvider)),
        ),
      ],
    );
  }

  Future<void> _fetchDeviceLocation(BuildContext context, String uid) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppDimensions.paddingLG),
            const Text('Fetching location...'),
          ],
        ),
      ),
    );

    try {
      final pos = await LocationService.getCurrentLocation();
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (pos != null) {
        final pm = await LocationService.getPlacemarkFromCoordinates(pos.latitude, pos.longitude);
        if (pm != null && pm.locality != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'address.city': pm.locality,
            'address.lat': pos.latitude,
            'address.lng': pos.longitude,
          });
            SnackbarHelper.success(context, 'Location updated to ${pm.locality}');
        } else {
          if (mounted) _promptForLocation(context, uid);
        }
      } else {
        if (mounted) _promptForLocation(context, uid);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _promptForLocation(context, uid);
      }
    }
  }

  void _promptForLocation(BuildContext context, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.border,
            width: 1,
          ),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            const Text('Set Your Location', style: AppTextStyles.headingLarge),
          ],
        ),
        content: const Text(
          'Please select your location on the map to find providers near you.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Later',
                  variant: ButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMD),
              Expanded(
                child: AppButton(
                  label: 'Choose on Map',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await context.pushNamed<dynamic>(RouteNames.mapPicker);
                    if (result != null && result is MapPickerResult) {
                      final pm = result.placemark;
                      if (pm.locality != null) {
                        FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'address.city': pm.locality,
                          'address.lat': result.latitude,
                          'address.lng': result.longitude,
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
