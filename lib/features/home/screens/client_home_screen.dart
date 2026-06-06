import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/user_session_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/router/route_names.dart';
import '../providers/home_providers.dart';
import '../../location/screens/map_picker_screen.dart';
import '../../jobs/models/job_post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final popularServicesAsync = ref.watch(popularServicesProvider);
    final bookAgainAsync = ref.watch(bookAgainProvider);
    final myPostsAsync = ref.watch(myJobPostsProvider);
    final nearbyProvidersAsync = ref.watch(nearbyProvidersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.postJob),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Problem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text('User not found'));
            
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
                        vertical: AppDimensions.paddingLG,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, user),
                          const SizedBox(height: AppDimensions.paddingLG),
                          _buildSearchBar(context),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final firstName = user.name.split(' ').first;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $firstName', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppDimensions.paddingXS),
              GestureDetector(
                onTap: () => _showLocationBottomSheet(context, user.uid, user.address.city),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      user.address.city.isNotEmpty ? user.address.city : 'Set your city',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            AppAvatar(
              name: user.name,
              imageUrl: user.profilePhoto,
              size: 48,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
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
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                    style: AppTextStyles.headingLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a post to let locals help!',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withAlpha(230)),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Text(
                      'Create a Post',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMD),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categories', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppDimensions.paddingMD),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppDimensions.paddingSM,
            mainAxisSpacing: AppDimensions.paddingSM,
            childAspectRatio: 0.8,
          ),
          itemCount: ServiceCategory.values.length,
          itemBuilder: (context, index) {
            final category = ServiceCategory.values[index];
            return _buildCategoryGridItem(category, context);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryGridItem(ServiceCategory category, BuildContext context) {
    var icon = FontAwesomeIcons.ellipsis;
    String label;
    Color color;
    
    switch (category) {
      case ServiceCategory.cleaning:
        icon = FontAwesomeIcons.broom;
        label = 'Cleaning';
        color = const Color(0xFF00B4D8); // Cyan
        break;
      case ServiceCategory.plumbing:
        icon = FontAwesomeIcons.faucetDrip;
        label = 'Plumbing';
        color = const Color(0xFF4361EE); // Blue
        break;
      case ServiceCategory.electrical:
        icon = FontAwesomeIcons.plug;
        label = 'Electrical';
        color = const Color(0xFFF72585); // Pink
        break;
      case ServiceCategory.painting:
        icon = FontAwesomeIcons.paintRoller;
        label = 'Painting';
        color = const Color(0xFFFF9F1C); // Orange
        break;
      case ServiceCategory.carpentry:
        icon = FontAwesomeIcons.hammer;
        label = 'Carpentry';
        color = const Color(0xFF7209B7); // Purple
        break;
      case ServiceCategory.appliance:
        icon = FontAwesomeIcons.blender;
        label = 'Appliance';
        color = const Color(0xFF38B000); // Green
        break;
      case ServiceCategory.shifting:
        icon = FontAwesomeIcons.truckFast;
        label = 'Shifting';
        color = const Color(0xFFF07167); // Coral
        break;
      case ServiceCategory.other:
        icon = FontAwesomeIcons.ellipsis;
        label = 'Other';
        color = const Color(0xFF6C757D); // Grey
        break;
    }

    return GestureDetector(
      onTap: () {
        context.push('/services?category=${category.name}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
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
            const SizedBox(height: AppDimensions.paddingMD),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: posts.map((post) {
                  var iconData = FontAwesomeIcons.ellipsis;
                  final catLower = post.category.toLowerCase();
                  if (catLower.contains('clean')) iconData = FontAwesomeIcons.broom;
                  else if (catLower.contains('plumb')) iconData = FontAwesomeIcons.faucetDrip;
                  else if (catLower.contains('electric')) iconData = FontAwesomeIcons.plug;
                  else if (catLower.contains('paint')) iconData = FontAwesomeIcons.paintRoller;
                  else if (catLower.contains('carpent')) iconData = FontAwesomeIcons.hammer;
                  else if (catLower.contains('appliance')) iconData = FontAwesomeIcons.blender;
                  else if (catLower.contains('shift')) iconData = FontAwesomeIcons.truckFast;

                  return GestureDetector(
                    onTap: () => context.push('/job/${post.id}'),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: AppDimensions.paddingMD),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.border, width: 2),
                                ),
                                child: FaIcon(
                                  iconData,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: post.status == 'open' ? AppColors.success : AppColors.warning,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.background, width: 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.title,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
      loading: () => const LoadingShimmer(type: ShimmerType.card),
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
}
