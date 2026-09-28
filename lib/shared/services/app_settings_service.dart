import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyWebsiteUrl = 'website_url';
  static const String _keyTinyUrl = 'tiny_url';

  static const String defaultWebsiteUrl =
      'https://ckmendo.github.io/Arcadia/';
  static const String defaultTinyUrl = 'https://tinyurl.com/arcadia2027';

  static const String _keyGeminiSecondaryApiKey = 'gemini_secondary_api_key';

  /// Compile-time fallback key passed via --dart-define=GEMINI_API_KEY=...
  static const String _compileTimeGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Retrieves the Primary Gemini API key (for Gemini 3.8 Flash).
  static Future<String?> getGeminiApiKey() async {
    return getGeminiPrimaryApiKey();
  }

  /// Retrieves the Primary Gemini API key.
  static Future<String?> getGeminiPrimaryApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyGeminiApiKey)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading SharedPreferences for Gemini primary key: $e');
    }
    if (_compileTimeGeminiKey.isNotEmpty) {
      return _compileTimeGeminiKey;
    }
    return null;
  }

  /// Retrieves the Secondary Gemini API key (for Gemini 3.7 Flash fallback).
  static Future<String?> getGeminiSecondaryApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyGeminiSecondaryApiKey)?.trim();
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      debugPrint('Error reading SharedPreferences for Gemini secondary key: $e');
    }
    return null;
  }

  /// Checks if either Primary or Secondary Gemini API key is configured.
  static Future<bool> hasAnyGeminiApiKey() async {
    final primary = await getGeminiPrimaryApiKey();
    if (primary != null && primary.isNotEmpty) return true;
    final secondary = await getGeminiSecondaryApiKey();
    return secondary != null && secondary.isNotEmpty;
  }

  /// Saves the Primary Gemini API key.
  static Future<void> setGeminiApiKey(String? key) async {
    return setGeminiPrimaryApiKey(key);
  }

  /// Saves the Primary Gemini API key. Passing null or empty removes it.
  static Future<void> setGeminiPrimaryApiKey(String? key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == null || key.trim().isEmpty) {
        await prefs.remove(_keyGeminiApiKey);
      } else {
        await prefs.setString(_keyGeminiApiKey, key.trim());
      }
    } catch (e) {
      debugPrint('Error saving Gemini primary API key to SharedPreferences: $e');
    }
  }

  /// Saves the Secondary Gemini API key. Passing null or empty removes it.
  static Future<void> setGeminiSecondaryApiKey(String? key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key == null || key.trim().isEmpty) {
        await prefs.remove(_keyGeminiSecondaryApiKey);
      } else {
        await prefs.setString(_keyGeminiSecondaryApiKey, key.trim());
      }
    } catch (e) {
      debugPrint('Error saving Gemini secondary API key to SharedPreferences: $e');
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

  /// Sets the custom TinyURL.
  static Future<void> setTinyUrl(String tinyUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tinyUrl.trim().isEmpty) {
        await prefs.remove(_keyTinyUrl);
      } else {
        await prefs.setString(_keyTinyUrl, tinyUrl.trim());
      }
    } catch (e) {
      debugPrint('Error saving custom TinyURL: $e');
    }
  }

  /// Sets both website URL and an optional custom TinyURL.
  static Future<void> updateWebsiteLinks({
    required String websiteUrl,
    String? tinyUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanWeb = websiteUrl.trim().isEmpty ? defaultWebsiteUrl : websiteUrl.trim();
      await prefs.setString(_keyWebsiteUrl, cleanWeb);

      if (tinyUrl != null && tinyUrl.trim().isNotEmpty) {
        await prefs.setString(_keyTinyUrl, tinyUrl.trim());
      } else {
        final autoTiny = await shortenWithTinyUrl(cleanWeb);
        await prefs.setString(_keyTinyUrl, autoTiny);
      }
    } catch (e) {
      debugPrint('Error updating website links: $e');
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

  /// Tests a Gemini API key by making a lightweight ping to a specified model
  /// (defaulting to Gemini 3.8 Flash, or specified model such as Gemini 3.7 Flash).
  static Future<bool> validateGeminiApiKey(
    String apiKey, {
    String model = 'gemini-3.8-flash',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) return false;

    final modelsToTry = [
      model,
      if (model != 'gemini-3.7-flash') 'gemini-3.7-flash',
      'gemini-3.6-flash',
    ];
    for (final m in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent?key=$trimmedKey',
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

        if (response.statusCode == 200) {
          return true;
        }
        // A 503 or 429 indicates Google Cloud authenticated the API key and project,
        // but the specific model cluster is momentarily saturated.
        if (response.statusCode == 503 || response.statusCode == 429) {
          return true;
        }
      } catch (e) {
        debugPrint('Gemini key validation attempt on $m failed: $e');
      }
    }
    return false;
  }
}
