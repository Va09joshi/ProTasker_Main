import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void updateList(List<String> list) => state = list;
}
final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

final searchProvider = FutureProvider.autoDispose.family<List<UserModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  final queryLower = query.toLowerCase().trim();
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'provider')
      .get();
      
  return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).where((user) {
    final nameMatch = user.name.toLowerCase().contains(queryLower);
    final serviceMatch = user.offeredServices?.any((s) => s.toLowerCase().contains(queryLower)) ?? false;
    return nameMatch || serviceMatch;
  }).toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recentSearches') ?? [];
    ref.read(recentSearchesProvider.notifier).updateList(list);
  }

  Future<void> _saveSearch(String term) async {
    final termTrimmed = term.trim();
    if (termTrimmed.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList('recentSearches') ?? [];
    
    list.remove(termTrimmed);
    list.insert(0, termTrimmed);
    if (list.length > 5) list = list.sublist(0, 5);
    
    await prefs.setStringList('recentSearches', list);
    ref.read(recentSearchesProvider.notifier).updateList(list);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value);
      if (value.isNotEmpty) _saveSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recents = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 8,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppDimensions.paddingMD),
          child: AppTextField(
            controller: _controller,
            label: 'Search for services...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isNotEmpty ? IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onSearchChanged('');
              },
            ) : null,
            onChanged: _onSearchChanged,
            // onSubmitted: _saveSearch, // AppTextField doesn't have onSubmitted
          ),
        ),
      ),
      body: SafeArea(
        child: _query.isEmpty ? _buildEmptyState(recents) : _buildResults(),
      ),
    );
  }

  Widget _buildEmptyState(List<String> recents) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
        vertical: AppDimensions.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches', style: AppTextStyles.headingMedium),
                AppButton(
                  label: 'Clear',
                  variant: ButtonVariant.text,
                  fullWidth: false,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('recentSearches');
                    ref.read(recentSearchesProvider.notifier).updateList([]);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recents.map((r) => ActionChip(
                label: Text(r, style: AppTextStyles.labelLarge),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.border, width: AppDimensions.cardBorderWidth),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusPill)),
                onPressed: () {
                  _controller.text = r;
                  _onSearchChanged(r);
                },
              )).toList(),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
          const Text('Browse Categories', style: AppTextStyles.headingLarge),
          const SizedBox(height: AppDimensions.paddingMD),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 0.0,
              runSpacing: 20.0,
              children: ServiceCategory.values.map((category) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - (AppDimensions.paddingLG * 2) - 32) / 3.1,
                  child: _buildCategoryGridItem(category, context),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGridItem(ServiceCategory category, BuildContext context) {
    String label;
    
    switch (category) {
      case ServiceCategory.cleaning: label = 'Cleaning'; break;
      case ServiceCategory.plumbing: label = 'Plumbing'; break;
      case ServiceCategory.electrical: label = 'Electrical'; break;
      case ServiceCategory.painting: label = 'Painting'; break;
      case ServiceCategory.carpentry: label = 'Carpentry'; break;
      case ServiceCategory.appliance: label = 'Appliance'; break;
      case ServiceCategory.shifting: label = 'Moving'; break;
      case ServiceCategory.other: label = 'Handyman'; break;
    }

    return GestureDetector(
      onTap: () {
        context.go('/client/category-providers/${category.name}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/category/${category.name}.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.build_circle_outlined, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
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

  Widget _buildResults() {
    final searchAsync = ref.watch(searchProvider(_query));

    return searchAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                Text('No results for "$_query"', style: AppTextStyles.headingMedium),
                const SizedBox(height: AppDimensions.paddingSM),
                Text('Try searching for something else.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
            vertical: AppDimensions.paddingMD,
          ),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingMD),
          itemBuilder: (context, index) {
            final provider = results[index];
            return Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
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
                  AppAvatar(name: provider.name, imageUrl: provider.profilePhoto, size: 56),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Book',
                    onPressed: () => context.push('/client/book-provider/${provider.uid}'),
                    fullWidth: false,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.card),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(searchProvider(_query))),
    );
  }
}
