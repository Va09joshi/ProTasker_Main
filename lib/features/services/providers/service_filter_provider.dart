import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/models.dart';

enum ServiceSort { topRated, priceLowToHigh, priceHighToLow }

class ServiceFilterState {
  final ServiceCategory? category;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final ServiceSort sort;

  const ServiceFilterState({
    this.category,
    this.minPrice = 0,
    this.maxPrice = 5000,
    this.minRating = 0,
    this.sort = ServiceSort.topRated,
  });

  ServiceFilterState copyWith({
    ServiceCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    ServiceSort? sort,
  }) {
    return ServiceFilterState(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
    );
  }
}

class ServiceFilterNotifier extends Notifier<ServiceFilterState> {
  @override
  ServiceFilterState build() {
    return const ServiceFilterState();
  }

  void updateFilter(ServiceFilterState newState) {
    state = newState;
  }

  void reset() {
    state = ServiceFilterState(category: state.category);
  }
  
  void setCategory(ServiceCategory? category) {
    state = state.copyWith(category: category);
  }

  void setPriceRange(double min, double max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void setMinRating(double min) {
    state = state.copyWith(minRating: min);
  }

  void setSort(ServiceSort sort) {
    state = state.copyWith(sort: sort);
  }
}

final serviceFilterProvider = NotifierProvider<ServiceFilterNotifier, ServiceFilterState>(ServiceFilterNotifier.new);
