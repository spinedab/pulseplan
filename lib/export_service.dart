import 'dart:convert';

import 'package:playlist_planner/plan_model.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalProfiles,
    required this.totalAccounts,
    required this.activeAccounts,
    required this.readyAccounts,
    required this.restingAccounts,
    required this.unassignedProfiles,
    required this.profilesWithoutAccount,
    required this.currentSlots,
    required this.upcomingSlots,
  });

  final int totalProfiles;
  final int totalAccounts;
  final int activeAccounts;
  final int readyAccounts;
  final int restingAccounts;
  final int unassignedProfiles;
  final int profilesWithoutAccount;
  final List<ScheduleSlot> currentSlots;
  final List<ScheduleSlot> upcomingSlots;
}

class ScheduleSlot {
  const ScheduleSlot({
    required this.profile,
    required this.day,
    required this.segment,
    required this.accountLabel,
    required this.minutesUntilStart,
    required this.isActiveNow,
  });

  final ListeningProfile profile;
  final DayPlan day;
  final ListeningSegment segment;
  final String accountLabel;
  final int minutesUntilStart;
  final bool isActiveNow;
}

class OperationalStep {
  const OperationalStep({
    required this.order,
    required this.title,
    required this.detail,
    required this.completed,
  });

  final int order;
  final String title;
  final String detail;
  final bool completed;
}

class ExportService {
  static int _currentMinuteOfDay(DateTime now) => now.hour * 60 + now.minute;

