import 'dart:async';
import 'dart:convert';

import 'package:dromos/utils/api.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dromos/utils/colors.dart';

/// Data class for a selected place.
class PlaceResult {
  final String name;
  final String address;
  final double lat;
  final double lng;

  PlaceResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  @override
  String toString() => '$name ($address)';
}

/// Suggestion model
class _PlaceSuggestion {
  final String mapboxId;
  final String mainText;
  final String placeFormatted;
  final String featureType;
  final String country;
  final String region;
  final String district;
  final String maki;
  final double? lat;
  final double? lng;

  _PlaceSuggestion({
    required this.mapboxId,
    required this.mainText,
    required this.placeFormatted,
    required this.featureType,
    required this.country,
    required this.region,
    required this.district,
    required this.maki,
    this.lat,
    this.lng,
  });
}

// /// Search Page
class PlaceSearchPage extends StatefulWidget {
  final String hintText;

  const PlaceSearchPage({super.key, this.hintText = 'Search for a place...'});

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final _searchController = TextEditingController();
  final _debounce = Duration(milliseconds: 350);
  Timer? _debounceTimer;
  int locCount = 0;

  List<_PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  String _contextNameFromList(List<dynamic> contextList, String typePrefix) {
    final match = contextList.cast<Map<String, dynamic>?>().firstWhere((entry) {
      final id = (entry?['id'] ?? '').toString();
      return id.startsWith('$typePrefix.');
    }, orElse: () => null);
    return (match?['text'] ?? '').toString();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounceTimer = Timer(_debounce, () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final url = Uri.parse(
        '${Api.url}/mapbox/search-location?q=$query',
      );
      final response = await http.get(url);
      final body = jsonDecode(response.body);
      debugPrint(body.toString());
      if (response.statusCode == 200) {
        final results = body is List ? body : [];

        setState(() {
          locCount = results.length;
          _suggestions = results.map((result) {
            final item = result as Map<String, dynamic>;
            final contextRaw = item['context'];

            final contextList = contextRaw is List
                ? contextRaw.cast<dynamic>()
                : const <dynamic>[];

            final country = _contextNameFromList(contextList, 'country');
            final region = _contextNameFromList(contextList, 'region');
            final district = _contextNameFromList(contextList, 'district');

            final placeTypeRaw = item['place_type'];
            final featureType =
                (item['feature_type'] ??
                        (placeTypeRaw is List && placeTypeRaw.isNotEmpty
                            ? placeTypeRaw.first
                            : null) ??
                        'location')
                    .toString();

            final properties =
                (item['properties'] as Map<String, dynamic>?) ?? {};
            final center = item['center'];
            final geometry = (item['geometry'] as Map<String, dynamic>?) ?? {};
            final coordinates = geometry['coordinates'];

            final lat = center is List && center.length >= 2
                ? _toDouble(center[1])
                : coordinates is List && coordinates.length >= 2
                ? _toDouble(coordinates[1])
                : null;

            final lng = center is List && center.length >= 2
                ? _toDouble(center[0])
                : coordinates is List && coordinates.length >= 2
                ? _toDouble(coordinates[0])
                : null;

            return _PlaceSuggestion(
              mapboxId:
                  (item['mapbox_id'] ??
                          properties['mapbox_id'] ??
                          item['id'] ??
                          '')
                      .toString(),
              mainText:
                  (item['name'] ?? item['text'] ?? item['place_name'] ?? '')
                      .toString(),
              placeFormatted:
                  (item['place_formatted'] ??
                          item['full_address'] ??
                          item['place_name'] ??
                          '')
                      .toString(),
              featureType: featureType,
              country: country.trim(),
              region: region.trim(),
              district: district.trim(),
              maki: (item['maki'] ?? '').toString(),
              lat: lat,
              lng: lng,
            );
          }).toList();

          if (_suggestions.isEmpty) {
            _error = 'No results found';
          }
        });
      } else {
        setState(() {
          _error = body is Map
              ? (body['message'] ??
                    body['details']?['status'] ??
                    'Unknown error')
              : 'Unknown error';
        });
        debugPrint(body.toString());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onSuggestionTapped(_PlaceSuggestion suggestion) async {
    if (suggestion.lat == null || suggestion.lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates not available')),
      );
      return;
    }

    final address = suggestion.placeFormatted.isNotEmpty
        ? suggestion.placeFormatted
        : [
            suggestion.mainText,
            suggestion.district,
            suggestion.region,
          ].where((e) => e.isNotEmpty).join(', ');

    if (!mounted) return;
    Navigator.pop(
      context,
      PlaceResult(
        name: suggestion.mainText,
        address: address,
        lat: suggestion.lat!,
        lng: suggestion.lng!,
      ),
    );
  }

  IconData _iconForFeatureType(String featureType) {
    switch (featureType.toLowerCase()) {
      case 'country':
        return Icons.public;
      case 'region':
        return Icons.map_outlined;
      case 'district':
      case 'locality':
      case 'neighborhood':
        return Icons.location_city_outlined;
      case 'poi':
      case 'place':
        return Icons.place_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Widget _buildSuggestionCard(_PlaceSuggestion suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onSuggestionTapped(suggestion),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: ConstColor.primaryPurple.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff7a6eff), ConstColor.primaryPurple],
                      ),
                    ),
                    child: Icon(
                      _iconForFeatureType(suggestion.featureType),
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.mainText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xff181a25),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.placeFormatted.isNotEmpty
                              ? suggestion.placeFormatted
                              : 'Details unavailable',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      appBar: AppBar(
        backgroundColor: ConstColor.primaryPurple,
        foregroundColor: Colors.white,
        title: const Text('Search Location'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: ConstColor.primaryPurple,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: ConstFonts.semibold(color: Colors.white, size: 14),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: ConstFonts.semibold(color: Colors.white.withAlpha(150), size: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withAlpha(30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_suggestions.isNotEmpty)
            Text(
              'Found $locCount result(s)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

          if (_isLoading)
            const LinearProgressIndicator(
              color: ConstColor.primaryPurple,
              backgroundColor: Colors.transparent,
            ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: ConstColor.error),
              ),
            ),

          Expanded(
            child: _suggestions.isEmpty && !_isLoading
                // ? MapSample()
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_searching,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Type at least 3 characters to search',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return _buildSuggestionCard(s);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
