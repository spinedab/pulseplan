import 'dart:convert';
import 'dart:math';

enum SegmentKind { mainPlaylist, artistFocus, secondaryPlaylist, discovery }

enum AccountStatus { ready, active, resting }

extension AccountStatusLabel on AccountStatus {
  String get label {
    switch (this) {
      case AccountStatus.ready:
        return 'Lista';
      case AccountStatus.active:
        return 'Activa';
      case AccountStatus.resting:
        return 'Descanso';
    }
  }

  String get jsonName => name;

  static AccountStatus fromJsonName(String value) {
    return AccountStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AccountStatus.ready,
    );
  }
}

extension SegmentKindLabel on SegmentKind {
  String get label {
    switch (this) {
      case SegmentKind.mainPlaylist:
        return 'Playlist principal';
      case SegmentKind.artistFocus:
        return 'Artista';
      case SegmentKind.secondaryPlaylist:
        return 'Playlist alterna';
      case SegmentKind.discovery:
        return 'Descubrimiento';
    }
  }

  String get jsonName => name;

  static SegmentKind fromJsonName(String value) {
    return SegmentKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => SegmentKind.mainPlaylist,
    );
  }
}

class MusicAccount {
  const MusicAccount({
    required this.id,
    required this.label,
    required this.status,
    this.assignedProfileId,
    this.note = '',
  });

  factory MusicAccount.fromJson(Map<String, dynamic> json) {
    return MusicAccount(
      id: json['id'] as String? ?? 'account',
      label: json['label'] as String? ?? 'Cuenta',
      status: AccountStatusLabel.fromJsonName(json['status'] as String? ?? ''),
      assignedProfileId: json['assignedProfileId'] as String?,
      note: json['note'] as String? ?? '',
    );
  }

  final String id;
  final String label;
  final AccountStatus status;
  final String? assignedProfileId;
  final String note;

  MusicAccount copyWith({
    String? id,
    String? label,
    AccountStatus? status,
    String? assignedProfileId,
    bool clearAssignedProfile = false,
    String? note,
  }) {
    return MusicAccount(
      id: id ?? this.id,
      label: label ?? this.label,
      status: status ?? this.status,
      assignedProfileId: clearAssignedProfile
          ? null
          : assignedProfileId ?? this.assignedProfileId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'status': status.jsonName,
      'assignedProfileId': assignedProfileId,
      'note': note,
    };
  }
}

class LibrarySettings {
  const LibrarySettings({
    required this.profileCount,
    required this.targetMinutes,
    required this.seed,
    required this.cycleMonths,
    required this.reverseSecondMonth,
    required this.profilePrefix,
    required this.profileStartNumber,
    required this.mainPlaylist,
    required this.artists,
    required this.secondaryPlaylists,
  });

  factory LibrarySettings.defaults() {
    return const LibrarySettings(
      profileCount: 4,
      targetMinutes: 13 * 60,
      seed: 2407,
      cycleMonths: 2,
      reverseSecondMonth: true,
      profilePrefix: 'MUSIC',
      profileStartNumber: 1,
      mainPlaylist: 'Playlist principal',
      artists: ['Karol G', 'Feid', 'Bad Bunny', 'Shakira', 'Rauw Alejandro'],
      secondaryPlaylists: [
        'Pop latino nuevo',
        'Urbano suave',
        'Descubrimiento semanal',
        'Favoritas de la tarde',
      ],
    );
  }

  factory LibrarySettings.fromJson(Map<String, dynamic> json) {
    return LibrarySettings(
      profileCount: (json['profileCount'] as num?)?.toInt() ?? 4,
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 13 * 60,
      seed: (json['seed'] as num?)?.toInt() ?? 2407,
      cycleMonths: (json['cycleMonths'] as num?)?.toInt() ?? 2,
      reverseSecondMonth: json['reverseSecondMonth'] as bool? ?? true,
      profilePrefix: json['profilePrefix'] as String? ?? 'MUSIC',
      profileStartNumber: (json['profileStartNumber'] as num?)?.toInt() ?? 1,
      mainPlaylist: json['mainPlaylist'] as String? ?? 'Playlist principal',
      artists: _stringList(json['artists']),
      secondaryPlaylists: _stringList(json['secondaryPlaylists']),
    );
  }

