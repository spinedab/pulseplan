import 'package:flutter_test/flutter_test.dart';
import 'package:playlist_planner/export_service.dart';
import 'package:playlist_planner/plan_model.dart';

void main() {
  test('buildCsv includes profile and segment rows', () {
    final settings = LibrarySettings.defaults().copyWith(profileCount: 2);
    final monthStart = DateTime(2026, 6);
    final profiles = PlanGenerator.generate(
      settings: settings,
      monthStart: monthStart,
    );
    final snapshot = PlannerSnapshot(
      settings: settings,
      monthStart: monthStart,
      profiles: profiles,
      accounts: const [],
    );

    final csv = ExportService.buildCsv(
      snapshot: snapshot,
      activeProfiles: profiles,
    );

    expect(csv, contains('profile,account,account_status,day,date'));
    expect(csv.split('\n').length, greaterThan(10));
  });

  test('buildIcs produces valid calendar envelope', () {
    final settings = LibrarySettings.defaults().copyWith(profileCount: 1);
    final monthStart = DateTime(2026, 6);
    final profiles = PlanGenerator.generate(
      settings: settings,
      monthStart: monthStart,
    );
    final snapshot = PlannerSnapshot(
      settings: settings,
      monthStart: monthStart,
      profiles: profiles,
      accounts: const [],
    );

    final ics = ExportService.buildIcs(
      snapshot: snapshot,
      activeProfiles: profiles,
    );

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('END:VCALENDAR'));
  });

  test('tidalUrlForSegment encodes search query', () {
    final uri = ExportService.tidalUrlForSegment(
      const ListeningSegment(
        id: 's1',
        kind: SegmentKind.artistFocus,
        title: 'Bad Bunny',
        startMinute: 480,
        durationMinutes: 30,
      ),
    );

    expect(uri.toString(), contains('tidal.com/search'));
    expect(uri.toString(), contains('Bad'));
  });

  test('parseTemplateSettings reads embedded settings', () {
    final template = ExportService.buildTemplateJson(
      settings: LibrarySettings.defaults().copyWith(profileCount: 25),
      profileCount: 25,
    );

    final parsed = ExportService.parseTemplateSettings(template);
    expect(parsed?.profileCount, 25);
  });
}