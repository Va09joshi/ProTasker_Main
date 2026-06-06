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

final searchProvider = FutureProvider.autoDispose.family<List<ServiceModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  final snapshot = await FirebaseFirestore.instance
      .collection('services')
      .where('isActive', isEqualTo: true)
      .where('title', isGreaterThanOrEqualTo: query)
      .where('title', isLessThan: '${query}z')
      .get();
      
  return snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
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
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(right: AppDimensions.paddingLG),
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
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: ServiceCategory.values.map((category) {
              return CategoryChip(
                category: category,
                isSelected: false,
                onTap: () => context.push('/services?category=${category.name}'),
              );
            }).toList(),
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
        
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : AppDimensions.paddingLG,
            vertical: AppDimensions.paddingMD,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppDimensions.paddingMD,
            crossAxisSpacing: AppDimensions.paddingMD,
            childAspectRatio: 0.75,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final service = results[index];
            return ServiceCard(
              service: service,
              onTap: () => context.push('/service/${service.id}'),
            );
          },
        );
      },
      loading: () => const LoadingShimmer(type: ShimmerType.card),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(searchProvider(_query))),
    );
  }
}