  final int profileCount;
  final int targetMinutes;
  final int seed;
  final int cycleMonths;
  final bool reverseSecondMonth;
  final String profilePrefix;
  final int profileStartNumber;
  final String mainPlaylist;
  final List<String> artists;
  final List<String> secondaryPlaylists;

  LibrarySettings copyWith({
    int? profileCount,
    int? targetMinutes,
    int? seed,
    int? cycleMonths,
    bool? reverseSecondMonth,
    String? profilePrefix,
    int? profileStartNumber,
    String? mainPlaylist,
    List<String>? artists,
    List<String>? secondaryPlaylists,
  }) {
    return LibrarySettings(
      profileCount: profileCount ?? this.profileCount,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      seed: seed ?? this.seed,
      cycleMonths: cycleMonths ?? this.cycleMonths,
      reverseSecondMonth: reverseSecondMonth ?? this.reverseSecondMonth,
      profilePrefix: profilePrefix ?? this.profilePrefix,
      profileStartNumber: profileStartNumber ?? this.profileStartNumber,
      mainPlaylist: mainPlaylist ?? this.mainPlaylist,
      artists: artists ?? this.artists,
      secondaryPlaylists: secondaryPlaylists ?? this.secondaryPlaylists,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileCount': profileCount,
      'targetMinutes': targetMinutes,
      'seed': seed,
      'cycleMonths': cycleMonths,
      'reverseSecondMonth': reverseSecondMonth,
      'profilePrefix': profilePrefix,
      'profileStartNumber': profileStartNumber,
      'mainPlaylist': mainPlaylist,
      'artists': artists,
      'secondaryPlaylists': secondaryPlaylists,
    };
  }
}

class ListeningSegment {
  const ListeningSegment({
    required this.id,
    required this.kind,
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
  });