  static int _dayOffsetForDate(DateTime monthStart, DateTime now) {
    final start = DateTime(monthStart.year, monthStart.month, monthStart.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays;
  }

  static DayPlan? _dayForToday(ListeningProfile profile, DateTime monthStart) {
    final offset = _dayOffsetForDate(monthStart, DateTime.now());
    if (offset < 0 || offset >= profile.days.length) {
      return null;
    }
    return profile.days[offset];
  }

  static String accountLabelForProfile(
    ListeningProfile profile,
    List<MusicAccount> accounts,
  ) {
    for (final account in accounts) {
      if (account.assignedProfileId == profile.id) {
        return account.label;
      }
    }
    return 'Sin cuenta';
  }

  static DashboardSummary buildDashboard({
    required List<ListeningProfile> profiles,
    required List<MusicAccount> accounts,
    required DateTime monthStart,
  }) {
    final nowMinute = _currentMinuteOfDay(DateTime.now());
    final current = <ScheduleSlot>[];
    final upcoming = <ScheduleSlot>[];

    for (final profile in profiles) {
      final day = _dayForToday(profile, monthStart);
      if (day == null) {
        continue;
      }
      final accountLabel = accountLabelForProfile(profile, accounts);
      for (final segment in day.segments) {
        final start = segment.startMinute;
        final end = segment.endMinute;
        final isActive = nowMinute >= start && nowMinute < end;
        final minutesUntil = start - nowMinute;
        final slot = ScheduleSlot(
          profile: profile,
          day: day,
          segment: segment,
          accountLabel: accountLabel,
          minutesUntilStart: minutesUntil,
          isActiveNow: isActive,
        );
        if (isActive) {
          current.add(slot);
        } else if (minutesUntil > 0 && minutesUntil <= 180) {
          upcoming.add(slot);
        }
      }
    }

    current.sort((a, b) => a.segment.startMinute.compareTo(b.segment.startMinute));
    upcoming.sort(
      (a, b) => a.minutesUntilStart.compareTo(b.minutesUntilStart),
    );

    final assignedIds = accounts
        .map((account) => account.assignedProfileId)
        .whereType<String>()
        .toSet();

    var profilesWithoutAccount = 0;
    for (final profile in profiles) {
      if (!assignedIds.contains(profile.id)) {
        profilesWithoutAccount++;
      }
    }

    return DashboardSummary(
      totalProfiles: profiles.length,
      totalAccounts: accounts.length,
      activeAccounts: accounts
          .where((account) => account.status == AccountStatus.active)
          .length,
      readyAccounts: accounts
          .where((account) => account.status == AccountStatus.ready)
          .length,
      restingAccounts: accounts
          .where((account) => account.status == AccountStatus.resting)
          .length,
      unassignedProfiles: accounts
          .where((account) => account.assignedProfileId == null)
          .length,
      profilesWithoutAccount: profilesWithoutAccount,
      currentSlots: current.take(8).toList(),
      upcomingSlots: upcoming.take(8).toList(),
    );
  }

  static List<OperationalStep> buildOperationalChecklist({
    required ListeningProfile profile,
    required DayPlan day,
    required MusicAccount? account,
    required Map<String, bool> health,
  }) {
    final mainSegment = day.segments.firstWhere(
      (segment) => segment.kind == SegmentKind.mainPlaylist,
      orElse: () => day.segments.first,
    );

    return [
      OperationalStep(
        order: 1,
        title: 'Revisar proxy y conexion',
        detail: 'Confirma que el dispositivo tiene red estable.',
        completed: (health['Proxy activo'] ?? false) &&
            (health['Conexion revisada'] ?? false),
      ),
      OperationalStep(
        order: 2,
        title: 'Abrir Tidal con el bloque del dia',
        detail:
            'Perfil ${profile.name} / ${account?.label ?? 'sin cuenta'} / '
            '${mainSegment.title}',
        completed: health['Plan del dia listo'] ?? false,
      ),
      OperationalStep(
        order: 3,
        title: 'Iniciar sesion manualmente',
        detail: 'Usa la cuenta asignada. PulsePlan no guarda credenciales.',
        completed: account?.status == AccountStatus.active,
      ),
      OperationalStep(
        order: 4,
        title: 'Reproducir segun horario',
        detail:
            '${minutesToClock(mainSegment.startMinute)} - '
            '${minutesToClock(mainSegment.endMinute)} '
            '(${minutesToDurationLabel(mainSegment.durationMinutes)})',
        completed: health['Musica activa'] ?? false,
      ),
      const OperationalStep(
        order: 5,
        title: 'Registrar evento',
        detail: 'Marca activa/pausa en el panel de estado.',
        completed: false,
      ),
    ];
  }

  static String buildCsv({
    required PlannerSnapshot snapshot,
    required List<ListeningProfile> activeProfiles,
  }) {
    final buffer = StringBuffer(
      'profile,account,account_status,day,date,segment_kind,title,'
      'start,end,duration_minutes,main_minutes,total_minutes\n',
    );

    for (final profile in activeProfiles) {
      final account = snapshot.accounts.firstWhere(
        (item) => item.assignedProfileId == profile.id,
        orElse: () => const MusicAccount(
          id: 'none',
          label: 'Sin cuenta',
          status: AccountStatus.ready,
        ),
      );

      for (final day in profile.days) {
        for (final segment in day.segments) {
          buffer.writeln(
            [
              _csv(profile.name),
              _csv(account.label),
              _csv(account.status.label),
              day.day,
              _dateKey(day.date),
              _csv(segment.kind.label),
              _csv(segment.title),
              minutesToClock(segment.startMinute),
              minutesToClock(segment.endMinute),
              segment.durationMinutes,
              day.mainMinutes,
              day.totalMinutes,
            ].join(','),
          );
        }
      }
    }

    return buffer.toString();
  }

  static String buildIcs({
    required PlannerSnapshot snapshot,
    required List<ListeningProfile> activeProfiles,
  }) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//PulsePlan//ES')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH');

    for (final profile in activeProfiles) {
      final account = snapshot.accounts.firstWhere(
        (item) => item.assignedProfileId == profile.id,
        orElse: () => const MusicAccount(
          id: 'none',
          label: 'Sin cuenta',
          status: AccountStatus.ready,
        ),
      );

      for (final day in profile.days) {
        for (final segment in day.segments) {
          final start = day.date.add(Duration(minutes: segment.startMinute));
          final end = start.add(Duration(minutes: segment.durationMinutes));
          final uid =
              '${profile.id}_${day.day}_${segment.id}@pulseplan.local';
          buffer
            ..writeln('BEGIN:VEVENT')
            ..writeln('UID:$uid')
            ..writeln(
              'DTSTAMP:${_icsDateTime(DateTime.now().toUtc())}',
            )
            ..writeln('DTSTART:${_icsDateTime(start)}')
            ..writeln('DTEND:${_icsDateTime(end)}')
            ..writeln(
              'SUMMARY:${_icsText('${profile.name}: ${segment.title}')}',
            )
            ..writeln(
              'DESCRIPTION:${_icsText('Cuenta: ${account.label} | ${segment.kind.label}')}',
            )
            ..writeln('END:VEVENT');
        }
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String buildTemplateJson({
    required LibrarySettings settings,
    required int profileCount,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'template': 'PulsePlan',
      'version': 1,
      'profileCount': profileCount,
      'settings': settings.toJson(),
      'note':
          'Importa esta plantilla y pulsa Aplicar para regenerar el plan.',
    });
  }

  static LibrarySettings? parseTemplateSettings(String source) {
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      if (decoded['settings'] is Map<String, dynamic>) {
        return LibrarySettings.fromJson(
          decoded['settings'] as Map<String, dynamic>,
        );
      }
      if (decoded['profileCount'] != null || decoded['mainPlaylist'] != null) {
        return LibrarySettings.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  static Uri tidalUrlForSegment(ListeningSegment segment) {
    final query = Uri.encodeComponent(segment.title.trim());
    if (query.isEmpty) {
      return Uri.parse('https://tidal.com/browse');
    }
    return Uri.parse('https://tidal.com/search?q=$query');
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _icsDateTime(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  static String _icsText(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}