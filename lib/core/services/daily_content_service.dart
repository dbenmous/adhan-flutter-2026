import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentItem {
  final String text;
  final String? translation;
  final String? source;
  final String? surah;
  final String? name; // For Allah Name
  final String? meaning; // For Allah Name

  ContentItem({
    required this.text,
    this.translation,
    this.source,
    this.surah,
    this.name, // e.g. "Ar-Rahman"
    this.meaning, // e.g. "The Merciful"
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      text: json['text'] ?? json['name'] ?? '', // Fallback for name to be main text
      translation: json['translation'],
      source: json['source'],
      surah: json['surah'],
      name: json['name'],
      meaning: json['meaning'],
    );
  }
}

class DailyContent {
  final int dayOfYear;
  final ContentItem ayah;
  final ContentItem hadith;
  final ContentItem dua;
  final ContentItem allahName;

  DailyContent({
    required this.dayOfYear,
    required this.ayah,
    required this.hadith,
    required this.dua,
    required this.allahName,
  });

  factory DailyContent.fromJson(Map<String, dynamic> json) {
    return DailyContent(
      dayOfYear: json['day_of_year'],
      ayah: ContentItem.fromJson(json['ayah']),
      hadith: ContentItem.fromJson(json['hadith']),
      dua: ContentItem.fromJson(json['dua']),
      allahName: ContentItem.fromJson(json['allah_name']),
    );
  }
}

class DailyContentService {
  static final DailyContentService _instance = DailyContentService._internal();
  factory DailyContentService() => _instance;
  DailyContentService._internal();

  List<DailyContent> _allContent = [];
  bool _isLoaded = false;

  Future<void> loadContent() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/json/daily_content.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allContent = jsonList.map((j) => DailyContent.fromJson(j)).toList();
      _isLoaded = true;
    } catch (e) {
      print("Error loading daily content: $e");
    }
  }

  DailyContent? getDailyContent() {
    if (!_isLoaded || _allContent.isEmpty) return null;
    
    // Calculate day of year (1-365)
    final now = DateTime.now();
    final diff = now.difference(DateTime(now.year, 1, 1, 0, 0));
    final dayOfYear = diff.inDays + 1;

    // Find content for this day, or fallback to first item (looping)
    return _allContent.firstWhere(
      (c) => c.dayOfYear == dayOfYear,
      orElse: () => _allContent[(dayOfYear - 1) % _allContent.length],
    );
  }

  // --- Read State Logic ---

  Future<void> markAsRead(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setBool('read_${type}_$today', true);
  }

  Future<bool> isRead(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.getBool('read_${type}_$today') ?? false;
  }
}
