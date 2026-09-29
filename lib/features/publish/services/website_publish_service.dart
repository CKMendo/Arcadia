import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../database/app_database.dart';
import '../../courses/models/scheduled_round.dart';
import '../../courses/repository/course_repository.dart';
import '../../courses/repository/trip_schedule_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../rounds/models/active_round_session.dart';
import '../../rounds/repository/round_repository.dart';
import '../../tournaments/repository/tournament_repository.dart';
import '../../../shared/services/app_settings_service.dart';
import 'package:flutter/foundation.dart';

class PublishResult {
  final bool success;
  final String message;
  final DateTime publishedAt;

  const PublishResult({
    required this.success,
    required this.message,
    required this.publishedAt,
  });
}

class WebsitePublishService {
  static const String publicSiteUrl = 'https://ckmendo.github.io/Arcadia';
  static const String apiEndpoint = '$publicSiteUrl/api/publication';

  /// Publishes the complete, latest tournament state to the public website.
  static Future<PublishResult> publishTournament({
    required TournamentRepository tournamentRepo,
    required CourseRepository courseRepo,
    required PlayerRepository playerRepo,
    required RoundRepository roundRepo,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      final tournament = await tournamentRepo.getActiveTournament();
      final courses = await courseRepo.getAllCourses();
      final players = await playerRepo.getAllPlayers();
      final savedRounds = await roundRepo.getAllSavedRounds();

      final sessions = <ActiveRoundSession>[];
      for (final r in savedRounds) {
        try {
          final map = jsonDecode(r.roundPayloadJson) as Map<String, dynamic>;
          sessions.add(ActiveRoundSession.fromJson(map));
        } catch (_) {}
      }

      final scheduleRepo = TripScheduleRepository();
      final schedule = await scheduleRepo.getSchedule();

      final payload = _buildTournamentPayload(
        tournament: tournament,
        courses: courses,
        players: players,
        sessions: sessions,
        schedule: schedule,
        now: now,
      );

      final encoded = jsonEncode(payload);

      // 1. Direct local file update if accessible (e.g. running on desktop or test)
      bool localUpdated = false;
      try {
        final localFile = File('public_site/tournament_data.json');
        if (await localFile.exists()) {
          await localFile.writeAsString(encoded, flush: true);
          localUpdated = true;
        }
        final docsFile = File('docs/tournament_data.json');
        if (await docsFile.exists()) {
          await docsFile.writeAsString(encoded, flush: true);
          localUpdated = true;
        }
      } catch (_) {}

      // 2. Direct GitHub API update (used on mobile / Android to commit to repo)
      final githubToken = await AppSettingsService.getGitHubToken();
      if (githubToken != null && githubToken.isNotEmpty) {
        final ghResult = await _publishViaGitHubApi(githubToken, encoded);
        if (ghResult.success) {
          return PublishResult(
            success: true,
            message: 'Standings successfully pushed to live website!',
            publishedAt: now,
          );
        } else {
          return PublishResult(
            success: false,
            message: 'GitHub publish error: ${ghResult.message}',
            publishedAt: now,
          );
        }
      }

      // 3. Fallback: custom HTTP server if configured (e.g. local Python server)
      final currentWebUrl = await AppSettingsService.getWebsiteUrl();
      if (!currentWebUrl.contains('github.io')) {
        try {
          final endpoint = '$currentWebUrl/api/publication';
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: encoded,
          ).timeout(const Duration(seconds: 12));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return PublishResult(
              success: true,
              message: 'Standings successfully pushed to live website!',
              publishedAt: now,
            );
          }
        } catch (_) {}
      }

      // If local files were updated (e.g. during desktop dev/testing), consider success
      if (localUpdated && kDebugMode) {
        return PublishResult(
          success: true,
          message: 'Website data updated successfully!',
          publishedAt: now,
        );
      }

