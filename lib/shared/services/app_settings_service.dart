import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyWebsiteUrl = 'website_url';
  static const String _keyTinyUrl = 'tiny_url';

  static const String defaultWebsiteUrl =
      'https://arcadia-golf-trip.ckm-endo.chatgpt.site';
  static const String defaultTinyUrl = 'https://tinyurl.com/2xnkqbrx';

  /// Compile-time fallback key passed via --dart-define=GEMINI_API_KEY=...
  static const String _compileTimeGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Retrieves the saved Gemini API key, falling back to compile-time env define.
  static Future<String?> getGeminiApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyGeminiApiKey)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading SharedPreferences for Gemini key: $e');
    }
    if (_compileTimeGeminiKey.isNotEmpty) {
      return _compileTimeGeminiKey;
    }
    return null;
  }

  /// Saves the Gemini API key. Passing null or empty removes it.
  static Future<void> setGeminiApiKey(String? key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == null || key.trim().isEmpty) {
        await prefs.remove(_keyGeminiApiKey);
      } else {
        await prefs.setString(_keyGeminiApiKey, key.trim());
      }
    } catch (e) {
      debugPrint('Error saving Gemini API key to SharedPreferences: $e');
    }
  }

  /// Retrieves the public website URL.
  static Future<String> getWebsiteUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyWebsiteUrl)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading website URL: $e');
    }
    return defaultWebsiteUrl;
  }

  /// Sets the public website URL and automatically regenerates the TinyURL shortlink.
  static Future<String> setWebsiteUrl(String url) async {
    final cleanUrl = url.trim().isEmpty ? defaultWebsiteUrl : url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyWebsiteUrl, cleanUrl);
      final tinyUrl = await shortenWithTinyUrl(cleanUrl);
      await prefs.setString(_keyTinyUrl, tinyUrl);
      return tinyUrl;
    } catch (e) {
      debugPrint('Error saving website URL: $e');
      return defaultTinyUrl;
    }
  }

  /// Retrieves the shortened TinyURL.
  static Future<String> getTinyUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyTinyUrl)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading TinyURL: $e');
    }
    return defaultTinyUrl;
  }

  /// Calls the tinyurl.com API to create a short link.
  static Future<String> shortenWithTinyUrl(String longUrl) async {
    if (longUrl == defaultWebsiteUrl) {
      return defaultTinyUrl;
    }
    try {
      final apiUri = Uri.parse(
        'https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(longUrl)}',
      );
      final response = await http.get(apiUri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.body.trim().startsWith('http')) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('TinyURL API request failed: $e');
    }
    return defaultTinyUrl;
  }

  /// Tests a Gemini API key by making a lightweight ping to gemini-2.5-flash.
  static Future<bool> validateGeminiApiKey(String apiKey) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey.trim()}',
      );
      final payload = {
        'contents': [
          {
            'parts': [
              {'text': 'Ping'}
            ]
          }
        ]
      };
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gemini key validation failed: $e');
      return false;
    }
  }
}
