import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dromos/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final String placeId;
  final String mainText;
  final String secondaryText;

  _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
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

  List<_PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  String get _apiKey => dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
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

    final url = Uri.parse('${Api.url}/map/searchByAddressName?address=$query');

    try {
      final response = await http.get(url);
      late dynamic body;
      body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final results = body['results'] as List;
        if (results.isNotEmpty) {
          final firstResult = results[0] as Map<String, dynamic>;
          final fmt = firstResult['address_components'] as List? ?? [];
          setState(() {
        _suggestions = [
          _PlaceSuggestion(
            placeId: firstResult['place_id'] ?? '',
            mainText: firstResult['formatted_address'] ?? '',
            secondaryText: '',
          ),
        ];
          });
        } else {
          setState(() => _error = 'No results found');
        }
      } else {
        setState(() => _error = body['details']['status'] ?? 'Unknown error');
        log(body['details']['status']);
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSuggestionTapped(_PlaceSuggestion suggestion) async {
    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${suggestion.placeId}'
      '&fields=geometry,name,formatted_address'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'OK') {
          final result = body['result'] as Map<String, dynamic>;
          final loc = result['geometry']['location'];
          final place = PlaceResult(
            name: result['name'] ?? suggestion.mainText,
            address: result['formatted_address'] ?? suggestion.secondaryText,
            lat: (loc['lat'] as num).toDouble(),
            lng: (loc['lng'] as num).toDouble(),
          );
          if (mounted) Navigator.of(context).pop(place);
          return;
        }
      }
      setState(() => _error = 'Could not get place details');
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.white.withAlpha(150)),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 56),
                    itemBuilder: (context, index) {
                      final s = _suggestions[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ConstColor.primaryPurple.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: ConstColor.primaryPurple,
                          ),
                        ),
                        title: Text(
                          s.mainText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          s.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () => _onSuggestionTapped(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
