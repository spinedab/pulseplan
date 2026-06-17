import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:playlist_planner/app_theme.dart';
import 'package:playlist_planner/export_service.dart';
import 'package:playlist_planner/plan_model.dart';

void main() {
  runApp(const PlaylistPlannerApp());
}

class PlaylistPlannerApp extends StatefulWidget {
  const PlaylistPlannerApp({super.key});

  @override
  State<PlaylistPlannerApp> createState() => _PlaylistPlannerAppState();
}

class _PlaylistPlannerAppState extends State<PlaylistPlannerApp> {
  static const _themeKey = 'playlist_planner_theme_v1';
  var _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, next == ThemeMode.dark ? 'dark' : 'light');
    if (!mounted) {
      return;
    }
    setState(() => _themeMode = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PulsePlan',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: PlannerHomePage(onToggleTheme: _toggleTheme),
    );
  }
}

class PlannerHomePage extends StatefulWidget {
  const PlannerHomePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<PlannerHomePage> createState() => _PlannerHomePageState();
}

class _PlannerHomePageState extends State<PlannerHomePage> {
  static const _storeKey = 'playlist_planner_snapshot_v1';
  static const _healthKey = 'playlist_planner_health_v1';
  static const _healthLogKey = 'playlist_planner_health_log_v1';

  late LibrarySettings _settings;
  late DateTime _monthStart;
  late List<ListeningProfile> _profiles;
  late List<MusicAccount> _accounts;
  late TextEditingController _mainPlaylistController;
  late TextEditingController _artistsController;
  late TextEditingController _secondaryController;
  late TextEditingController _profilePrefixController;
  late TextEditingController _profileStartController;

  var _selectedProfile = 0;
  var _selectedDay = 0;
  var _selectedTab = 0;
  var _selectedCycleMonth = 0;
  var _loading = true;
  var _profileCountDraft = 4.0;
  var _targetHoursDraft = 13.0;

  final _health = <String, bool>{
    'Proxy activo': true,
    'Conexion revisada': true,
    'Musica activa': true,
    'Plan del dia listo': true,
  };
  final _healthLog = <String>[];

  @override
  void initState() {
    super.initState();
    _settings = LibrarySettings.defaults();
    _monthStart = PlanGenerator.currentMonthStart();
    _profiles = PlanGenerator.generate(
      settings: _settings,
      monthStart: _monthStart,
    );
    _accounts = _defaultAccountsForProfiles(_profiles);
    _mainPlaylistController = TextEditingController(
      text: _settings.mainPlaylist,
    );
    _artistsController = TextEditingController(
      text: _settings.artists.join('\n'),
    );
    _secondaryController = TextEditingController(
      text: _settings.secondaryPlaylists.join('\n'),
    );
    _profilePrefixController = TextEditingController(
      text: _settings.profilePrefix,
    );
    _profileStartController = TextEditingController(
      text: _settings.profileStartNumber.toString(),
    );
    _profileCountDraft = _settings.profileCount.toDouble();
    _targetHoursDraft = _settings.targetMinutes / 60;
    _load();
  }

  @override
  void dispose() {
    _mainPlaylistController.dispose();
    _artistsController.dispose();
    _secondaryController.dispose();
    _profilePrefixController.dispose();
    _profileStartController.dispose();
    super.dispose();
  }

  List<ListeningProfile> get _activeProfiles {
    if (_selectedCycleMonth == 1 && _settings.reverseSecondMonth) {
      return PlanGenerator.generateSecondMonth(
        firstMonthProfiles: _profiles,
        secondMonthStart: PlanGenerator.nextMonthStart(_monthStart),
      );
    }
    return _profiles;
  }