      // Needs token to push to GitHub Pages from mobile
      return PublishResult(
        success: false,
        message: 'NEEDS_GITHUB_TOKEN',
        publishedAt: now,
      );
    } catch (e) {
      return PublishResult(
        success: false,
        message: 'Publishing failed: $e',
        publishedAt: now,
      );
    }
  }

  static Future<({bool success, String message})> _publishViaGitHubApi(
    String token,
    String jsonPayload,
  ) async {
    const repo = 'CKMendo/Arcadia';
    const filePath = 'docs/tournament_data.json';
    const branch = 'master';

    try {
      final getUri = Uri.parse('https://api.github.com/repos/$repo/contents/$filePath?ref=$branch');
      final getRes = await http.get(
        getUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'ArcadiaApp',
        },
      ).timeout(const Duration(seconds: 10));

      String? sha;
      if (getRes.statusCode == 200) {
        final getMap = jsonDecode(getRes.body) as Map<String, dynamic>;
        sha = getMap['sha'] as String?;
      }

      final putUri = Uri.parse('https://api.github.com/repos/$repo/contents/$filePath');
      final contentBase64 = base64Encode(utf8.encode(jsonPayload));

      final body = <String, dynamic>{
        'message': 'Update tournament standings and roster [skip ci]',
        'content': contentBase64,
        'branch': branch,
      };
      if (sha != null) {
        body['sha'] = sha;
      }

      final putRes = await http.put(
        putUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
          'User-Agent': 'ArcadiaApp',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        // Also update public_site/tournament_data.json on GitHub for consistency
        try {
          final pubGetUri = Uri.parse('https://api.github.com/repos/$repo/contents/public_site/tournament_data.json?ref=$branch');
          final pubGetRes = await http.get(
            pubGetUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'ArcadiaApp',
            },
          ).timeout(const Duration(seconds: 8));

          String? pubSha;
          if (pubGetRes.statusCode == 200) {
            final pubMap = jsonDecode(pubGetRes.body) as Map<String, dynamic>;
            pubSha = pubMap['sha'] as String?;
          }

          final pubPutUri = Uri.parse('https://api.github.com/repos/$repo/contents/public_site/tournament_data.json');
          final pubBody = <String, dynamic>{
            'message': 'Sync public_site tournament data [skip ci]',
            'content': contentBase64,
            'branch': branch,
          };
          if (pubSha != null) pubBody['sha'] = pubSha;

          await http.put(
            pubPutUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/vnd.github+json',
              'Content-Type': 'application/json',
              'User-Agent': 'ArcadiaApp',
            },
            body: jsonEncode(pubBody),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}

        return (success: true, message: 'Published successfully!');
      } else {
        String errDetail = 'HTTP ${putRes.statusCode}';
        try {
          final errJson = jsonDecode(putRes.body) as Map<String, dynamic>;
          if (errJson['message'] != null) {
            errDetail += ': ${errJson['message']}';
          }
        } catch (_) {}
        return (success: false, message: errDetail);
      }
    } catch (e) {
      return (success: false, message: '$e');
    }
  }

  static Map<String, dynamic> _buildTournamentPayload({
    required Tournament? tournament,
    required List<Course> courses,
    required List<Player> players,
    required List<ActiveRoundSession> sessions,
    required List<ScheduledRound> schedule,
    required DateTime now,
  }) {
    // Calculate player stats
    final playerPoints = <String, int>{};
    final playerRoundScores = <String, List<int>>{};
    final playerGrossTotal = <String, int>{};
    final playerNetTotal = <String, int>{};
    final playerRoundsCount = <String, int>{};
    final playerBirdies = <String, int>{};
    final playerPartnerHist = <String, List<String>>{};

    for (final p in players) {
      playerPoints[p.id] = 0;
      playerRoundScores[p.id] = [];
      playerGrossTotal[p.id] = 0;
      playerNetTotal[p.id] = 0;
      playerRoundsCount[p.id] = 0;
      playerBirdies[p.id] = 0;
      playerPartnerHist[p.id] = [];
    }

    final birdieEvents = <Map<String, dynamic>>[];

    for (var rIdx = 0; rIdx < sessions.length; rIdx++) {
      final s = sessions[rIdx];
      final roundNum = s.roundNumber;

      for (final p in s.players) {
        final pid = p.playerId;
        final pts = s.effectivePlayerStableford(pid);
        final gross = s.totalGross(pid);
        final net = s.totalNet(pid);

        playerPoints[pid] = (playerPoints[pid] ?? 0) + pts;
        playerRoundScores[pid] = [...(playerRoundScores[pid] ?? []), pts];
        playerGrossTotal[pid] = (playerGrossTotal[pid] ?? 0) + gross;
        playerNetTotal[pid] = (playerNetTotal[pid] ?? 0) + net;
        playerRoundsCount[pid] = (playerRoundsCount[pid] ?? 0) + 1;

        // Count birdies
        for (var h = 1; h <= s.holeCount; h++) {
          final gScore = s.getGrossScore(pid, h);
          final par = s.getHole(h).par;
          if (gScore > 0 && gScore < par) {
            playerBirdies[pid] = (playerBirdies[pid] ?? 0) + 1;
            birdieEvents.add({
              'round': roundNum,
              'course': s.courseName,
              'hole': h,
              'golfer': p.name,
              'par': par,
              'score': gScore,
              'time': 'Round $roundNum',
            });
          }
        }
      }
    }

    // Sort standings by points descending
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) {
        final ptsA = playerPoints[a.id] ?? 0;
        final ptsB = playerPoints[b.id] ?? 0;
        return ptsB.compareTo(ptsA);
      });

    final standings = <Map<String, dynamic>>[];
    for (var i = 0; i < sortedPlayers.length; i++) {
      final p = sortedPlayers[i];
      final rCount = playerRoundsCount[p.id] ?? 0;
      final pts = playerPoints[p.id] ?? 0;
      final grossAvg = rCount > 0 ? ((playerGrossTotal[p.id] ?? 0) / rCount) : 0.0;
      final netAvg = rCount > 0 ? ((playerNetTotal[p.id] ?? 0) / rCount) : 0.0;

      String seedLabel;
      if (i < 4) {
        seedLabel = 'Seed #${i + 1} Captain';
      } else {
        seedLabel = 'Draft Pool #${i + 1}';
      }

      final bluffsHcp = (p.handicapIndex * (137.0 / 113.0) + (73.5 - 72.0)).round();
      final southHcp = (p.handicapIndex * (134.0 / 113.0) + (72.8 - 72.0)).round();

      standings.add({
        'rank': i + 1,
        'seed': seedLabel,
        'playerId': p.id,
        'name': p.fullName,
        'nickname': p.nickname,
        'initials': p.initials,
        'handicapIndex': p.handicapIndex,
        'courseHcpBluffs': bluffsHcp,
        'courseHcpSouth': southHcp,
        'phone': p.phoneNumber ?? '',
        'tee': p.preferredTee ?? 'Blue',
        'roundsPlayed': rCount,
        'totalPoints': pts,
        'birdies': playerBirdies[p.id] ?? 0,
        'grossAvg': double.parse(grossAvg.toStringAsFixed(1)),
        'netAvg': double.parse(netAvg.toStringAsFixed(1)),
        'partnerHistory': playerPartnerHist[p.id] ?? [],
        'contributionPct': 50,
        'roundPoints': playerRoundScores[p.id] ?? [],
      });
    }

    // Birdie pots
    final totalBirdieCount = birdieEvents.length;
    final totalTripPot = totalBirdieCount * 8.0; // 8 players contributing

    final coursePots = <Map<String, dynamic>>[];
    for (var rIdx = 0; rIdx < sessions.length; rIdx++) {
      final s = sessions[rIdx];
      final rBirdies = birdieEvents.where((e) => e['round'] == s.roundNumber).toList();
      final roundPot = rBirdies.length * 8.0;

      coursePots.add({
        'id': 'cp_${s.roundNumber}',
        'courseName': s.courseName,
        'roundNumber': s.roundNumber,
        'roundPot': roundPot,
        'birdieCount': rBirdies.length,
        'lastBirdieHole': rBirdies.isNotEmpty ? rBirdies.last['hole'] : null,
        'lastBirdieGolfers': rBirdies.isNotEmpty ? [rBirdies.last['golfer']] : [],
        'isAwarded': true,
        'winnerPayout': roundPot,
      });
    }

    final playerLedger = <Map<String, dynamic>>[];
    for (final p in players) {
      final count = playerBirdies[p.id] ?? 0;
      final dues = totalBirdieCount * 2.0;
      playerLedger.add({
        'playerId': p.id,
        'name': p.fullName,
        'nickname': p.nickname,
        'birdiesMade': count,
        'totalDues': dues,
        'potsWon': 0.0,
        'netBalance': -dues,
      });
    }

    // Pairings
    final pairings = <Map<String, dynamic>>[];
    for (var rIdx = 0; rIdx < sessions.length; rIdx++) {
      final s = sessions[rIdx];
      final pList = s.players.map((p) => p.name).toList();
      pairings.add({
        'roundNumber': s.roundNumber,
        'title': 'Round ${s.roundNumber} — ${s.courseName}',
        'courseName': s.courseName,
        'date': 'Round ${s.roundNumber}',
        'format': '2-Man Best Ball Net Stableford',
        'groups': [
          {
            'groupNumber': 1,
            'teeTime': '9:00 AM',
            'teamA': {
              'name': 'Team 1',
              'players': pList.take(2).toList(),
              'score': s.effectivePlayerStableford(s.players.firstOrNull?.playerId ?? ''),
            },
            'teamB': {
              'name': 'Team 2',
              'players': pList.skip(2).take(2).toList(),
              'score': s.effectivePlayerStableford(s.players.length > 2 ? s.players[2].playerId : ''),
            },
          },
        ],
      });
    }

    final courseList = courses.isNotEmpty
        ? courses.map((c) => {
            'id': c.id,
            'name': c.name,
            'par': 72,
            'rating': 73.5,
            'slope': 137,
            'yardage': 6800,
          }).toList()
        : [
            {
              'id': 'arcadia_bluffs',
              'name': 'Arcadia Bluffs (The Bluffs)',
              'par': 72,
              'rating': 73.5,
              'slope': 137,
              'yardage': 6800,
            },
            {
              'id': 'the_south_course',
              'name': 'The South Course',
              'par': 72,
              'rating': 72.8,
              'slope': 134,
              'yardage': 6750,
            },
          ];

    final rosterList = <Map<String, dynamic>>[];
    for (var i = 0; i < sortedPlayers.length; i++) {
      final p = sortedPlayers[i];
      final bluffsHcp = (p.handicapIndex * (137.0 / 113.0) + (73.5 - 72.0)).round();
      final southHcp = (p.handicapIndex * (134.0 / 113.0) + (72.8 - 72.0)).round();
      final seed = i < 4 ? 'Seed #${i + 1} Captain' : 'Draft Pool #${i + 1}';

      rosterList.add({
        'id': p.id,
        'name': p.fullName,
        'nickname': p.nickname,
        'initials': p.initials,
        'handicapIndex': p.handicapIndex,
        'courseHcpBluffs': bluffsHcp,
        'courseHcpSouth': southHcp,
        'phone': p.phoneNumber ?? '',
        'email': p.email ?? '',
        'ghin': p.ghinNumber ?? '',
        'tee': p.preferredTee ?? 'Blue',
        'seed': seed,
        'rank': i + 1,
        'photo': p.photoPath ?? 'assets/images/user_logo.jpg',
      });
    }

    return {
      'leagueName': 'Arcadia Cup 2027',
      'publishedAt': now.toIso8601String(),
      'isLive': sessions.isNotEmpty,
      'tournament': {
        'id': tournament?.id ?? 'arcadia_2027',
        'name': tournament?.name ?? 'Arcadia Cup 2027',
        'dates': 'June 7 - June 12, 2027',
        'venue': 'Arcadia Bluffs Golf Club',
        'courses': courseList,
        'roster': rosterList,
      },
      'birdiePots': {
        'totalBirdies': totalBirdieCount,
        'entryPerBirdie': 2.0,
        'roundPotContribution': 1.0,
        'tripPotContribution': 1.0,
        'cumulativeTripPot': totalTripPot,
        'coursePots': coursePots,
        'birdieEvents': birdieEvents,
        'playerLedger': playerLedger,
      },
      'standings': standings,
      'pairings': pairings,
      'schedule': schedule.map((r) => r.toJson()).toList(),
    };
  }
}
