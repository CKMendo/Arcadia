# Arcadia Golf Trip Tournament App — Project Status

## Overview
A tournament scoring and trip management Flutter application built for an 8-player golf trip. Designed for fast on-the-course scoring, spotty cellular environments (offline-first with Drift SQLite), Galaxy Fold & mobile daylight readability, and flexible competition formats.

## Current Tech Stack
- **Framework**: Flutter 3.44.7 (Dart 3.12.2)
- **Database**: Drift SQLite (`drift: ^2.34.2`, `drift_flutter: ^0.3.1`)
- **State & Storage**: Offline-first reactive streams, local SQLite persistence
- **Sharing**: `share_plus` for texting round leaderboards & overall standings to the group chat
- **Theme**: Lake Michigan Coastal Links aesthetic (Deep Oceanic Navy `#0A1118`, Lake Cyan `#00B4D8`, Dune Sand `#DFC19E`, modern sans-serif typography, high-contrast daylight scoring markers)

## Features Implemented

### 1. Roster Management (`lib/features/players/`)
- Empty start as requested: Add custom players from scratch
- Optional 1-tap "Load Sample 8 Players" or "Clear All" for testing
- Fields: Full Name, Nickname, Initials, Handicap Index, Preferred Tee, GHIN #, Phone, Email, Photo Path
- Automatic initial generator & handicap badge display

### 2. Courses & Tees (`lib/features/courses/`)
- Manual scratch entry: Course name, city, state, 18 or 9 holes
- Tee boxes: Custom name (Black, Blue, White, Gold, etc.), Course Rating, Slope Rating, total yardage
- 18-hole configuration: Par selector (3, 4, 5) and Handicap/Stroke Index (1..18)
- 1-tap preset templates: "Arcadia Bluffs (The Bluffs)" and "Arcadia Bluffs (The South)" with authentic ratings, slopes, pars, and handicap indexes

### 3. Trip & Tournament Management (`lib/features/tournaments/`)
- Multi-day trip setup (Name, Start/End dates)
- Flexible competition styles:
  - **Hybrid**: Individual Net/Gross + Stableford + Skins + 4v4 Team matches
  - **4v4 Teams**: Team Blue vs Team Red with customizable team rosters
  - **Individual**: Championship stroke play and Stableford
- Team assignment selector (4-on-4)

### 4. Live Hole-by-Hole Scoring (`lib/features/rounds/`)
- **Optimized for Galaxy Fold & Mobile Screens**: Large touch targets, high contrast, tactile thumb-friendly controls
- Rapid score entry: `[-]` / `[+]` incrementers and quick-tap 1-10 keypad sheet
- Automatic USGA Course Handicap & stroke allocation per hole:
  - $\text{Course Handicap} = \text{Handicap Index} \times (\text{Slope} / 113) + (\text{Rating} - \text{Par})$
  - Visual handicap stroke dots on each hole
  - Instant Net Score indicator with color badge (Eagle gold, Birdie red, Par teal, Bogey blue)
  - Real-time Stableford points earned on the hole
- Putts counter and side-game bonus chips:
  - **Greenie (🎯 CTP)**: Closest to pin toggle on Par 3s
  - **Sandie (🏖️)**: Up-and-down from sand
- **Auto-Save Durability**: Every tap saves to `ActiveRoundDraft` SQLite table. Closing the app or sleeping the device never loses a stroke
- In-round live leaderboard and skins tracker sheet

### 5. Leaderboards & Standings (`lib/features/standings/`)
- Aggregates all completed trip rounds:
  - **Overall Net Total** (Cumulative net strokes vs par)
  - **Stableford Championship** (Total points accumulated)
  - **Overall Gross Total** (Total gross strokes)
  - **Skins Leaderboard** (Cumulative skins won and purse/points)
  - **Team Standings** (4v4 Team Blue vs Team Red cumulative points)
- One-tap "Share Results" (generates clean text ready to send via SMS or WhatsApp group chat)

## Verification
- Unit test suite (`test/widget_test.dart`) passes 4/4 tests:
  - Course handicap calculation formula
  - Hole stroke allocation logic
  - USGA Stableford point scoring
  - Multi-hole skins calculation with carryovers
- `flutter analyze`: 0 errors, 0 warnings, 0 lints