  ListeningProfile get _profile =>
      _activeProfiles[_safeIndex(_selectedProfile, _activeProfiles.length)];
  DayPlan get _day =>
      _profile.days[_safeIndex(_selectedDay, _profile.days.length)];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null) {
      // Fresh install: still try to load any previous health, then finish
      await _loadHealthState();
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = PlannerSnapshot.fromJson(raw);
      setState(() {
        _settings = snapshot.settings;
        _monthStart = snapshot.monthStart;
        _profiles = snapshot.profiles.isEmpty
            ? PlanGenerator.generate(
                settings: _settings,
                monthStart: _monthStart,
              )
            : snapshot.profiles;
        _accounts = snapshot.accounts.isEmpty
            ? _defaultAccountsForProfiles(_profiles)
            : snapshot.accounts;
        _selectedProfile = _safeIndex(_selectedProfile, _profiles.length);
        _selectedDay = _safeIndex(_selectedDay, _profile.days.length);
        _syncControllers();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }

    // Load persisted device health state (non-fatal)
    await _loadHealthState();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = PlannerSnapshot(
      settings: _settings,
      monthStart: _monthStart,
      profiles: _profiles,
      accounts: _accounts,
    );
    await prefs.setString(_storeKey, snapshot.toJsonString());
    await _saveHealthState(prefs);
  }

  void _syncControllers() {
    _mainPlaylistController.text = _settings.mainPlaylist;
    _artistsController.text = _settings.artists.join('\n');
    _secondaryController.text = _settings.secondaryPlaylists.join('\n');
    _profilePrefixController.text = _settings.profilePrefix;
    _profileStartController.text = _settings.profileStartNumber.toString();
    _profileCountDraft = _settings.profileCount.toDouble();
    _targetHoursDraft = _settings.targetMinutes / 60;
  }

  void _regenerateMonth({int? seed}) {
    setState(() {
      _settings = _settings.copyWith(seed: seed ?? _settings.seed);
      _profiles = PlanGenerator.generate(
        settings: _settings,
        monthStart: _monthStart,
      );
      _accounts = _reconcileAccounts(_accounts, _profiles);
      _selectedProfile = _safeIndex(_selectedProfile, _profiles.length);
      _selectedDay = _safeIndex(_selectedDay, _profile.days.length);
    });
    unawaited(_save());
    _showSnack('Plan mensual generado');
  }

  void _applyLibrarySettings() {
    final artists = parseLines(_artistsController.text);
    final secondary = parseLines(_secondaryController.text);
    setState(() {
      _settings = _settings.copyWith(
        profileCount: _profileCountDraft.round().clamp(1, 100),
        targetMinutes: (_targetHoursDraft * 60).round(),
        cycleMonths: _settings.reverseSecondMonth ? 2 : 1,
        profilePrefix: _profilePrefixController.text.trim().isEmpty
            ? 'MUSIC'
            : _profilePrefixController.text.trim().toUpperCase(),
        profileStartNumber:
            int.tryParse(_profileStartController.text.trim()) ?? 1,
        mainPlaylist: _mainPlaylistController.text.trim().isEmpty
            ? 'Playlist principal'
            : _mainPlaylistController.text.trim(),
        artists: artists.isEmpty ? LibrarySettings.defaults().artists : artists,
        secondaryPlaylists: secondary.isEmpty
            ? LibrarySettings.defaults().secondaryPlaylists
            : secondary,
      );
      _profiles = PlanGenerator.generate(
        settings: _settings,
        monthStart: _monthStart,
      );
      _accounts = _reconcileAccounts(_accounts, _profiles);
      _selectedProfile = _safeIndex(_selectedProfile, _profiles.length);
      _selectedDay = _safeIndex(_selectedDay, _profile.days.length);
    });
    unawaited(_save());
    _showSnack('Biblioteca aplicada');
  }

  List<MusicAccount> _defaultAccountsForProfiles(
    List<ListeningProfile> profiles,
  ) {
    return profiles
        .map(
          (profile) => MusicAccount(
            id: 'account_${profile.id}',
            label: profile.name,
            status: AccountStatus.active,
            assignedProfileId: profile.id,
          ),
        )
        .toList();
  }

  List<MusicAccount> _reconcileAccounts(
    List<MusicAccount> accounts,
    List<ListeningProfile> profiles,
  ) {
    final profileIds = profiles.map((profile) => profile.id).toSet();
    final cleaned = accounts
        .map(
          (account) => profileIds.contains(account.assignedProfileId)
              ? account
              : account.copyWith(clearAssignedProfile: true),
        )
        .toList();

    for (final profile in profiles) {
      final hasAccount = cleaned.any(
        (account) => account.assignedProfileId == profile.id,
      );
      if (!hasAccount) {
        cleaned.add(
          MusicAccount(
            id: 'account_${profile.id}_${DateTime.now().microsecondsSinceEpoch}',
            label: profile.name,
            status: AccountStatus.ready,
            assignedProfileId: profile.id,
          ),
        );
      }
    }
    return cleaned;
  }

  MusicAccount? _accountForProfile(String profileId) {
    for (final account in _accounts) {
      if (account.assignedProfileId == profileId) {
        return account;
      }
    }
    return null;
  }

  String _profileNameForAccount(MusicAccount account) {
    final profileId = account.assignedProfileId;
    if (profileId == null) {
      return 'Sin asignar';
    }
    for (final profile in _profiles) {
      if (profile.id == profileId) {
        return profile.name;
      }
    }
    return 'Sin asignar';
  }

  void _assignAccount(String profileId, String? accountId) {
    setState(() {
      _accounts = _accounts.map((account) {
        if (account.assignedProfileId == profileId) {
          return account.copyWith(clearAssignedProfile: true);
        }
        if (account.id == accountId) {
          return account.copyWith(
            assignedProfileId: profileId,
            status: AccountStatus.active,
          );
        }
        return account;
      }).toList();
    });
    unawaited(_save());
  }

  Future<void> _confirmCloseCycle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar ciclo de 60 días'),
        content: const Text(
          'Esto marcará todas las cuentas asignadas como "Descanso", '
          'generará un nuevo plan para el siguiente período y avanzará el ciclo.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cerrar ciclo'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _closeTwoMonthCycle();
    }
  }

  void _closeTwoMonthCycle() {
    setState(() {
      _accounts = _accounts
          .map(
            (account) => account.assignedProfileId == null
                ? account
                : account.copyWith(
                    status: AccountStatus.resting,
                    clearAssignedProfile: true,
                  ),
          )
          .toList();
      _selectedCycleMonth = 0;
      _settings = _settings.copyWith(seed: Random().nextInt(900000) + 1000);
      _profiles = PlanGenerator.generate(
        settings: _settings,
        monthStart: PlanGenerator.nextMonthStart(
          PlanGenerator.nextMonthStart(_monthStart),
        ),
      );
      _monthStart = PlanGenerator.nextMonthStart(
        PlanGenerator.nextMonthStart(_monthStart),
      );
    });
    unawaited(_save());
    _showSnack('Ciclo cerrado; asigna cuentas nuevas');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildDashboardTab(context),
      _buildPlanTab(context),
      _buildAccountsTab(context),
      _buildLibraryTab(context),
      _buildExportTab(context),
      _buildHealthTab(context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PulsePlan'),
        actions: [
          IconButton(
            tooltip: 'Tema claro/oscuro',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Abrir Tidal del dia',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openMusicForDay(),
          ),
          IconButton(
            tooltip: 'Nuevo mes',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                _regenerateMonth(seed: Random().nextInt(900000) + 1000),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: IndexedStack(index: _selectedTab, children: tabs),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts),
            label: 'Cuentas',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Biblioteca'),
          NavigationDestination(icon: Icon(Icons.ios_share), label: 'Exportar'),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart),
            label: 'Estado',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final summary = ExportService.buildDashboard(
      profiles: _activeProfiles,
      accounts: _accounts,
      monthStart: _selectedCycleMonth == 1
          ? PlanGenerator.nextMonthStart(_monthStart)
          : _monthStart,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Panel operativo', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        _MetricStrip(
          metrics: [
            _Metric('Perfiles', '${summary.totalProfiles}', Icons.devices),
            _Metric('Activas', '${summary.activeAccounts}', Icons.play_circle),
            _Metric('Listas', '${summary.readyAccounts}', Icons.hourglass_top),
            _Metric('Descanso', '${summary.restingAccounts}', Icons.bedtime),
            _Metric(
              'Sin asignar',
              '${summary.profilesWithoutAccount}',
              Icons.link_off,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (summary.profilesWithoutAccount > 0)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Perfiles sin cuenta asignada'),
              subtitle: Text(
                '${summary.profilesWithoutAccount} perfiles necesitan cuenta en la pestaña Cuentas.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text('Reproduciendo ahora', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.currentSlots.isEmpty)
          const Text('Ningun bloque activo en este momento.')
        else
          for (final slot in summary.currentSlots) ...[
            _ScheduleSlotCard(slot: slot, onOpen: () => _openMusicForSegment(slot.segment)),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        Text('Proximos 3 horas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.upcomingSlots.isEmpty)
          const Text('Sin bloques proximos en las siguientes 3 horas.')
        else
          for (final slot in summary.upcomingSlots) ...[
            _ScheduleSlotCard(slot: slot, onOpen: () => _openMusicForSegment(slot.segment)),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => setState(() => _selectedTab = 5),
          icon: const Icon(Icons.checklist),
          label: const Text('Ver checklist operativo'),
        ),
      ],
    );
  }

  Widget _buildPlanTab(BuildContext context) {
    final activeProfiles = _activeProfiles;
    final profile = _profile;
    final day = _day;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricStrip(
          metrics: [
            _Metric('Perfiles', '${activeProfiles.length}', Icons.devices),
            _Metric(
              'Horas/dia',
              minutesToDurationLabel(day.mainMinutes),
              Icons.schedule,
            ),
            _Metric(
              'Ciclo',
              _settings.reverseSecondMonth ? '60 dias' : '30 dias',
              Icons.sync_alt,
            ),
            _Metric(
              'Variacion',
              minutesToDurationLabel(day.variationMinutes),
              Icons.shuffle,
            ),
            _Metric(
              'Cuentas',
              '${_accounts.where((account) => account.status == AccountStatus.active).length}',
              Icons.manage_accounts,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Mes 1'),
              icon: Icon(Icons.looks_one),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Mes 2'),
              icon: Icon(Icons.repeat),
            ),
          ],
          selected: {_selectedCycleMonth},
          onSelectionChanged: _settings.reverseSecondMonth
              ? (value) => setState(() => _selectedCycleMonth = value.first)
              : null,
        ),
        const SizedBox(height: 18),
        Text('Perfiles', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < activeProfiles.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(activeProfiles[index].colorValue),
                    ),
                    label: Text(activeProfiles[index].name),
                    selected: index == _selectedProfile,
                    onSelected: (_) => setState(() => _selectedProfile = index),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Dias del mes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profile.days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = profile.days[index];
              return ChoiceChip(
                label: Text('Dia ${item.day.toString().padLeft(2, '0')}'),
                selected: index == _selectedDay,
                onSelected: (_) => setState(() => _selectedDay = index),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _DayHeader(
          profile: profile,
          day: day,
          accountLabel: _accountForProfile(profile.id)?.label ?? 'Sin cuenta',
          locked: _selectedCycleMonth == 1,
          onAdd: _selectedCycleMonth == 0 ? () => _openSegmentDialog() : null,
        ),
        const SizedBox(height: 12),
        for (final segment in day.segments) ...[
          _SegmentCard(
            segment: segment,
            color: _kindColor(context, segment.kind),
            onOpenTidal: () => _openMusicForSegment(segment),
            onEdit: _selectedCycleMonth == 0
                ? () => _openSegmentDialog(segment: segment)
                : null,
            onDelete: _selectedCycleMonth == 0
                ? () => _removeSegment(segment)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAccountsTab(BuildContext context) {
    final activeProfiles = _activeProfiles;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cuentas manuales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton.filled(
              tooltip: 'Agregar cuenta',
              onPressed: () => _openAccountDialog(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricStrip(
          metrics: [
            _Metric('Total', '${_accounts.length}', Icons.account_circle),
            _Metric(
              'Activas',
              '${_accounts.where((account) => account.status == AccountStatus.active).length}',
              Icons.play_circle,
            ),
            _Metric(
              'Descanso',
              '${_accounts.where((account) => account.status == AccountStatus.resting).length}',
              Icons.bedtime,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Asignacion por ranura',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (final profile in activeProfiles) ...[
          _ProfileAssignmentTile(
            profile: profile,
            account: _accountForProfile(profile.id),
            accounts: _accounts,
            onChanged: (accountId) => _assignAccount(profile.id, accountId),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmCloseCycle,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Cerrar ciclo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openAccountDialog(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Nueva cuenta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Inventario', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (_accounts.isEmpty)
          const Text('Agrega cuentas por etiqueta para asignarlas manualmente.')
        else
          for (final account in _accounts) ...[
            _AccountCard(
              account: account,
              assignedProfileName: _profileNameForAccount(account),
              onEdit: () => _openAccountDialog(account: account),
              onDelete: () => _confirmRemoveAccount(account),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildLibraryTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Biblioteca base',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _mainPlaylistController,
          decoration: const InputDecoration(
            labelText: 'Playlist principal',
            prefixIcon: Icon(Icons.queue_music),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _profilePrefixController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Prefijo',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _profileStartController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Inicio',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _artistsController,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: 'Artistas para bloques cortos',
            prefixIcon: Icon(Icons.person_search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _secondaryController,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: 'Playlists alternas',
            prefixIcon: Icon(Icons.library_music),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _settings.reverseSecondMonth,
          secondary: const Icon(Icons.repeat_on),
          title: const Text('Mes 2 inverso'),
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                reverseSecondMonth: value,
                cycleMonths: value ? 2 : 1,
              );
              if (!value) {
                _selectedCycleMonth = 0;
              }
            });
            unawaited(_save());
          },
        ),
        const SizedBox(height: 8),
        _SliderPanel(
          label: 'Perfiles autorizados',
          valueLabel: _profileCountDraft.round().toString(),
          child: Slider(
            value: _profileCountDraft,
            min: 1,
            max: 100,
            divisions: 99,
            label: _profileCountDraft.round().toString(),
            onChanged: (value) => setState(() => _profileCountDraft = value),
          ),
        ),
        const SizedBox(height: 14),
        _SliderPanel(
          label: 'Escucha diaria aproximada',
          valueLabel: '${_targetHoursDraft.toStringAsFixed(1)}h',
          child: Slider(
            value: _targetHoursDraft,
            min: 10,
            max: 14,
            divisions: 16,
            label: '${_targetHoursDraft.toStringAsFixed(1)}h',
            onChanged: (value) => setState(() => _targetHoursDraft = value),
          ),
        ),
        const SizedBox(height: 18),
        Text('Plantillas rapidas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final count in [10, 50, 100])
              OutlinedButton(
                onPressed: () => _applyTemplate(count),
                child: Text('$count perfiles'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _applyLibrarySettings,
                icon: const Icon(Icons.check),
                label: const Text('Aplicar'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Cambiar semilla',
              onPressed: () =>
                  _regenerateMonth(seed: Random().nextInt(900000) + 1000),
              icon: const Icon(Icons.casino),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportTab(BuildContext context) {
    final snapshotModel = PlannerSnapshot(
      settings: _settings,
      monthStart: _monthStart,
      profiles: _profiles,
      accounts: _accounts,
    );
    final snapshot = snapshotModel.toJsonString();
    final csv = ExportService.buildCsv(
      snapshot: snapshotModel,
      activeProfiles: _activeProfiles,
    );
    final ics = ExportService.buildIcs(
      snapshot: snapshotModel,
      activeProfiles: _activeProfiles,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Exportar', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _copyExport(snapshot, 'JSON copiado'),
              icon: const Icon(Icons.data_object),
              label: const Text('Copiar JSON'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _copyExport(csv, 'CSV copiado'),
              icon: const Icon(Icons.table_chart),
              label: const Text('Copiar CSV'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _copyExport(ics, 'Calendario ICS copiado'),
              icon: const Icon(Icons.event),
              label: const Text('Copiar ICS'),
            ),
            OutlinedButton.icon(
              onPressed: _importTemplate,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar plantilla'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('JSON completo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCardColor(context),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              snapshot,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTab(BuildContext context) {
    final steps = ExportService.buildOperationalChecklist(
      profile: _profile,
      day: _day,
      account: _accountForProfile(_profile.id),
      health: _health,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Estado del dispositivo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Text('Checklist operativo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final step in steps) ...[
          _OperationalStepCard(step: step),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openMusicForDay(),
          icon: const Icon(Icons.open_in_new),
          label: Text('Abrir Tidal: ${_day.segments.first.title}'),
        ),
        const SizedBox(height: 18),
        for (final item in _health.entries) ...[
          SwitchListTile(
            value: item.value,
            secondary: Icon(
              item.value ? Icons.check_circle : Icons.error_outline,
            ),
            title: Text(item.key),
            onChanged: (value) {
              setState(() => _health[item.key] = value);
              _markEvent('${item.key}: ${value ? 'OK' : 'revisar'}');
              unawaited(_save());
            },
          ),
          const Divider(height: 1),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _markEvent('Reproduccion activa'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Activa'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _markEvent('Pausa detectada'),
                icon: const Icon(Icons.pause),
                label: const Text('Pausa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Registro', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (_healthLog.isEmpty)
          const Text('Sin eventos registrados')
        else
          for (final event in _healthLog.take(12))
            ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text(event),
            ),
      ],
    );
  }

  Future<void> _openAccountDialog({MusicAccount? account}) async {
    var status = account?.status ?? AccountStatus.ready;
    final labelController = TextEditingController(text: account?.label ?? '');
    final noteController = TextEditingController(text: account?.note ?? '');

    final result = await showDialog<MusicAccount>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account == null ? 'Nueva cuenta' : 'Editar cuenta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Etiqueta de cuenta',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AccountStatus>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: AccountStatus.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Nota',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    if (label.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      MusicAccount(
                        id:
                            account?.id ??
                            'account_${DateTime.now().microsecondsSinceEpoch}',
                        label: label,
                        status: status,
                        assignedProfileId: account?.assignedProfileId,
                        note: noteController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    noteController.dispose();
    if (result == null) {
      return;
    }

    setState(() {
      final index = _accounts.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _accounts = [..._accounts, result];
      } else {
        final updated = [..._accounts];
        updated[index] = result;
        _accounts = updated;
      }
    });
    unawaited(_save());
  }

  Future<void> _confirmRemoveAccount(MusicAccount account) async {
    final isAssigned = account.assignedProfileId != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Eliminar la cuenta "${account.label}"?'
          '${isAssigned ? '\n\nEsta cuenta está asignada actualmente.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeAccount(account);
    }
  }

  void _removeAccount(MusicAccount account) {
    setState(() {
      _accounts = _accounts.where((item) => item.id != account.id).toList();
    });
    unawaited(_save());
  }

  Future<void> _openSegmentDialog({ListeningSegment? segment}) async {
    var kind = segment?.kind ?? SegmentKind.artistFocus;
    var start = TimeOfDay(
      hour:
          ((segment?.startMinute ?? _day.segments.first.startMinute) ~/ 60) %
          24,
      minute: (segment?.startMinute ?? _day.segments.first.startMinute) % 60,
    );
    var duration = (segment?.durationMinutes ?? 30)
        .toDouble()
        .clamp(15, 180)
        .toDouble();
    final titleController = TextEditingController(
      text: segment?.title ?? _suggestTitle(kind),
    );

    final result = await showDialog<ListeningSegment>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(segment == null ? 'Nuevo bloque' : 'Editar bloque'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<SegmentKind>(
                      initialValue: kind,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: SegmentKind.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          kind = value;
                          titleController.text = _suggestTitle(value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Hora de inicio'),
                      trailing: Text(start.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: start,
                        );
                        if (picked != null) {
                          setDialogState(() => start = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _SliderPanel(
                      label: 'Duracion',
                      valueLabel: minutesToDurationLabel(duration.round()),
                      child: Slider(
                        value: duration,
                        min: 15,
                        max: 180,
                        divisions: 33,
                        label: minutesToDurationLabel(duration.round()),
                        onChanged: (value) =>
                            setDialogState(() => duration = value),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ListeningSegment(
                        id:
                            segment?.id ??
                            'custom_${DateTime.now().microsecondsSinceEpoch}',
                        kind: kind,
                        title: titleController.text.trim().isEmpty
                            ? _suggestTitle(kind)
                            : titleController.text.trim(),
                        startMinute: start.hour * 60 + start.minute,
                        durationMinutes: duration.round(),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    if (result == null) {
      return;
    }

    final current = _day;
    final updatedSegments = [...current.segments];
    final index = updatedSegments.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      updatedSegments.add(result);
    } else {
      updatedSegments[index] = result;
    }
    updatedSegments.sort(
      (left, right) => left.startMinute.compareTo(right.startMinute),
    );
    _replaceCurrentDay(current.copyWith(segments: updatedSegments));
  }

  void _removeSegment(ListeningSegment segment) {
    final current = _day;
    if (current.segments.length == 1) {
      _showSnack('El dia necesita al menos un bloque');
      return;
    }
    _replaceCurrentDay(
      current.copyWith(
        segments: current.segments
            .where((item) => item.id != segment.id)
            .toList(),
      ),
    );
  }

  void _replaceCurrentDay(DayPlan updatedDay) {
    if (_selectedCycleMonth == 1) {
      _showSnack('Edita el mes 1; el mes 2 se refleja automaticamente');
      return;
    }
    final profile = _profile;
    final days = [...profile.days];
    days[_safeIndex(_selectedDay, days.length)] = updatedDay;
    final profiles = [..._profiles];
    profiles[_safeIndex(_selectedProfile, profiles.length)] = profile.copyWith(
      days: days,
    );
    setState(() => _profiles = profiles);
    unawaited(_save());
  }

  String _suggestTitle(SegmentKind kind) {
    switch (kind) {
      case SegmentKind.mainPlaylist:
        return _settings.mainPlaylist;
      case SegmentKind.artistFocus:
        return _settings.artists.isEmpty
            ? 'Artista favorito'
            : _settings.artists.first;
      case SegmentKind.secondaryPlaylist:
        return _settings.secondaryPlaylists.isEmpty
            ? 'Playlist alterna'
            : _settings.secondaryPlaylists.first;
      case SegmentKind.discovery:
        return _settings.secondaryPlaylists.length > 1
            ? _settings.secondaryPlaylists[1]
            : 'Descubrimiento';
    }
  }

  Future<void> _copyExport(String content, String message) async {
    await Clipboard.setData(ClipboardData(text: content));
    _showSnack(message);
  }

  Future<void> _importTemplate() async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar plantilla'),
          content: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'JSON de plantilla o configuracion',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );

    if (accepted != true) {
      controller.dispose();
      return;
    }

    final settings = ExportService.parseTemplateSettings(controller.text.trim());
    controller.dispose();
    if (settings == null) {
      _showSnack('Plantilla invalida');
      return;
    }

    setState(() {
      _settings = settings;
      _syncControllers();
    });
    _showSnack('Plantilla importada; pulsa Aplicar para regenerar');
  }

  void _applyTemplate(int profileCount) {
    setState(() {
      _profileCountDraft = profileCount.toDouble();
      _settings = _settings.copyWith(profileCount: profileCount);
    });
    _showSnack('Plantilla de $profileCount perfiles lista; pulsa Aplicar');
  }

  Future<void> _openMusicForDay() async {
    final segment = _day.segments.firstWhere(
      (item) => item.kind == SegmentKind.mainPlaylist,
      orElse: () => _day.segments.first,
    );
    await _openMusicForSegment(segment);
  }

  Future<void> _openMusicForSegment(ListeningSegment segment) async {
    final url = ExportService.tidalUrlForSegment(segment);
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnack('No se pudo abrir Tidal');
      return;
    }
    _markEvent('Tidal abierto: ${segment.title}');
  }

  void _markEvent(String message) {
    final now = TimeOfDay.now();
    setState(() {
      _healthLog.insert(0, '${now.format(context)} - $message');
      if (_healthLog.length > 30) {
        _healthLog.removeLast();
      }
    });
    unawaited(_save());
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadHealthState() async {
    final prefs = await SharedPreferences.getInstance();
    final healthRaw = prefs.getString(_healthKey);
    if (healthRaw != null) {
      try {
        final map = jsonDecode(healthRaw) as Map<String, dynamic>;
        for (final entry in map.entries) {
          if (_health.containsKey(entry.key)) {
            _health[entry.key] = entry.value as bool;
          }
        }
      } catch (_) {}
    }
    final logRaw = prefs.getString(_healthLogKey);
    if (logRaw != null) {
      try {
        final list = (jsonDecode(logRaw) as List).cast<String>();
        _healthLog
          ..clear()
          ..addAll(list.take(30));
      } catch (_) {}
    }
  }

  Future<void> _saveHealthState(SharedPreferences prefs) async {
    await prefs.setString(_healthKey, jsonEncode(_health));
    await prefs.setString(_healthLogKey, jsonEncode(_healthLog));
  }

  Color _kindColor(BuildContext context, SegmentKind kind) {
    final scheme = Theme.of(context).colorScheme;
    switch (kind) {
      case SegmentKind.mainPlaylist:
        return scheme.primary;
      case SegmentKind.artistFocus:
        return scheme.tertiary;
      case SegmentKind.secondaryPlaylist:
        return scheme.secondary;
      case SegmentKind.discovery:
        return const Color(0xff4d7c0f);
    }
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final metric in metrics)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCardColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(metric.icon, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.label,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            metric.value,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileAssignmentTile extends StatelessWidget {
  const _ProfileAssignmentTile({
    required this.profile,
    required this.account,
    required this.accounts,
    required this.onChanged,
  });

  final ListeningProfile profile;
  final MusicAccount? account;
  final List<MusicAccount> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final availableAccounts = accounts
        .where(
          (item) =>
              item.status != AccountStatus.resting || item.id == account?.id,
        )
        .toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(
                profile.colorValue,
              ).withValues(alpha: 0.14),
              foregroundColor: Color(profile.colorValue),
              child: const Icon(Icons.phone_android),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    account?.status.label ?? 'Sin cuenta',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 156,
              child: DropdownButtonFormField<String>(
                initialValue: account?.id ?? 'none',
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'none',
                    child: Text('Sin cuenta'),
                  ),
                  for (final item in availableAccounts)
                    DropdownMenuItem(value: item.id, child: Text(item.label)),
                ],
                onChanged: (value) => onChanged(value == 'none' ? null : value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.assignedProfileName,
    required this.onEdit,
    required this.onDelete,
  });

  final MusicAccount account;
  final String assignedProfileName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (account.status) {
      AccountStatus.active => Theme.of(context).colorScheme.primary,
      AccountStatus.ready => Theme.of(context).colorScheme.secondary,
      AccountStatus.resting => Theme.of(context).colorScheme.outline,
    };

    return Card(
      color: AppTheme.surfaceCardColor(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: const Icon(Icons.account_circle),
        ),
        title: Text(
          account.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${account.status.label} - $assignedProfileName'),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: 'Quitar',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.profile,
    required this.day,
    required this.accountLabel,
    required this.locked,
    required this.onAdd,
  });

  final ListeningProfile profile;
  final DayPlan day;
  final String accountLabel;
  final bool locked;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(profile.colorValue).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(profile.colorValue).withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name} / Dia ${day.day}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Principal ${minutesToDurationLabel(day.mainMinutes)} - total ${minutesToDurationLabel(day.totalMinutes)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (locked)
              const Tooltip(
                message: 'Mes inverso',
                child: Icon(Icons.lock_clock),
              )
            else
              IconButton.filled(
                tooltip: 'Agregar bloque',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.segment,
    required this.color,
    required this.onOpenTidal,
    required this.onEdit,
    required this.onDelete,
  });

  final ListeningSegment segment;
  final Color color;
  final VoidCallback onOpenTidal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceCardColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: Icon(_iconForKind(segment.kind)),
        ),
        title: Text(
          segment.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${segment.kind.label} - ${minutesToClock(segment.startMinute)} a '
          '${minutesToClock(segment.endMinute)} - ${minutesToDurationLabel(segment.durationMinutes)}',
        ),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Abrir en Tidal',
              onPressed: onOpenTidal,
              icon: const Icon(Icons.open_in_new),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: 'Quitar',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForKind(SegmentKind kind) {
    switch (kind) {
      case SegmentKind.mainPlaylist:
        return Icons.queue_music;
      case SegmentKind.artistFocus:
        return Icons.person_search;
      case SegmentKind.secondaryPlaylist:
        return Icons.library_music;
      case SegmentKind.discovery:
        return Icons.explore;
    }
  }
}

class _SliderPanel extends StatelessWidget {
  const _SliderPanel({
    required this.label,
    required this.valueLabel,
    required this.child,
  });

  final String label;
  final String valueLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(valueLabel, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScheduleSlotCard extends StatelessWidget {
  const _ScheduleSlotCard({required this.slot, required this.onOpen});

  final ScheduleSlot slot;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final status = slot.isActiveNow
        ? 'Ahora'
        : 'En ${slot.minutesUntilStart} min';
    return Card(
      color: AppTheme.surfaceCardColor(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(slot.profile.colorValue).withValues(alpha: 0.14),
          foregroundColor: Color(slot.profile.colorValue),
          child: const Icon(Icons.schedule),
        ),
        title: Text('${slot.profile.name} - ${slot.segment.title}'),
        subtitle: Text(
          '$status | ${slot.accountLabel} | '
          '${minutesToClock(slot.segment.startMinute)} - '
          '${minutesToClock(slot.segment.endMinute)}',
        ),
        trailing: IconButton(
          tooltip: 'Abrir en Tidal',
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new),
        ),
      ),
    );
  }
}

class _OperationalStepCard extends StatelessWidget {
  const _OperationalStepCard({required this.step});

  final OperationalStep step;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceCardColor(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: step.completed
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text('${step.order}'),
        ),
        title: Text(step.title),
        subtitle: Text(step.detail),
        trailing: Icon(
          step.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: step.completed
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

int _safeIndex(int index, int length) {
  if (length <= 0) {
    return 0;
  }
  return index.clamp(0, length - 1);
}
