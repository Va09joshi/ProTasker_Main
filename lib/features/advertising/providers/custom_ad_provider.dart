import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_ad_model.dart';
import '../repositories/custom_ad_repository.dart';

final activeAdsProvider = StreamProvider.autoDispose<List<CustomAdModel>>((ref) {
  final repo = ref.watch(customAdRepositoryProvider);
  return repo.getActiveAds();
});

final allAdsAdminProvider = StreamProvider.autoDispose<List<CustomAdModel>>((ref) {
  final repo = ref.watch(customAdRepositoryProvider);
  return repo.getAllAds();
});
