import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceCommunicationService {
  const DeviceCommunicationService();

  static const _channel = MethodChannel('com.arcadia.golf.arcadia/communication');

  Future<void> sendSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final validNumbers = phoneNumbers
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (validNumbers.isEmpty) {
      throw ArgumentError.value(phoneNumbers, 'phoneNumbers', 'Cannot be empty');
    }

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod<void>('sendSms', {
          'phoneNumbers': validNumbers,
          'message': message,
        });
        return;
      }
    } catch (_) {
      // Fallback to url_launcher below
    }

    final separator = Platform.isAndroid ? ';' : ',';
    final recipientList = validNumbers.join(separator);
    final smsUri = Uri(
      scheme: 'sms',
      path: recipientList,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      final smstoUri = Uri.parse('smsto:$recipientList?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smstoUri)) {
        await launchUrl(smstoUri);
      } else {
        throw Exception('Could not launch SMS application.');
      }
    }
  }

  Future<bool> openAiAssistant({
    required String packageName,
    required String fallbackUrl,
  }) async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('openAiAssistant', {
          'packageName': packageName,
          'fallbackUrl': fallbackUrl,
        });
        if (result != null) return result;
      }
    } catch (_) {}

    // Fallback using url_launcher
    final uri = Uri.parse(fallbackUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return false;
    }
    return false;
  }
}
