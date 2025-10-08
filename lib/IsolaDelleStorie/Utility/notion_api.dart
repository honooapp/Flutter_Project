import 'dart:convert';
import 'dart:developer' as developer;

import 'package:honoo/IsolaDelleStorie/Entities/api_exercise.dart';
import 'package:http/http.dart' as http;

class NotionApi {
  final String baseUrl = 'api.notion.com';
  final String token;
  final String databaseId;

  static NotionApi? instance;

  factory NotionApi(String token, String databaseId) {
    instance ??= NotionApi._internal(token, databaseId);
    return instance!;
  }

  NotionApi._internal(this.token, this.databaseId);

  Future<Map<String, dynamic>> getDatabase() async {
    developer.log('----------LOG-----------', name: 'NotionApi');
    developer.log('URI: ${baseUrl}databases/$databaseId/query', name: 'NotionApi');
    developer.log('Authorization: Bearer $token', name: 'NotionApi');
    final response = await http.post(
      Uri.https(baseUrl, '/v1/databases/$databaseId/query'),
      headers: {
        'Authorization': 'Bearer $token',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load database');
    }
  }

  List<APIExercise> getAllExercises() {
    // Ensure that the instance is initialized before using it
    if (instance == null) {
      throw Exception(
          "NotionApi has not been initialized. Call the 'initialize' method first.");
    }

    return [];
  }
}
