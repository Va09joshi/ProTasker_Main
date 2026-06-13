import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/service_model.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/providers/home_providers.dart';
import '../../../shared/providers/user_session_provider.dart';

final providerMarkerProvider = FutureProvider.family<BitmapDescriptor, String>((ref, userId) async {
  final providersAsync = ref.watch(nearbyProvidersProvider);
  final providerList = providersAsync.value ?? [];
  UserModel? provider;
  for (var p in providerList) {
    if (p.uid == userId) {
      provider = p;
      break;
    }
  }

  if (provider == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  const double size = 150.0; // High resolution size
  const double center = size / 2;
  const double radius = 55.0; // Inner circle radius
  
  // Draw shadow
  final Paint shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  canvas.drawCircle(const Offset(center, center + 4), radius + 8, shadowPaint);

  // Draw Golden Frame Pointer pointing down
  final Path pointerPath = Path()
    ..moveTo(center - 16, center + radius + 2)
    ..lineTo(center, size - 10) // Point
    ..lineTo(center + 16, center + radius + 2)
    ..close();
    
  canvas.drawPath(pointerPath, shadowPaint);

  final Paint goldenPaint = Paint()
    ..color = const Color(0xFFFFD700) // Golden
    ..style = PaintingStyle.fill;
    
  canvas.drawPath(pointerPath, goldenPaint);
  canvas.drawCircle(const Offset(center, center), radius + 10, goldenPaint);

  // Draw white inner border
  final Paint whitePaint = Paint()..color = Colors.white;
  canvas.drawCircle(const Offset(center, center), radius + 4, whitePaint);

  ui.Image? profileImage;
  if (provider.profilePhoto != null && provider.profilePhoto!.isNotEmpty) {
    try {
      final completer = Completer<ImageInfo>();
      final img = NetworkImage(provider.profilePhoto!);
      img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
          (info, _) => completer.complete(info),
          onError: (e, s) => completer.completeError(e),
        )
      );
      final info = await completer.future.timeout(const Duration(seconds: 5));
      profileImage = info.image;
    } catch (e) {
      debugPrint('Failed to load profile image for marker: $e');
    }
  }

  // Clip the image or text to the inner circle
  final Path clipPath = Path()..addOval(Rect.fromCircle(center: const Offset(center, center), radius: radius));
  canvas.save();
  canvas.clipPath(clipPath);

  if (profileImage != null) {
    final double imgW = profileImage.width.toDouble();
    final double imgH = profileImage.height.toDouble();
    final double minDim = math.min(imgW, imgH);
    final src = Rect.fromLTWH((imgW - minDim)/2, (imgH - minDim)/2, minDim, minDim);
    final dst = Rect.fromCircle(center: const Offset(center, center), radius: radius);
    canvas.drawImageRect(profileImage, src, dst, Paint());
  } else {
    // Draw Initials
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = AppColors.primary);
    TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    String initials = provider.name.isNotEmpty ? provider.name.substring(0, 1).toUpperCase() : '?';
    if (provider.name.contains(' ')) {
      initials = provider.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    }
    textPainter.text = TextSpan(
      text: initials,
      style: const TextStyle(
        fontSize: 48.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center - (textPainter.width / 2), center - (textPainter.height / 2)));
  }
  canvas.restore();

  final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
});

class ClientMapScreen extends ConsumerStatefulWidget {
  const ClientMapScreen({super.key});

