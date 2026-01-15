import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/location_service.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final _settingsService = SettingsService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();

  String _currentLocationName = 'Loading...';
  bool _isManual = false;
  bool _isSearching = false;
  List<Location> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final settings = _settingsService.getSettings();
    _isManual = settings.isManualLocation;
    
    if (settings.isManualLocation && settings.manualLocationName != null) {
      setState(() => _currentLocationName = settings.manualLocationName!);
    } else {
      final coords = await _locationService.getCurrentLocation();
      final name = await _locationService.getLocationName(coords);
      if (mounted) setState(() => _currentLocationName = name);
    }
  }

  Future<void> _searchCity(String query) async {
    if (query.length < 3) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      setState(() => _searchResults = locations.take(5).toList());
    } catch (e) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectLocation(Location location) async {
    final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
    final name = placemarks.isNotEmpty
        ? "${placemarks.first.locality ?? ''}, ${placemarks.first.country ?? ''}"
        : "Selected Location";
    
    await _settingsService.setManualLocation(location.latitude, location.longitude, name);
    setState(() {
      _currentLocationName = name;
      _isManual = true;
      _searchResults = [];
      _searchController.clear();
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _useAutoLocation() async {
    setState(() => _currentLocationName = 'Detecting location...');
    
    // First clear manual location flag
    await _settingsService.clearManualLocation();
    
    // Force get fresh GPS location
    final coords = await _locationService.getGpsLocation();
    final name = await _locationService.getLocationName(coords);
    
    // Save the fresh auto location
    await _settingsService.setLocation(coords.latitude, coords.longitude);
    
    setState(() {
      _currentLocationName = name;
      _isManual = false;
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Location', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isManual ? 'Manual Location' : 'Automatic Location',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentLocationName,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (_isManual) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _useAutoLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text('Use Automatic Location', style: GoogleFonts.outfit()),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Search City', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter city name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
              ),
              onChanged: _searchCity,
            ),
            
            const SizedBox(height: 16),
            
            // Search Results
            ...(_searchResults.map((loc) => ListTile(
              leading: const Icon(Icons.place_outlined),
              title: FutureBuilder<List<Placemark>>(
                future: placemarkFromCoordinates(loc.latitude, loc.longitude),
                builder: (context, snap) {
                  if (snap.hasData && snap.data!.isNotEmpty) {
                    final p = snap.data!.first;
                    return Text("${p.locality ?? p.name}, ${p.country}", style: GoogleFonts.outfit());
                  }
                  return Text('${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}', style: GoogleFonts.outfit());
                },
              ),
              onTap: () => _selectLocation(loc),
            ))),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
