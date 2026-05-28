import 'package:flutter_test/flutter_test.dart';
import 'package:playlist_planner/main.dart';
import 'package:playlist_planner/plan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('generator builds a reversible two month cycle', () {
    final settings = LibrarySettings.defaults().copyWith(
      profileCount: 3,
      profilePrefix: 'NEW50',
      profileStartNumber: 35,
    );
    final monthStart = DateTime(2026, 5);
    final monthOne = PlanGenerator.generate(
      settings: settings,
      monthStart: monthStart,
    );
    final monthTwo = PlanGenerator.generateSecondMonth(
      firstMonthProfiles: monthOne,
      secondMonthStart: PlanGenerator.nextMonthStart(monthStart),
    );

    expect(monthOne, hasLength(3));
    expect(monthOne.first.name, 'NEW50-035');
    expect(monthOne.first.days, hasLength(30));
    for (final profile in monthOne) {
      for (final day in profile.days) {
        expect(day.mainMinutes, settings.targetMinutes);
      }
    }
    expect(
      monthTwo.first.days.first.segments.first.title,
      monthOne.first.days.last.segments.first.title,
    );
    expect(
      monthTwo.first.days.last.segments.first.title,
      monthOne.first.days.first.segments.first.title,
    );
  });

  test('generator supports a 100 device staggered schedule', () {
    final settings = LibrarySettings.defaults().copyWith(profileCount: 100);
    final profiles = PlanGenerator.generate(
      settings: settings,
      monthStart: DateTime(2026, 5),
    );
    final starts = profiles
        .map(
          (profile) => profile.days.first.segments
              .firstWhere((segment) => segment.kind == SegmentKind.mainPlaylist)
              .startMinute,
        )
        .toSet();

    expect(profiles, hasLength(100));
    expect(starts.length, greaterThan(80));
    expect(profiles.last.days.first.mainMinutes, 13 * 60);
  });

  testWidgets('app renders the planner shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PlaylistPlannerApp());
    await tester.pumpAndSettle();

    expect(find.text('PulsePlan'), findsOneWidget);
    expect(find.text('Plan'), findsWidgets);
    expect(find.text('Mes 1'), findsOneWidget);
    expect(find.text('Mes 2'), findsOneWidget);
  });

  test('PlanGenerator handles empty artists gracefully', () {
    final settings = LibrarySettings.defaults().copyWith(artists: []);
    final profiles = PlanGenerator.generate(
      settings: settings,
      monthStart: DateTime(2026, 5),
    );

    expect(profiles, isNotEmpty);
    expect(profiles.first.days.first.mainMinutes, settings.targetMinutes);
  });

  test('PlannerSnapshot roundtrips without data loss', () {
    final original = PlannerSnapshot(
      settings: LibrarySettings.defaults(),
      monthStart: DateTime(2026, 5),
      profiles: PlanGenerator.generate(
        settings: LibrarySettings.defaults(),
        monthStart: DateTime(2026, 5),
      ),
      accounts: const [],
    );

    final json = original.toJsonString();
    final restored = PlannerSnapshot.fromJson(json);

    expect(restored.settings.profileCount, original.settings.profileCount);
    expect(restored.profiles.length, original.profiles.length);
  });
}