  @override
  ConsumerState<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends ConsumerState<ClientMapScreen> {
  GoogleMapController? _mapController;
  String _searchQuery = '';
  ServiceCategory? _selectedCategory;
  
  List<ServiceCategory?> get _categories {
    return [null, ...ServiceCategory.values];
  }

  final List<String> _citySuggestions = [
    'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Ahmedabad', 'Chennai', 
    'Kolkata', 'Surat', 'Pune', 'Jaipur', 'Indore', 'Bhopal', 'Dewas',
    'Ujjain', 'Gwalior', 'Jabalpur', 'Lucknow', 'Kanpur', 'Nagpur',
    'Visakhapatnam', 'Patna', 'Vadodara', 'Ghaziabad', 'Ludhiana', 'Agra',
    'Nashik', 'Faridabad', 'Meerut', 'Rajkot', 'Kalyan', 'Vasai', 'Varanasi',
    'Srinagar', 'Aurangabad', 'Dhanbad', 'Amritsar', 'Navi Mumbai', 'Allahabad',
    'Ranchi', 'Howrah', 'Coimbatore', 'Vijayawada', 'Jodhpur', 'Madurai',
    'Raipur', 'Kota', 'Guwahati', 'Chandigarh', 'Trivandrum', 'Mysore'
  ];

  // Store fuzzed locations to keep them consistent during the session
  final Map<String, LatLng> _fuzzedLocations = {};
  final math.Random _random = math.Random();

  LatLng _getFuzzedLocation(String uid, double lat, double lng) {
    if (_fuzzedLocations.containsKey(uid)) {
      return _fuzzedLocations[uid]!;
    }
    // Fuzz by approx ~100-200 meters (0.001 to 0.002 degrees)
    // This protects exact privacy (house number) while keeping them in the general area.
    double fuzzLat = (0.001 + _random.nextDouble() * 0.001) * (_random.nextBool() ? 1 : -1);
    double fuzzLng = (0.001 + _random.nextDouble() * 0.001) * (_random.nextBool() ? 1 : -1);
    
    final fuzzed = LatLng(lat + fuzzLat, lng + fuzzLng);
    _fuzzedLocations[uid] = fuzzed;
    return fuzzed;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Keep colorful map but hide clutter (shops, POIs, transit) so our markers stand out
    _mapController?.setMapStyle('''
[
  {
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry.fill",
    "stylers": [
      { "color": "#f4f4f4" }
    ]
  },
  {
    "featureType": "landscape.natural",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''');
  }

  Future<void> _performSearch(String val) async {
    if (val.trim().isNotEmpty) {
      try {
        final locations = await locationFromAddress(val.trim());
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final newLatLng = LatLng(loc.latitude, loc.longitude);
          ref.read(mapCenterProvider.notifier).state = newLatLng;
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 12.0));
        }
      } catch (e) {
        debugPrint('Location not found: $e');
      }
    } else {
       ref.read(mapCenterProvider.notifier).state = null;
    }
  }

  void _showProviderDialog(UserModel provider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
          clipBehavior: Clip.antiAlias,
          elevation: 24,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AppAvatar(
                          name: provider.name,
                          imageUrl: provider.profilePhoto,
                          size: 60,
                          isVerified: provider.isVerified,
                        ),
                        const SizedBox(width: AppDimensions.paddingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: AppTextStyles.headingMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.rating.toStringAsFixed(1),
                                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    ' (${provider.totalReviews} reviews)',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.privacy_tip_outlined, size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Approximate location',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.success),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.paddingLG),
                    if (provider.offeredServices != null && provider.offeredServices!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.offeredServices!.take(3).map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                service,
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDDDDDD),
                  foregroundColor: AppColors.textPrimary,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/provider/${provider.uid}');
                },
                child: Text(
                  'View Profile & Connect',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearbyProvidersAsync = ref.watch(nearbyProvidersProvider);
    final userAsync = ref.watch(currentUserProvider);
    final mapCenter = ref.watch(mapCenterProvider);

    LatLng initialTarget = const LatLng(20.5937, 78.9629); // Default center (India)
    if (mapCenter != null) {
      initialTarget = mapCenter;
    } else if (userAsync.value != null && userAsync.value!.address.lat != 0.0) {
      initialTarget = LatLng(userAsync.value!.address.lat, userAsync.value!.address.lng);
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Column(
        children: [
          // Custom "App Bar" / Search Section
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore Providers', style: AppTextStyles.headingLarge.copyWith(color: AppColors.surface, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppDimensions.paddingMD),
                // Search Field
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _citySuggestions.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _searchQuery = selection;
                    });
                    _performSearch(selection);
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                    return Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                        ],
                      ),
                      child: TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (val) {
                          _performSearch(val);
                          onFieldSubmitted();
                        },
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by area or name...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: InkWell(
                              onTap: () => _performSearch(textEditingController.text),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 32,
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: AppColors.textTertiary, size: 20),
                                      const SizedBox(width: 12),
                                      Text(option, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                // Category Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      final label = category == null ? 'All' : category.displayName;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? AppColors.surface : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected ? AppColors.surface : Colors.white.withValues(alpha: 0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Map Area
          Expanded(
            child: nearbyProvidersAsync.when(
              data: (providers) {
                // Filter Logic
                final filteredProviders = providers.where((p) {
                  // Only show online providers on the map
                  if (!p.isOnline) return false;

                  final matchesCategory = _selectedCategory == null ||
                      (p.offeredServices?.any((s) => s.toLowerCase() == _selectedCategory!.name.toLowerCase()) ?? false);
                  
                  final matchesSearch = _searchQuery.isEmpty ||
                      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.address.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.address.street.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.address.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.address.pincode.toLowerCase().contains(_searchQuery.toLowerCase());
                      
                  return matchesCategory && matchesSearch;
                }).toList();

                Set<Marker> markers = {};
                
                for (var provider in filteredProviders) {
                  if (provider.address.lat != 0.0 && provider.address.lng != 0.0) {
                    final markerIconAsync = ref.watch(providerMarkerProvider(provider.uid));
                    final fuzzedLocation = _getFuzzedLocation(provider.uid, provider.address.lat, provider.address.lng);
                    
                    markers.add(
                      Marker(
                        markerId: MarkerId(provider.uid),
                        position: fuzzedLocation,
                        icon: markerIconAsync.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                        onTap: () => _showProviderDialog(provider),
                      ),
                    );
                  }
                }

                return Stack(
                  children: [
                    // Scale map slightly to push the Google logo off-screen
                    ClipRect(
                      child: Transform.scale(
                        scale: 1.15,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: initialTarget,
                            zoom: 12.0,
                          ),
                          onMapCreated: _onMapCreated,
                          markers: markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          buildingsEnabled: false,
                        ),
                      ),
                    ),
                    if (filteredProviders.isEmpty)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingMD),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.warning),
                              const SizedBox(width: AppDimensions.paddingMD),
                              const Expanded(
                                child: Text(
                                  'No providers found matching your filters.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: LoadingShimmer(type: ShimmerType.map)),
              error: (e, _) => Center(child: Text('Failed to load map: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