  factory ListeningSegment.fromJson(Map<String, dynamic> json) {
    return ListeningSegment(
      id: json['id'] as String? ?? 'segment',
      kind: SegmentKindLabel.fromJsonName(json['kind'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final SegmentKind kind;
  final String title;
  final int startMinute;
  final int durationMinutes;

  int get endMinute => startMinute + durationMinutes;

  ListeningSegment copyWith({
    String? id,
    SegmentKind? kind,
    String? title,
    int? startMinute,
    int? durationMinutes,
  }) {
    return ListeningSegment(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.jsonName,
      'title': title,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
    };
  }
}

class DayPlan {
  const DayPlan({
    required this.day,
    required this.date,
    required this.segments,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: (json['day'] as num?)?.toInt() ?? 1,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      segments: (json['segments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ListeningSegment.fromJson)
          .toList(),
    );
  }

  final int day;
  final DateTime date;
  final List<ListeningSegment> segments;

  int get totalMinutes {
    return segments.fold<int>(
      0,
      (sum, segment) => sum + segment.durationMinutes,
    );
  }

  int get mainMinutes {
    return segments
        .where((segment) => segment.kind == SegmentKind.mainPlaylist)
        .fold<int>(0, (sum, segment) => sum + segment.durationMinutes);
  }

  int get variationMinutes {
    return segments
        .where((segment) => segment.kind != SegmentKind.mainPlaylist)
        .fold<int>(0, (sum, segment) => sum + segment.durationMinutes);
  }

  DayPlan copyWith({List<ListeningSegment>? segments}) {
    return DayPlan(day: day, date: date, segments: segments ?? this.segments);
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': _dateKey(date),
      'totalMinutes': totalMinutes,
      'mainMinutes': mainMinutes,
      'variationMinutes': variationMinutes,
      'segments': segments.map((segment) => segment.toJson()).toList(),
    };
  }
}

class ListeningProfile {
  const ListeningProfile({
    required this.id,
    required this.name,
    required this.seed,
    required this.colorValue,
    required this.days,
  });

  factory ListeningProfile.fromJson(Map<String, dynamic> json) {
    return ListeningProfile(
      id: json['id'] as String? ?? 'profile',
      name: json['name'] as String? ?? 'Dispositivo',
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xff1565c0,
      days: (json['days'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DayPlan.fromJson)
          .toList(),
    );
  }

  final String id;
  final String name;
  final int seed;
  final int colorValue;
  final List<DayPlan> days;

  ListeningProfile copyWith({List<DayPlan>? days}) {
    return ListeningProfile(
      id: id,
      name: name,
      seed: seed,
      colorValue: colorValue,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seed': seed,
      'colorValue': colorValue,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}

class PlannerSnapshot {
  const PlannerSnapshot({
    required this.settings,
    required this.monthStart,
    required this.profiles,
    required this.accounts,
  });

  factory PlannerSnapshot.fromJson(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return PlannerSnapshot(
      settings: LibrarySettings.fromJson(
        decoded['settings'] as Map<String, dynamic>? ?? {},
      ),
      monthStart:
          DateTime.tryParse(decoded['monthStart'] as String? ?? '') ??
          PlanGenerator.currentMonthStart(),
      profiles: (decoded['profiles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ListeningProfile.fromJson)
          .toList(),
      accounts: (decoded['accounts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MusicAccount.fromJson)
          .toList(),
    );
  }

  final LibrarySettings settings;
  final DateTime monthStart;
  final List<ListeningProfile> profiles;
  final List<MusicAccount> accounts;

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  Map<String, dynamic> toJson() {
    final secondMonthProfiles = settings.reverseSecondMonth
        ? PlanGenerator.generateSecondMonth(
            firstMonthProfiles: profiles,
            secondMonthStart: PlanGenerator.nextMonthStart(monthStart),
          )
        : const <ListeningProfile>[];

    return {
      'app': 'PulsePlan',
      'scope': 'personal_authorized_planning',
      'monthStart': _dateKey(monthStart),
      'cycleDays': settings.reverseSecondMonth ? 60 : 30,
      'settings': settings.toJson(),
      'rotationPolicy': {
        'manualLogin': true,
        'credentialStorage': false,
        'cycleMonths': settings.reverseSecondMonth ? 2 : 1,
        'secondMonth': settings.reverseSecondMonth
            ? 'inverse_of_month_1'
            : 'none',
        'afterCycle':
            'mark_current_accounts_resting_and_assign_new_accounts_manually',
      },
      'accounts': accounts.map((account) => account.toJson()).toList(),
      'months': [
        {
          'name': 'month_1_base',
          'start': _dateKey(monthStart),
          'profiles': profiles.map((profile) => profile.toJson()).toList(),
        },
        if (settings.reverseSecondMonth)
          {
            'name': 'month_2_inverse',
            'start': _dateKey(PlanGenerator.nextMonthStart(monthStart)),
            'profiles': secondMonthProfiles
                .map((profile) => profile.toJson())
                .toList(),
          },
      ],
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
    };
  }
}

class VariationBlock {
  const VariationBlock({
    required this.kind,
    required this.title,
    required this.afterMainMinutes,
    required this.durationMinutes,
    this.beforeMain = false,
  });

  final SegmentKind kind;
  final String title;
  final int afterMainMinutes;
  final int durationMinutes;
  final bool beforeMain;
}

class PlanGenerator {
  static DateTime currentMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  static DateTime nextMonthStart(DateTime date) {
    return DateTime(date.year, date.month + 1);
  }

  static List<ListeningProfile> generateSecondMonth({
    required List<ListeningProfile> firstMonthProfiles,
    required DateTime secondMonthStart,
  }) {
    return firstMonthProfiles.map((profile) {
      final reversedDays = List.generate(profile.days.length, (index) {
        final source = profile.days[profile.days.length - index - 1];
        return DayPlan(
          day: index + 1,
          date: secondMonthStart.add(Duration(days: index)),
          segments: source.segments
              .map(
                (segment) =>
                    segment.copyWith(id: 'm2_d${index + 1}_${segment.id}'),
              )
              .toList(),
        );
      });

      return profile.copyWith(days: reversedDays);
    }).toList();
  }

  static List<ListeningProfile> generate({
    required LibrarySettings settings,
    required DateTime monthStart,
  }) {
    final count = settings.profileCount.clamp(1, 100);
    return List.generate(count, (profileIndex) {
      final profileSeed = settings.seed + (profileIndex + 1) * 7919;
      final days = List.generate(30, (dayOffset) {
        return _generateDay(
          settings: settings,
          profileIndex: profileIndex,
          profileSeed: profileSeed,
          day: dayOffset + 1,
          date: monthStart.add(Duration(days: dayOffset)),
        );
      });

      return ListeningProfile(
        id: 'device_${profileIndex + 1}',
        name: _profileName(settings, profileIndex),
        seed: profileSeed,
        colorValue: _profileColors[profileIndex % _profileColors.length],
        days: days,
      );
    });
  }

  static String _profileName(LibrarySettings settings, int profileIndex) {
    final prefix = settings.profilePrefix.trim().isEmpty
        ? 'MUSIC'
        : settings.profilePrefix.trim();
    final number = settings.profileStartNumber + profileIndex;
    return '$prefix-${number.toString().padLeft(3, '0')}';
  }

  static DayPlan _generateDay({
    required LibrarySettings settings,
    required int profileIndex,
    required int profileSeed,
    required int day,
    required DateTime date,
  }) {
    final random = Random(profileSeed + day * 1093);
    final startMinute =
        (profileIndex * 37 + day * 43 + random.nextInt(31)) % (24 * 60);
    final targetMinutes = settings.targetMinutes.clamp(60, 24 * 60);
    final blocks = [
      ..._variationBlocks(
        settings: settings,
        random: random,
        profileIndex: profileIndex,
        day: day,
        targetMinutes: targetMinutes,
      ),
    ];
    final segments = <ListeningSegment>[];
    var customIndex = 0;

    for (final block in blocks.where((block) => block.beforeMain)) {
      final gap = 6 + random.nextInt(10);
      segments.add(
        ListeningSegment(
          id: 'd${day}_pre_${customIndex++}',
          kind: block.kind,
          title: block.title,
          startMinute: startMinute - block.durationMinutes - gap,
          durationMinutes: block.durationMinutes,
        ),
      );
    }

    var cursor = startMinute;
    var mainPlayed = 0;

    final midBlocks = blocks.where((block) => !block.beforeMain).toList()
      ..sort(
        (left, right) =>
            left.afterMainMinutes.compareTo(right.afterMainMinutes),
      );

    for (final block in midBlocks) {
      final playUntil = block.afterMainMinutes.clamp(
        mainPlayed,
        targetMinutes - 1,
      );
      final mainChunk = playUntil - mainPlayed;
      if (mainChunk > 0) {
        segments.add(
          _mainSegment(settings, day, segments.length, cursor, mainChunk),
        );
        cursor += mainChunk;
        mainPlayed += mainChunk;
      }

      segments.add(
        ListeningSegment(
          id: 'd${day}_creative_${customIndex++}',
          kind: block.kind,
          title: block.title,
          startMinute: cursor,
          durationMinutes: block.durationMinutes,
        ),
      );
      cursor += block.durationMinutes;
    }

    final remainingMain = targetMinutes - mainPlayed;
    if (remainingMain > 0) {
      segments.add(
        _mainSegment(settings, day, segments.length, cursor, remainingMain),
      );
    }

    segments.sort(
      (left, right) => left.startMinute.compareTo(right.startMinute),
    );
    return DayPlan(day: day, date: date, segments: segments);
  }

  static List<VariationBlock> _variationBlocks({
    required LibrarySettings settings,
    required Random random,
    required int profileIndex,
    required int day,
    required int targetMinutes,
  }) {
    final mode = (day + profileIndex + random.nextInt(3)) % 6;
    final durationA = 10 + random.nextInt(16);
    final durationB = 12 + random.nextInt(21);
    final artist = _pick(
      settings.artists,
      random,
      fallback: 'Artista favorito',
    );
    final secondary = _pick(
      settings.secondaryPlaylists,
      random,
      fallback: 'Playlist alterna',
    );
    final middleAfter = targetMinutes * (38 + random.nextInt(28)) ~/ 100;
    final lateAfter = targetMinutes * (68 + random.nextInt(18)) ~/ 100;
    final earlyAfter = targetMinutes * (12 + random.nextInt(18)) ~/ 100;

    switch (mode) {
      case 0:
        return [
          VariationBlock(
            kind: SegmentKind.artistFocus,
            title: artist,
            afterMainMinutes: 0,
            durationMinutes: durationA,
            beforeMain: true,
          ),
        ];
      case 1:
        return const [];
      case 2:
        return [
          VariationBlock(
            kind: SegmentKind.artistFocus,
            title: artist,
            afterMainMinutes: middleAfter,
            durationMinutes: durationA,
          ),
        ];
      case 3:
        return [
          VariationBlock(
            kind: SegmentKind.secondaryPlaylist,
            title: secondary,
            afterMainMinutes: 0,
            durationMinutes: durationA,
            beforeMain: true,
          ),
          VariationBlock(
            kind: SegmentKind.discovery,
            title: secondary,
            afterMainMinutes: lateAfter,
            durationMinutes: durationB,
          ),
        ];
      case 4:
        return [
          VariationBlock(
            kind: SegmentKind.discovery,
            title: secondary,
            afterMainMinutes: earlyAfter,
            durationMinutes: durationA,
          ),
          VariationBlock(
            kind: SegmentKind.secondaryPlaylist,
            title: secondary,
            afterMainMinutes: lateAfter,
            durationMinutes: durationB,
          ),
        ];
      default:
        return [
          VariationBlock(
            kind: SegmentKind.discovery,
            title: secondary,
            afterMainMinutes: middleAfter,
            durationMinutes: durationA,
          ),
        ];
    }
  }

  static ListeningSegment _mainSegment(
    LibrarySettings settings,
    int day,
    int index,
    int startMinute,
    int durationMinutes,
  ) {
    return ListeningSegment(
      id: 'd${day}_main_$index',
      kind: SegmentKind.mainPlaylist,
      title: settings.mainPlaylist,
      startMinute: startMinute,
      durationMinutes: durationMinutes,
    );
  }
}

String minutesToClock(int minutes) {
  final normalized = minutes % (24 * 60);
  final hour = normalized ~/ 60;
  final minute = normalized % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String minutesToDurationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return '${rest}m';
  }
  if (rest == 0) {
    return '${hours}h';
  }
  return '${hours}h ${rest}m';
}

List<String> parseLines(String source) {
  return source
      .split(RegExp(r'[\n,]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  return const [];
}

String _pick(List<String> values, Random random, {required String fallback}) {
  final usable = values.where((item) => item.trim().isNotEmpty).toList();
  if (usable.isEmpty) {
    return fallback;
  }
  return usable[random.nextInt(usable.length)];
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

const _profileColors = <int>[
  0xff1565c0,
  0xff2e7d32,
  0xffad1457,
  0xff6a1b9a,
  0xff00838f,
  0xffef6c00,
  0xff455a64,
  0xff5d4037,
  0xff283593,
  0xff00695c,
  0xff9e9d24,
  0xffc62828,
];
