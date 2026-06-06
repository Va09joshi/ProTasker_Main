import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

class MapPickerResult {
  final double latitude;
  final double longitude;
  final Placemark placemark;

  MapPickerResult({required this.latitude, required this.longitude, required this.placemark});
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  CameraPosition? _initialPosition;
  LatLng? _currentCenter;
  Placemark? _currentPlacemark;
  bool _isMoving = false;
  bool _isLoadingAddress = false;
  
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determineInitialPosition() async {
    if (widget.initialLat != null && widget.initialLat != 0.0 && widget.initialLng != null && widget.initialLng != 0.0) {
      _setInitialPosition(LatLng(widget.initialLat!, widget.initialLng!));
      return;
    }

    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      _setInitialPosition(LatLng(pos.latitude, pos.longitude));
    } else {
      _setInitialPosition(const LatLng(37.7749, -122.4194));
    }
  }

  void _setInitialPosition(LatLng latLng) {
    setState(() {
      _initialPosition = CameraPosition(target: latLng, zoom: 15.0);
      _currentCenter = latLng;
    });
    _fetchAddress(latLng);
  }

  Future<void> _fetchAddress(LatLng latLng) async {
    setState(() => _isLoadingAddress = true);
    final placemark = await LocationService.getPlacemarkFromCoordinates(latLng.latitude, latLng.longitude);
    if (mounted) {
      setState(() {
        _currentPlacemark = placemark;
        _isLoadingAddress = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getSuggestions(query);
    });
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') return;

    final url = 'https://places.googleapis.com/v1/places:autocomplete';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({'input': query}),
      );
      
      debugPrint("Places API (New) Response Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List?;
        setState(() {
          _placeSuggestions = suggestions?.map((s) {
            final prediction = s['placePrediction'];
            return {
              'place_id': prediction['placeId'],
              'description': prediction['text']['text']
            };
          }).toList() ?? [];
        });
      } else {
        debugPrint("Places API Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _placeSuggestions = [];
      _searchController.text = description;
    });

    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final url = 'https://places.googleapis.com/v1/places/$placeId';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'location',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['location'];
        if (location != null) {
          final lat = location['latitude'];
          final lng = location['longitude'];
          
          final controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 16),
          ));
        }
      } else {
        debugPrint("Places details API Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (!_isMoving) setState(() => _isMoving = true);
    _currentCenter = position.target;
  }

  void _onCameraIdle() {
    if (_isMoving) setState(() => _isMoving = false);
    if (_currentCenter != null) {
      _fetchAddress(_currentCenter!);
    }
  }

  void _confirmLocation() {
    if (_currentCenter != null && _currentPlacemark != null) {
      final result = MapPickerResult(
        latitude: _currentCenter!.latitude,
        longitude: _currentCenter!.longitude,
        placemark: _currentPlacemark!,
      );
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Location'),
      ),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition!,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                // Center Pin
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35.0),
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: _isMoving ? AppColors.accent.withAlpha(150) : AppColors.accent,
                    ),
                  ),
                ),
                // Search Bar and Suggestions
                Positioned(
                  top: AppDimensions.paddingMD,
                  left: AppDimensions.paddingMD,
                  right: AppDimensions.paddingMD,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for a place or address...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _placeSuggestions = []);
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      if (_placeSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: AppDimensions.paddingSM),
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _placeSuggestions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final suggestion = _placeSuggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                                title: Text(suggestion['description'], style: AppTextStyles.bodyMedium),
                                onTap: () => _selectPlace(suggestion['place_id'], suggestion['description']),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusLG),
                        topRight: Radius.circular(AppDimensions.radiusLG),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.place, color: AppColors.primary),
                            const SizedBox(width: AppDimensions.paddingMD),
                            Expanded(
                              child: _isLoadingAddress
                                  ? const Text('Loading address...', style: AppTextStyles.bodyMedium)
                                  : Text(
                                      _currentPlacemark != null
                                          ? '${_currentPlacemark!.street ?? ''}, ${_currentPlacemark!.locality ?? ''}'
                                          : 'Searching...',
                                      style: AppTextStyles.headingMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingLG),
                        AppButton(
                          label: 'Confirm Location',
                          onPressed: _isLoadingAddress || _currentPlacemark == null ? null : _confirmLocation,
                        ),
                      ],
                    ),
                  ),
                ),
                // My Location Button
                Positioned(
                  bottom: 140,
                  right: AppDimensions.paddingMD,
                  child: FloatingActionButton(
                    heroTag: 'myLocationBtn',
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                    onPressed: () async {
                      final pos = await LocationService.getCurrentLocation();
                      if (pos != null) {
                        final controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.newCameraPosition(
                          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
                        ));
                      }
                    },
                  ),
                )
              ],
            ),
    );
  }
}
