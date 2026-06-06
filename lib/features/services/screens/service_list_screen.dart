import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/service_filter_provider.dart';
import '../providers/service_list_provider.dart';

class ServiceListScreen extends ConsumerStatefulWidget {
  final ServiceCategory? category;

  const ServiceListScreen({super.key, this.category});

  @override
  ConsumerState<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends ConsumerState<ServiceListScreen> {

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG))),
      builder: (ctx) => _FilterBottomSheet(category: widget.category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(paginatedServicesProvider(widget.category));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.category != null ? widget.category!.name.toUpperCase() : 'All Services'),
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No Services Found',
              subtitle: 'Try adjusting your filters or search criteria to find what you\'re looking for.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG, vertical: AppDimensions.paddingMD),
                child: Row(
                  children: [
                    Text('Showing ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    Text('${services.length} result(s)', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.paddingLG,
                      crossAxisSpacing: AppDimensions.paddingLG,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: services.length + (servicesAsync.isLoading ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= services.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final service = services[index];
                      return ServiceCard(
                        service: service,
                        onTap: () => context.push('/service/${service.id}'),
                      );
                    },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingShimmer(type: ShimmerType.list),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(paginatedServicesProvider(widget.category))),
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final ServiceCategory? category;
  const _FilterBottomSheet({required this.category});

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  late ServiceSort _sort;

  @override
  void initState() {
    super.initState();
    final state = ref.read(serviceFilterProvider);
    _minPrice = state.minPrice;
    _maxPrice = state.maxPrice;
    _minRating = state.minRating;
    _sort = state.sort;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppDimensions.paddingLG,
        right: AppDimensions.paddingLG,
        top: AppDimensions.paddingSM,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: AppDimensions.paddingMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: AppTextStyles.displayMedium),
              TextButton(
                onPressed: () {
                  ref.read(serviceFilterProvider.notifier).reset();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Reset', style: AppTextStyles.labelLarge),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          
          Text('Price Range', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${_minPrice.toInt()}', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
              Text('\$${_maxPrice.toInt()}', style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: (vals) => setState(() {
              _minPrice = vals.start;
              _maxPrice = vals.end;
            }),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minimum Rating', style: AppTextStyles.labelLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('${_minRating.toStringAsFixed(1)}+', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 5,
            activeColor: AppColors.warning,
            inactiveColor: AppColors.border,
            onChanged: (val) => setState(() => _minRating = val),
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          
          const Text('Sort By', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.paddingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceSort>(
                value: _sort,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                items: const [
                  DropdownMenuItem(value: ServiceSort.topRated, child: Text('Top Rated')),
                  DropdownMenuItem(value: ServiceSort.priceLowToHigh, child: Text('Price: Low to High')),
                  DropdownMenuItem(value: ServiceSort.priceHighToLow, child: Text('Price: High to Low')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sort = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          
          AppButton(
            label: 'Apply Filters',
            onPressed: () {
              final notifier = ref.read(serviceFilterProvider.notifier);
              notifier.setPriceRange(_minPrice, _maxPrice);
              notifier.setMinRating(_minRating);
              notifier.setSort(_sort);
              ref.invalidate(paginatedServicesProvider(widget.category));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }
}
