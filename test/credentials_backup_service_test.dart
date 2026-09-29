import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arcadia/shared/services/app_settings_service.dart';
import 'package:arcadia/shared/services/credentials_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CredentialsBackupService.resetTestMemory();
  });

  group('Credentials & API Tokens Multi-Layer Auto-Backup Tests', () {
    test('CredentialsBackupService saves and retrieves GitHub token and API keys', () async {
      // 1. Initial state is empty
      expect(await CredentialsBackupService.getCredential(CredentialsBackupService.keyGitHubToken), isNull);
      expect(await AppSettingsService.getGitHubToken(), isNull);

      // 2. Save GitHub token
      const sampleToken = 'ghp_SampleTestToken1234567890abcdefgh';
      final saved = await AppSettingsService.setGitHubToken(sampleToken);
      expect(saved, isTrue);

      // 3. Retrieve GitHub token
      expect(await AppSettingsService.getGitHubToken(), sampleToken);
      expect(await CredentialsBackupService.getCredential(CredentialsBackupService.keyGitHubToken), sampleToken);

      // 4. Save Gemini Primary & Secondary API keys
      await AppSettingsService.setGeminiPrimaryApiKey('AIzaSy_Primary_38_Key');
      await AppSettingsService.setGeminiSecondaryApiKey('AIzaSy_Secondary_37_Key');

      expect(await AppSettingsService.getGeminiPrimaryApiKey(), 'AIzaSy_Primary_38_Key');
      expect(await AppSettingsService.getGeminiSecondaryApiKey(), 'AIzaSy_Secondary_37_Key');
      expect(await AppSettingsService.hasAnyGeminiApiKey(), isTrue);

      // 5. Update website links
      await AppSettingsService.updateWebsiteLinks(
        websiteUrl: 'https://ckmendo.github.io/Arcadia/',
        tinyUrl: 'https://tinyurl.com/arcadia2027',
      );
      expect(await AppSettingsService.getWebsiteUrl(), 'https://ckmendo.github.io/Arcadia/');
      expect(await AppSettingsService.getTinyUrl(), 'https://tinyurl.com/arcadia2027');
    });

    test('Self-Healing: SharedPreferences wipe restores missing credentials', () async {
      // 1. Save token and keys
      const sampleToken = 'ghp_PermanentProtectedToken';
      await AppSettingsService.setGitHubToken(sampleToken);
      await AppSettingsService.setGeminiPrimaryApiKey('AIzaSy_GeminiKey');

      expect(await AppSettingsService.getGitHubToken(), sampleToken);
      expect(await AppSettingsService.getGeminiPrimaryApiKey(), 'AIzaSy_GeminiKey');

      // 2. Simulate SharedPreferences wipe (e.g. app update / reinstall)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      expect(prefs.getString(CredentialsBackupService.keyGitHubToken), isNull);

      // 3. ensureCredentialsPreserved restores everything from backup
      final restoredCount = await AppSettingsService.ensureCredentialsPreserved();
      expect(restoredCount, greaterThanOrEqualTo(1));

      // 4. Verification that tokens and keys are restored
      expect(await AppSettingsService.getGitHubToken(), sampleToken);
      expect(await AppSettingsService.getGeminiPrimaryApiKey(), 'AIzaSy_GeminiKey');
    });

    test('Safety: Removing one key preserves all other tokens and URLs', () async {
      const sampleToken = 'ghp_MyTokenToKeep';
      await AppSettingsService.setGitHubToken(sampleToken);
      await AppSettingsService.setGeminiPrimaryApiKey('AIzaSy_KeyToKeep');
      await AppSettingsService.setGeminiSecondaryApiKey('AIzaSy_KeyToRemove');

      // Remove secondary key only
      await AppSettingsService.setGeminiSecondaryApiKey(null);

      // Verify secondary is gone but primary and github token remain intact
      expect(await AppSettingsService.getGeminiSecondaryApiKey(), isNull);
      expect(await AppSettingsService.getGeminiPrimaryApiKey(), 'AIzaSy_KeyToKeep');
      expect(await AppSettingsService.getGitHubToken(), sampleToken);
    });
  });
}
