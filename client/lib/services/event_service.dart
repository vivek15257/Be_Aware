import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Event {
  final String id;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> mediaUrls;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.mediaUrls,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'],
      category: json['category'],
      description: json['description'],
      latitude: json['location']['coordinates'][1],
      longitude: json['location']['coordinates'][0],
      mediaUrls: List<String>.from(json['media'].map((m) => m['fileId'])),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class EventService extends ChangeNotifier {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';

  Future<List<Event>> getEvents(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events?lat=$lat&lng=$lng'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<void> createEvent({
    required String category,
    required String description,
    required List<File> mediaFiles,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/events'),
    );

    request.fields['category'] = category;
    request.fields['description'] = description;

    // Add media files
    for (var file in mediaFiles) {
      request.files.add(
        await http.MultipartFile.fromPath('media', file.path),
      );
    }

    final response = await request.send();
    
    if (response.statusCode != 201) {
      throw Exception('Failed to create event');
    }

    notifyListeners();
  }
} 