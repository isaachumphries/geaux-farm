// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfileTableTable extends UserProfileTable
    with TableInfo<$UserProfileTableTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _admin1Meta = const VerificationMeta('admin1');
  @override
  late final GeneratedColumn<String> admin1 = GeneratedColumn<String>(
    'admin1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postcodeMeta = const VerificationMeta(
    'postcode',
  );
  @override
  late final GeneratedColumn<String> postcode = GeneratedColumn<String>(
    'postcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<Goal>, String> goals =
      GeneratedColumn<String>(
        'goals',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<Goal>>($UserProfileTableTable.$convertergoals);
  static const VerificationMeta _goalOtherTextMeta = const VerificationMeta(
    'goalOtherText',
  );
  @override
  late final GeneratedColumn<String> goalOtherText = GeneratedColumn<String>(
    'goal_other_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Experience, String> experience =
      GeneratedColumn<String>(
        'experience',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Experience>($UserProfileTableTable.$converterexperience);
  @override
  late final GeneratedColumnWithTypeConverter<HeardFrom?, String> heardFrom =
      GeneratedColumn<String>(
        'heard_from',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<HeardFrom?>($UserProfileTableTable.$converterheardFromn);
  static const VerificationMeta _heardOtherTextMeta = const VerificationMeta(
    'heardOtherText',
  );
  @override
  late final GeneratedColumn<String> heardOtherText = GeneratedColumn<String>(
    'heard_other_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Availability, String>
  availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Availability>($UserProfileTableTable.$converteravailability);
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
    'units',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notificationPermissionAskedMeta =
      const VerificationMeta('notificationPermissionAsked');
  @override
  late final GeneratedColumn<bool> notificationPermissionAsked =
      GeneratedColumn<bool>(
        'notification_permission_asked',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_permission_asked" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _firstPlantPromptDismissedMeta =
      const VerificationMeta('firstPlantPromptDismissed');
  @override
  late final GeneratedColumn<bool> firstPlantPromptDismissed =
      GeneratedColumn<bool>(
        'first_plant_prompt_dismissed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("first_plant_prompt_dismissed" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _onboardingCompletedAtMeta =
      const VerificationMeta('onboardingCompletedAt');
  @override
  late final GeneratedColumn<DateTime> onboardingCompletedAt =
      GeneratedColumn<DateTime>(
        'onboarding_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    city,
    admin1,
    countryCode,
    postcode,
    lat,
    lon,
    timezone,
    goals,
    goalOtherText,
    experience,
    heardFrom,
    heardOtherText,
    availability,
    units,
    notificationsEnabled,
    notificationPermissionAsked,
    firstPlantPromptDismissed,
    onboardingCompletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('admin1')) {
      context.handle(
        _admin1Meta,
        admin1.isAcceptableOrUnknown(data['admin1']!, _admin1Meta),
      );
    } else if (isInserting) {
      context.missing(_admin1Meta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countryCodeMeta);
    }
    if (data.containsKey('postcode')) {
      context.handle(
        _postcodeMeta,
        postcode.isAcceptableOrUnknown(data['postcode']!, _postcodeMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('goal_other_text')) {
      context.handle(
        _goalOtherTextMeta,
        goalOtherText.isAcceptableOrUnknown(
          data['goal_other_text']!,
          _goalOtherTextMeta,
        ),
      );
    }
    if (data.containsKey('heard_other_text')) {
      context.handle(
        _heardOtherTextMeta,
        heardOtherText.isAcceptableOrUnknown(
          data['heard_other_text']!,
          _heardOtherTextMeta,
        ),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    } else if (isInserting) {
      context.missing(_unitsMeta);
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notification_permission_asked')) {
      context.handle(
        _notificationPermissionAskedMeta,
        notificationPermissionAsked.isAcceptableOrUnknown(
          data['notification_permission_asked']!,
          _notificationPermissionAskedMeta,
        ),
      );
    }
    if (data.containsKey('first_plant_prompt_dismissed')) {
      context.handle(
        _firstPlantPromptDismissedMeta,
        firstPlantPromptDismissed.isAcceptableOrUnknown(
          data['first_plant_prompt_dismissed']!,
          _firstPlantPromptDismissedMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed_at')) {
      context.handle(
        _onboardingCompletedAtMeta,
        onboardingCompletedAt.isAcceptableOrUnknown(
          data['onboarding_completed_at']!,
          _onboardingCompletedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      admin1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin1'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      postcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}postcode'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      goals: $UserProfileTableTable.$convertergoals.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}goals'],
        )!,
      ),
      goalOtherText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_other_text'],
      ),
      experience: $UserProfileTableTable.$converterexperience.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}experience'],
        )!,
      ),
      heardFrom: $UserProfileTableTable.$converterheardFromn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}heard_from'],
        ),
      ),
      heardOtherText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heard_other_text'],
      ),
      availability: $UserProfileTableTable.$converteravailability.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}availability'],
        )!,
      ),
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}units'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      notificationPermissionAsked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_permission_asked'],
      )!,
      firstPlantPromptDismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}first_plant_prompt_dismissed'],
      )!,
      onboardingCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}onboarding_completed_at'],
      ),
    );
  }

  @override
  $UserProfileTableTable createAlias(String alias) {
    return $UserProfileTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<Goal>, String> $convertergoals =
      const GoalsConverter();
  static JsonTypeConverter2<Experience, String, String> $converterexperience =
      const EnumNameConverter<Experience>(Experience.values);
  static JsonTypeConverter2<HeardFrom, String, String> $converterheardFrom =
      const EnumNameConverter<HeardFrom>(HeardFrom.values);
  static JsonTypeConverter2<HeardFrom?, String?, String?> $converterheardFromn =
      JsonTypeConverter2.asNullable($converterheardFrom);
  static TypeConverter<Availability, String> $converteravailability =
      const AvailabilityConverter();
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final String city;
  final String admin1;
  final String countryCode;
  final String? postcode;
  final double lat;
  final double lon;
  final String timezone;
  final List<Goal> goals;
  final String? goalOtherText;
  final Experience experience;
  final HeardFrom? heardFrom;
  final String? heardOtherText;
  final Availability availability;
  final String units;
  final bool notificationsEnabled;
  final bool notificationPermissionAsked;
  final bool firstPlantPromptDismissed;
  final DateTime? onboardingCompletedAt;
  const UserProfileRow({
    required this.id,
    required this.city,
    required this.admin1,
    required this.countryCode,
    this.postcode,
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.goals,
    this.goalOtherText,
    required this.experience,
    this.heardFrom,
    this.heardOtherText,
    required this.availability,
    required this.units,
    required this.notificationsEnabled,
    required this.notificationPermissionAsked,
    required this.firstPlantPromptDismissed,
    this.onboardingCompletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['city'] = Variable<String>(city);
    map['admin1'] = Variable<String>(admin1);
    map['country_code'] = Variable<String>(countryCode);
    if (!nullToAbsent || postcode != null) {
      map['postcode'] = Variable<String>(postcode);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['timezone'] = Variable<String>(timezone);
    {
      map['goals'] = Variable<String>(
        $UserProfileTableTable.$convertergoals.toSql(goals),
      );
    }
    if (!nullToAbsent || goalOtherText != null) {
      map['goal_other_text'] = Variable<String>(goalOtherText);
    }
    {
      map['experience'] = Variable<String>(
        $UserProfileTableTable.$converterexperience.toSql(experience),
      );
    }
    if (!nullToAbsent || heardFrom != null) {
      map['heard_from'] = Variable<String>(
        $UserProfileTableTable.$converterheardFromn.toSql(heardFrom),
      );
    }
    if (!nullToAbsent || heardOtherText != null) {
      map['heard_other_text'] = Variable<String>(heardOtherText);
    }
    {
      map['availability'] = Variable<String>(
        $UserProfileTableTable.$converteravailability.toSql(availability),
      );
    }
    map['units'] = Variable<String>(units);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['notification_permission_asked'] = Variable<bool>(
      notificationPermissionAsked,
    );
    map['first_plant_prompt_dismissed'] = Variable<bool>(
      firstPlantPromptDismissed,
    );
    if (!nullToAbsent || onboardingCompletedAt != null) {
      map['onboarding_completed_at'] = Variable<DateTime>(
        onboardingCompletedAt,
      );
    }
    return map;
  }

  UserProfileTableCompanion toCompanion(bool nullToAbsent) {
    return UserProfileTableCompanion(
      id: Value(id),
      city: Value(city),
      admin1: Value(admin1),
      countryCode: Value(countryCode),
      postcode: postcode == null && nullToAbsent
          ? const Value.absent()
          : Value(postcode),
      lat: Value(lat),
      lon: Value(lon),
      timezone: Value(timezone),
      goals: Value(goals),
      goalOtherText: goalOtherText == null && nullToAbsent
          ? const Value.absent()
          : Value(goalOtherText),
      experience: Value(experience),
      heardFrom: heardFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(heardFrom),
      heardOtherText: heardOtherText == null && nullToAbsent
          ? const Value.absent()
          : Value(heardOtherText),
      availability: Value(availability),
      units: Value(units),
      notificationsEnabled: Value(notificationsEnabled),
      notificationPermissionAsked: Value(notificationPermissionAsked),
      firstPlantPromptDismissed: Value(firstPlantPromptDismissed),
      onboardingCompletedAt: onboardingCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(onboardingCompletedAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      city: serializer.fromJson<String>(json['city']),
      admin1: serializer.fromJson<String>(json['admin1']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      postcode: serializer.fromJson<String?>(json['postcode']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      timezone: serializer.fromJson<String>(json['timezone']),
      goals: serializer.fromJson<List<Goal>>(json['goals']),
      goalOtherText: serializer.fromJson<String?>(json['goalOtherText']),
      experience: $UserProfileTableTable.$converterexperience.fromJson(
        serializer.fromJson<String>(json['experience']),
      ),
      heardFrom: $UserProfileTableTable.$converterheardFromn.fromJson(
        serializer.fromJson<String?>(json['heardFrom']),
      ),
      heardOtherText: serializer.fromJson<String?>(json['heardOtherText']),
      availability: serializer.fromJson<Availability>(json['availability']),
      units: serializer.fromJson<String>(json['units']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      notificationPermissionAsked: serializer.fromJson<bool>(
        json['notificationPermissionAsked'],
      ),
      firstPlantPromptDismissed: serializer.fromJson<bool>(
        json['firstPlantPromptDismissed'],
      ),
      onboardingCompletedAt: serializer.fromJson<DateTime?>(
        json['onboardingCompletedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'city': serializer.toJson<String>(city),
      'admin1': serializer.toJson<String>(admin1),
      'countryCode': serializer.toJson<String>(countryCode),
      'postcode': serializer.toJson<String?>(postcode),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'timezone': serializer.toJson<String>(timezone),
      'goals': serializer.toJson<List<Goal>>(goals),
      'goalOtherText': serializer.toJson<String?>(goalOtherText),
      'experience': serializer.toJson<String>(
        $UserProfileTableTable.$converterexperience.toJson(experience),
      ),
      'heardFrom': serializer.toJson<String?>(
        $UserProfileTableTable.$converterheardFromn.toJson(heardFrom),
      ),
      'heardOtherText': serializer.toJson<String?>(heardOtherText),
      'availability': serializer.toJson<Availability>(availability),
      'units': serializer.toJson<String>(units),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'notificationPermissionAsked': serializer.toJson<bool>(
        notificationPermissionAsked,
      ),
      'firstPlantPromptDismissed': serializer.toJson<bool>(
        firstPlantPromptDismissed,
      ),
      'onboardingCompletedAt': serializer.toJson<DateTime?>(
        onboardingCompletedAt,
      ),
    };
  }

  UserProfileRow copyWith({
    int? id,
    String? city,
    String? admin1,
    String? countryCode,
    Value<String?> postcode = const Value.absent(),
    double? lat,
    double? lon,
    String? timezone,
    List<Goal>? goals,
    Value<String?> goalOtherText = const Value.absent(),
    Experience? experience,
    Value<HeardFrom?> heardFrom = const Value.absent(),
    Value<String?> heardOtherText = const Value.absent(),
    Availability? availability,
    String? units,
    bool? notificationsEnabled,
    bool? notificationPermissionAsked,
    bool? firstPlantPromptDismissed,
    Value<DateTime?> onboardingCompletedAt = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    city: city ?? this.city,
    admin1: admin1 ?? this.admin1,
    countryCode: countryCode ?? this.countryCode,
    postcode: postcode.present ? postcode.value : this.postcode,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    timezone: timezone ?? this.timezone,
    goals: goals ?? this.goals,
    goalOtherText: goalOtherText.present
        ? goalOtherText.value
        : this.goalOtherText,
    experience: experience ?? this.experience,
    heardFrom: heardFrom.present ? heardFrom.value : this.heardFrom,
    heardOtherText: heardOtherText.present
        ? heardOtherText.value
        : this.heardOtherText,
    availability: availability ?? this.availability,
    units: units ?? this.units,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    notificationPermissionAsked:
        notificationPermissionAsked ?? this.notificationPermissionAsked,
    firstPlantPromptDismissed:
        firstPlantPromptDismissed ?? this.firstPlantPromptDismissed,
    onboardingCompletedAt: onboardingCompletedAt.present
        ? onboardingCompletedAt.value
        : this.onboardingCompletedAt,
  );
  UserProfileRow copyWithCompanion(UserProfileTableCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      city: data.city.present ? data.city.value : this.city,
      admin1: data.admin1.present ? data.admin1.value : this.admin1,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      postcode: data.postcode.present ? data.postcode.value : this.postcode,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      goals: data.goals.present ? data.goals.value : this.goals,
      goalOtherText: data.goalOtherText.present
          ? data.goalOtherText.value
          : this.goalOtherText,
      experience: data.experience.present
          ? data.experience.value
          : this.experience,
      heardFrom: data.heardFrom.present ? data.heardFrom.value : this.heardFrom,
      heardOtherText: data.heardOtherText.present
          ? data.heardOtherText.value
          : this.heardOtherText,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      units: data.units.present ? data.units.value : this.units,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      notificationPermissionAsked: data.notificationPermissionAsked.present
          ? data.notificationPermissionAsked.value
          : this.notificationPermissionAsked,
      firstPlantPromptDismissed: data.firstPlantPromptDismissed.present
          ? data.firstPlantPromptDismissed.value
          : this.firstPlantPromptDismissed,
      onboardingCompletedAt: data.onboardingCompletedAt.present
          ? data.onboardingCompletedAt.value
          : this.onboardingCompletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('city: $city, ')
          ..write('admin1: $admin1, ')
          ..write('countryCode: $countryCode, ')
          ..write('postcode: $postcode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('timezone: $timezone, ')
          ..write('goals: $goals, ')
          ..write('goalOtherText: $goalOtherText, ')
          ..write('experience: $experience, ')
          ..write('heardFrom: $heardFrom, ')
          ..write('heardOtherText: $heardOtherText, ')
          ..write('availability: $availability, ')
          ..write('units: $units, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('notificationPermissionAsked: $notificationPermissionAsked, ')
          ..write('firstPlantPromptDismissed: $firstPlantPromptDismissed, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    city,
    admin1,
    countryCode,
    postcode,
    lat,
    lon,
    timezone,
    goals,
    goalOtherText,
    experience,
    heardFrom,
    heardOtherText,
    availability,
    units,
    notificationsEnabled,
    notificationPermissionAsked,
    firstPlantPromptDismissed,
    onboardingCompletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.city == this.city &&
          other.admin1 == this.admin1 &&
          other.countryCode == this.countryCode &&
          other.postcode == this.postcode &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.timezone == this.timezone &&
          other.goals == this.goals &&
          other.goalOtherText == this.goalOtherText &&
          other.experience == this.experience &&
          other.heardFrom == this.heardFrom &&
          other.heardOtherText == this.heardOtherText &&
          other.availability == this.availability &&
          other.units == this.units &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.notificationPermissionAsked ==
              this.notificationPermissionAsked &&
          other.firstPlantPromptDismissed == this.firstPlantPromptDismissed &&
          other.onboardingCompletedAt == this.onboardingCompletedAt);
}

class UserProfileTableCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<String> city;
  final Value<String> admin1;
  final Value<String> countryCode;
  final Value<String?> postcode;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> timezone;
  final Value<List<Goal>> goals;
  final Value<String?> goalOtherText;
  final Value<Experience> experience;
  final Value<HeardFrom?> heardFrom;
  final Value<String?> heardOtherText;
  final Value<Availability> availability;
  final Value<String> units;
  final Value<bool> notificationsEnabled;
  final Value<bool> notificationPermissionAsked;
  final Value<bool> firstPlantPromptDismissed;
  final Value<DateTime?> onboardingCompletedAt;
  const UserProfileTableCompanion({
    this.id = const Value.absent(),
    this.city = const Value.absent(),
    this.admin1 = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.postcode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.timezone = const Value.absent(),
    this.goals = const Value.absent(),
    this.goalOtherText = const Value.absent(),
    this.experience = const Value.absent(),
    this.heardFrom = const Value.absent(),
    this.heardOtherText = const Value.absent(),
    this.availability = const Value.absent(),
    this.units = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.notificationPermissionAsked = const Value.absent(),
    this.firstPlantPromptDismissed = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
  });
  UserProfileTableCompanion.insert({
    this.id = const Value.absent(),
    required String city,
    required String admin1,
    required String countryCode,
    this.postcode = const Value.absent(),
    required double lat,
    required double lon,
    required String timezone,
    required List<Goal> goals,
    this.goalOtherText = const Value.absent(),
    required Experience experience,
    this.heardFrom = const Value.absent(),
    this.heardOtherText = const Value.absent(),
    required Availability availability,
    required String units,
    this.notificationsEnabled = const Value.absent(),
    this.notificationPermissionAsked = const Value.absent(),
    this.firstPlantPromptDismissed = const Value.absent(),
    this.onboardingCompletedAt = const Value.absent(),
  }) : city = Value(city),
       admin1 = Value(admin1),
       countryCode = Value(countryCode),
       lat = Value(lat),
       lon = Value(lon),
       timezone = Value(timezone),
       goals = Value(goals),
       experience = Value(experience),
       availability = Value(availability),
       units = Value(units);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<String>? city,
    Expression<String>? admin1,
    Expression<String>? countryCode,
    Expression<String>? postcode,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? timezone,
    Expression<String>? goals,
    Expression<String>? goalOtherText,
    Expression<String>? experience,
    Expression<String>? heardFrom,
    Expression<String>? heardOtherText,
    Expression<String>? availability,
    Expression<String>? units,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? notificationPermissionAsked,
    Expression<bool>? firstPlantPromptDismissed,
    Expression<DateTime>? onboardingCompletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (city != null) 'city': city,
      if (admin1 != null) 'admin1': admin1,
      if (countryCode != null) 'country_code': countryCode,
      if (postcode != null) 'postcode': postcode,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (timezone != null) 'timezone': timezone,
      if (goals != null) 'goals': goals,
      if (goalOtherText != null) 'goal_other_text': goalOtherText,
      if (experience != null) 'experience': experience,
      if (heardFrom != null) 'heard_from': heardFrom,
      if (heardOtherText != null) 'heard_other_text': heardOtherText,
      if (availability != null) 'availability': availability,
      if (units != null) 'units': units,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (notificationPermissionAsked != null)
        'notification_permission_asked': notificationPermissionAsked,
      if (firstPlantPromptDismissed != null)
        'first_plant_prompt_dismissed': firstPlantPromptDismissed,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt,
    });
  }

  UserProfileTableCompanion copyWith({
    Value<int>? id,
    Value<String>? city,
    Value<String>? admin1,
    Value<String>? countryCode,
    Value<String?>? postcode,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? timezone,
    Value<List<Goal>>? goals,
    Value<String?>? goalOtherText,
    Value<Experience>? experience,
    Value<HeardFrom?>? heardFrom,
    Value<String?>? heardOtherText,
    Value<Availability>? availability,
    Value<String>? units,
    Value<bool>? notificationsEnabled,
    Value<bool>? notificationPermissionAsked,
    Value<bool>? firstPlantPromptDismissed,
    Value<DateTime?>? onboardingCompletedAt,
  }) {
    return UserProfileTableCompanion(
      id: id ?? this.id,
      city: city ?? this.city,
      admin1: admin1 ?? this.admin1,
      countryCode: countryCode ?? this.countryCode,
      postcode: postcode ?? this.postcode,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      timezone: timezone ?? this.timezone,
      goals: goals ?? this.goals,
      goalOtherText: goalOtherText ?? this.goalOtherText,
      experience: experience ?? this.experience,
      heardFrom: heardFrom ?? this.heardFrom,
      heardOtherText: heardOtherText ?? this.heardOtherText,
      availability: availability ?? this.availability,
      units: units ?? this.units,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPermissionAsked:
          notificationPermissionAsked ?? this.notificationPermissionAsked,
      firstPlantPromptDismissed:
          firstPlantPromptDismissed ?? this.firstPlantPromptDismissed,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (admin1.present) {
      map['admin1'] = Variable<String>(admin1.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (postcode.present) {
      map['postcode'] = Variable<String>(postcode.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (goals.present) {
      map['goals'] = Variable<String>(
        $UserProfileTableTable.$convertergoals.toSql(goals.value),
      );
    }
    if (goalOtherText.present) {
      map['goal_other_text'] = Variable<String>(goalOtherText.value);
    }
    if (experience.present) {
      map['experience'] = Variable<String>(
        $UserProfileTableTable.$converterexperience.toSql(experience.value),
      );
    }
    if (heardFrom.present) {
      map['heard_from'] = Variable<String>(
        $UserProfileTableTable.$converterheardFromn.toSql(heardFrom.value),
      );
    }
    if (heardOtherText.present) {
      map['heard_other_text'] = Variable<String>(heardOtherText.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(
        $UserProfileTableTable.$converteravailability.toSql(availability.value),
      );
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (notificationPermissionAsked.present) {
      map['notification_permission_asked'] = Variable<bool>(
        notificationPermissionAsked.value,
      );
    }
    if (firstPlantPromptDismissed.present) {
      map['first_plant_prompt_dismissed'] = Variable<bool>(
        firstPlantPromptDismissed.value,
      );
    }
    if (onboardingCompletedAt.present) {
      map['onboarding_completed_at'] = Variable<DateTime>(
        onboardingCompletedAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileTableCompanion(')
          ..write('id: $id, ')
          ..write('city: $city, ')
          ..write('admin1: $admin1, ')
          ..write('countryCode: $countryCode, ')
          ..write('postcode: $postcode, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('timezone: $timezone, ')
          ..write('goals: $goals, ')
          ..write('goalOtherText: $goalOtherText, ')
          ..write('experience: $experience, ')
          ..write('heardFrom: $heardFrom, ')
          ..write('heardOtherText: $heardOtherText, ')
          ..write('availability: $availability, ')
          ..write('units: $units, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('notificationPermissionAsked: $notificationPermissionAsked, ')
          ..write('firstPlantPromptDismissed: $firstPlantPromptDismissed, ')
          ..write('onboardingCompletedAt: $onboardingCompletedAt')
          ..write(')'))
        .toString();
  }
}

class $SpacesTableTable extends SpacesTable
    with TableInfo<$SpacesTableTable, SpaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpacesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SpaceType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SpaceType>($SpacesTableTable.$convertertype);
  static const VerificationMeta _areaSqFtMeta = const VerificationMeta(
    'areaSqFt',
  );
  @override
  late final GeneratedColumn<int> areaSqFt = GeneratedColumn<int>(
    'area_sq_ft',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SunLevel, String> sun =
      GeneratedColumn<String>(
        'sun',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SunLevel>($SpacesTableTable.$convertersun);
  static const VerificationMeta _sunUnsureMeta = const VerificationMeta(
    'sunUnsure',
  );
  @override
  late final GeneratedColumn<bool> sunUnsure = GeneratedColumn<bool>(
    'sun_unsure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sun_unsure" IN (0, 1))',
    ),
  );
  static const VerificationMeta _rainExposedMeta = const VerificationMeta(
    'rainExposed',
  );
  @override
  late final GeneratedColumn<bool> rainExposed = GeneratedColumn<bool>(
    'rain_exposed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rain_exposed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _inContainerDefaultMeta =
      const VerificationMeta('inContainerDefault');
  @override
  late final GeneratedColumn<bool> inContainerDefault = GeneratedColumn<bool>(
    'in_container_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_container_default" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    areaSqFt,
    sun,
    sunUnsure,
    rainExposed,
    inContainerDefault,
    isPrimary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('area_sq_ft')) {
      context.handle(
        _areaSqFtMeta,
        areaSqFt.isAcceptableOrUnknown(data['area_sq_ft']!, _areaSqFtMeta),
      );
    } else if (isInserting) {
      context.missing(_areaSqFtMeta);
    }
    if (data.containsKey('sun_unsure')) {
      context.handle(
        _sunUnsureMeta,
        sunUnsure.isAcceptableOrUnknown(data['sun_unsure']!, _sunUnsureMeta),
      );
    } else if (isInserting) {
      context.missing(_sunUnsureMeta);
    }
    if (data.containsKey('rain_exposed')) {
      context.handle(
        _rainExposedMeta,
        rainExposed.isAcceptableOrUnknown(
          data['rain_exposed']!,
          _rainExposedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rainExposedMeta);
    }
    if (data.containsKey('in_container_default')) {
      context.handle(
        _inContainerDefaultMeta,
        inContainerDefault.isAcceptableOrUnknown(
          data['in_container_default']!,
          _inContainerDefaultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inContainerDefaultMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    } else if (isInserting) {
      context.missing(_isPrimaryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $SpacesTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      areaSqFt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_sq_ft'],
      )!,
      sun: $SpacesTableTable.$convertersun.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sun'],
        )!,
      ),
      sunUnsure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sun_unsure'],
      )!,
      rainExposed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rain_exposed'],
      )!,
      inContainerDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_container_default'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
    );
  }

  @override
  $SpacesTableTable createAlias(String alias) {
    return $SpacesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SpaceType, String, String> $convertertype =
      const EnumNameConverter<SpaceType>(SpaceType.values);
  static JsonTypeConverter2<SunLevel, String, String> $convertersun =
      const EnumNameConverter<SunLevel>(SunLevel.values);
}

class SpaceRow extends DataClass implements Insertable<SpaceRow> {
  final String id;
  final SpaceType type;
  final int areaSqFt;
  final SunLevel sun;
  final bool sunUnsure;
  final bool rainExposed;
  final bool inContainerDefault;
  final bool isPrimary;
  const SpaceRow({
    required this.id,
    required this.type,
    required this.areaSqFt,
    required this.sun,
    required this.sunUnsure,
    required this.rainExposed,
    required this.inContainerDefault,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $SpacesTableTable.$convertertype.toSql(type),
      );
    }
    map['area_sq_ft'] = Variable<int>(areaSqFt);
    {
      map['sun'] = Variable<String>($SpacesTableTable.$convertersun.toSql(sun));
    }
    map['sun_unsure'] = Variable<bool>(sunUnsure);
    map['rain_exposed'] = Variable<bool>(rainExposed);
    map['in_container_default'] = Variable<bool>(inContainerDefault);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  SpacesTableCompanion toCompanion(bool nullToAbsent) {
    return SpacesTableCompanion(
      id: Value(id),
      type: Value(type),
      areaSqFt: Value(areaSqFt),
      sun: Value(sun),
      sunUnsure: Value(sunUnsure),
      rainExposed: Value(rainExposed),
      inContainerDefault: Value(inContainerDefault),
      isPrimary: Value(isPrimary),
    );
  }

  factory SpaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpaceRow(
      id: serializer.fromJson<String>(json['id']),
      type: $SpacesTableTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      areaSqFt: serializer.fromJson<int>(json['areaSqFt']),
      sun: $SpacesTableTable.$convertersun.fromJson(
        serializer.fromJson<String>(json['sun']),
      ),
      sunUnsure: serializer.fromJson<bool>(json['sunUnsure']),
      rainExposed: serializer.fromJson<bool>(json['rainExposed']),
      inContainerDefault: serializer.fromJson<bool>(json['inContainerDefault']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $SpacesTableTable.$convertertype.toJson(type),
      ),
      'areaSqFt': serializer.toJson<int>(areaSqFt),
      'sun': serializer.toJson<String>(
        $SpacesTableTable.$convertersun.toJson(sun),
      ),
      'sunUnsure': serializer.toJson<bool>(sunUnsure),
      'rainExposed': serializer.toJson<bool>(rainExposed),
      'inContainerDefault': serializer.toJson<bool>(inContainerDefault),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  SpaceRow copyWith({
    String? id,
    SpaceType? type,
    int? areaSqFt,
    SunLevel? sun,
    bool? sunUnsure,
    bool? rainExposed,
    bool? inContainerDefault,
    bool? isPrimary,
  }) => SpaceRow(
    id: id ?? this.id,
    type: type ?? this.type,
    areaSqFt: areaSqFt ?? this.areaSqFt,
    sun: sun ?? this.sun,
    sunUnsure: sunUnsure ?? this.sunUnsure,
    rainExposed: rainExposed ?? this.rainExposed,
    inContainerDefault: inContainerDefault ?? this.inContainerDefault,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  SpaceRow copyWithCompanion(SpacesTableCompanion data) {
    return SpaceRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      areaSqFt: data.areaSqFt.present ? data.areaSqFt.value : this.areaSqFt,
      sun: data.sun.present ? data.sun.value : this.sun,
      sunUnsure: data.sunUnsure.present ? data.sunUnsure.value : this.sunUnsure,
      rainExposed: data.rainExposed.present
          ? data.rainExposed.value
          : this.rainExposed,
      inContainerDefault: data.inContainerDefault.present
          ? data.inContainerDefault.value
          : this.inContainerDefault,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpaceRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('areaSqFt: $areaSqFt, ')
          ..write('sun: $sun, ')
          ..write('sunUnsure: $sunUnsure, ')
          ..write('rainExposed: $rainExposed, ')
          ..write('inContainerDefault: $inContainerDefault, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    areaSqFt,
    sun,
    sunUnsure,
    rainExposed,
    inContainerDefault,
    isPrimary,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpaceRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.areaSqFt == this.areaSqFt &&
          other.sun == this.sun &&
          other.sunUnsure == this.sunUnsure &&
          other.rainExposed == this.rainExposed &&
          other.inContainerDefault == this.inContainerDefault &&
          other.isPrimary == this.isPrimary);
}

class SpacesTableCompanion extends UpdateCompanion<SpaceRow> {
  final Value<String> id;
  final Value<SpaceType> type;
  final Value<int> areaSqFt;
  final Value<SunLevel> sun;
  final Value<bool> sunUnsure;
  final Value<bool> rainExposed;
  final Value<bool> inContainerDefault;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const SpacesTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.areaSqFt = const Value.absent(),
    this.sun = const Value.absent(),
    this.sunUnsure = const Value.absent(),
    this.rainExposed = const Value.absent(),
    this.inContainerDefault = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpacesTableCompanion.insert({
    required String id,
    required SpaceType type,
    required int areaSqFt,
    required SunLevel sun,
    required bool sunUnsure,
    required bool rainExposed,
    required bool inContainerDefault,
    required bool isPrimary,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       areaSqFt = Value(areaSqFt),
       sun = Value(sun),
       sunUnsure = Value(sunUnsure),
       rainExposed = Value(rainExposed),
       inContainerDefault = Value(inContainerDefault),
       isPrimary = Value(isPrimary);
  static Insertable<SpaceRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? areaSqFt,
    Expression<String>? sun,
    Expression<bool>? sunUnsure,
    Expression<bool>? rainExposed,
    Expression<bool>? inContainerDefault,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (areaSqFt != null) 'area_sq_ft': areaSqFt,
      if (sun != null) 'sun': sun,
      if (sunUnsure != null) 'sun_unsure': sunUnsure,
      if (rainExposed != null) 'rain_exposed': rainExposed,
      if (inContainerDefault != null)
        'in_container_default': inContainerDefault,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpacesTableCompanion copyWith({
    Value<String>? id,
    Value<SpaceType>? type,
    Value<int>? areaSqFt,
    Value<SunLevel>? sun,
    Value<bool>? sunUnsure,
    Value<bool>? rainExposed,
    Value<bool>? inContainerDefault,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return SpacesTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      sun: sun ?? this.sun,
      sunUnsure: sunUnsure ?? this.sunUnsure,
      rainExposed: rainExposed ?? this.rainExposed,
      inContainerDefault: inContainerDefault ?? this.inContainerDefault,
      isPrimary: isPrimary ?? this.isPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SpacesTableTable.$convertertype.toSql(type.value),
      );
    }
    if (areaSqFt.present) {
      map['area_sq_ft'] = Variable<int>(areaSqFt.value);
    }
    if (sun.present) {
      map['sun'] = Variable<String>(
        $SpacesTableTable.$convertersun.toSql(sun.value),
      );
    }
    if (sunUnsure.present) {
      map['sun_unsure'] = Variable<bool>(sunUnsure.value);
    }
    if (rainExposed.present) {
      map['rain_exposed'] = Variable<bool>(rainExposed.value);
    }
    if (inContainerDefault.present) {
      map['in_container_default'] = Variable<bool>(inContainerDefault.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpacesTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('areaSqFt: $areaSqFt, ')
          ..write('sun: $sun, ')
          ..write('sunUnsure: $sunUnsure, ')
          ..write('rainExposed: $rainExposed, ')
          ..write('inContainerDefault: $inContainerDefault, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClimateMonthsTableTable extends ClimateMonthsTable
    with TableInfo<$ClimateMonthsTableTable, ClimateMonthRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClimateMonthsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgLowFMeta = const VerificationMeta(
    'avgLowF',
  );
  @override
  late final GeneratedColumn<double> avgLowF = GeneratedColumn<double>(
    'avg_low_f',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgHighFMeta = const VerificationMeta(
    'avgHighF',
  );
  @override
  late final GeneratedColumn<double> avgHighF = GeneratedColumn<double>(
    'avg_high_f',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precipInMeta = const VerificationMeta(
    'precipIn',
  );
  @override
  late final GeneratedColumn<double> precipIn = GeneratedColumn<double>(
    'precip_in',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rhPctMeta = const VerificationMeta('rhPct');
  @override
  late final GeneratedColumn<double> rhPct = GeneratedColumn<double>(
    'rh_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudPctMeta = const VerificationMeta(
    'cloudPct',
  );
  @override
  late final GeneratedColumn<double> cloudPct = GeneratedColumn<double>(
    'cloud_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sunshineHoursMeta = const VerificationMeta(
    'sunshineHours',
  );
  @override
  late final GeneratedColumn<double> sunshineHours = GeneratedColumn<double>(
    'sunshine_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    month,
    avgLowF,
    avgHighF,
    precipIn,
    rhPct,
    cloudPct,
    sunshineHours,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'climate_months';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClimateMonthRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('avg_low_f')) {
      context.handle(
        _avgLowFMeta,
        avgLowF.isAcceptableOrUnknown(data['avg_low_f']!, _avgLowFMeta),
      );
    } else if (isInserting) {
      context.missing(_avgLowFMeta);
    }
    if (data.containsKey('avg_high_f')) {
      context.handle(
        _avgHighFMeta,
        avgHighF.isAcceptableOrUnknown(data['avg_high_f']!, _avgHighFMeta),
      );
    } else if (isInserting) {
      context.missing(_avgHighFMeta);
    }
    if (data.containsKey('precip_in')) {
      context.handle(
        _precipInMeta,
        precipIn.isAcceptableOrUnknown(data['precip_in']!, _precipInMeta),
      );
    } else if (isInserting) {
      context.missing(_precipInMeta);
    }
    if (data.containsKey('rh_pct')) {
      context.handle(
        _rhPctMeta,
        rhPct.isAcceptableOrUnknown(data['rh_pct']!, _rhPctMeta),
      );
    } else if (isInserting) {
      context.missing(_rhPctMeta);
    }
    if (data.containsKey('cloud_pct')) {
      context.handle(
        _cloudPctMeta,
        cloudPct.isAcceptableOrUnknown(data['cloud_pct']!, _cloudPctMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudPctMeta);
    }
    if (data.containsKey('sunshine_hours')) {
      context.handle(
        _sunshineHoursMeta,
        sunshineHours.isAcceptableOrUnknown(
          data['sunshine_hours']!,
          _sunshineHoursMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sunshineHoursMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  ClimateMonthRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClimateMonthRow(
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      avgLowF: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_low_f'],
      )!,
      avgHighF: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_high_f'],
      )!,
      precipIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precip_in'],
      )!,
      rhPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rh_pct'],
      )!,
      cloudPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cloud_pct'],
      )!,
      sunshineHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sunshine_hours'],
      )!,
    );
  }

  @override
  $ClimateMonthsTableTable createAlias(String alias) {
    return $ClimateMonthsTableTable(attachedDatabase, alias);
  }
}

class ClimateMonthRow extends DataClass implements Insertable<ClimateMonthRow> {
  final int month;
  final double avgLowF;
  final double avgHighF;
  final double precipIn;
  final double rhPct;
  final double cloudPct;
  final double sunshineHours;
  const ClimateMonthRow({
    required this.month,
    required this.avgLowF,
    required this.avgHighF,
    required this.precipIn,
    required this.rhPct,
    required this.cloudPct,
    required this.sunshineHours,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<int>(month);
    map['avg_low_f'] = Variable<double>(avgLowF);
    map['avg_high_f'] = Variable<double>(avgHighF);
    map['precip_in'] = Variable<double>(precipIn);
    map['rh_pct'] = Variable<double>(rhPct);
    map['cloud_pct'] = Variable<double>(cloudPct);
    map['sunshine_hours'] = Variable<double>(sunshineHours);
    return map;
  }

  ClimateMonthsTableCompanion toCompanion(bool nullToAbsent) {
    return ClimateMonthsTableCompanion(
      month: Value(month),
      avgLowF: Value(avgLowF),
      avgHighF: Value(avgHighF),
      precipIn: Value(precipIn),
      rhPct: Value(rhPct),
      cloudPct: Value(cloudPct),
      sunshineHours: Value(sunshineHours),
    );
  }

  factory ClimateMonthRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClimateMonthRow(
      month: serializer.fromJson<int>(json['month']),
      avgLowF: serializer.fromJson<double>(json['avgLowF']),
      avgHighF: serializer.fromJson<double>(json['avgHighF']),
      precipIn: serializer.fromJson<double>(json['precipIn']),
      rhPct: serializer.fromJson<double>(json['rhPct']),
      cloudPct: serializer.fromJson<double>(json['cloudPct']),
      sunshineHours: serializer.fromJson<double>(json['sunshineHours']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<int>(month),
      'avgLowF': serializer.toJson<double>(avgLowF),
      'avgHighF': serializer.toJson<double>(avgHighF),
      'precipIn': serializer.toJson<double>(precipIn),
      'rhPct': serializer.toJson<double>(rhPct),
      'cloudPct': serializer.toJson<double>(cloudPct),
      'sunshineHours': serializer.toJson<double>(sunshineHours),
    };
  }

  ClimateMonthRow copyWith({
    int? month,
    double? avgLowF,
    double? avgHighF,
    double? precipIn,
    double? rhPct,
    double? cloudPct,
    double? sunshineHours,
  }) => ClimateMonthRow(
    month: month ?? this.month,
    avgLowF: avgLowF ?? this.avgLowF,
    avgHighF: avgHighF ?? this.avgHighF,
    precipIn: precipIn ?? this.precipIn,
    rhPct: rhPct ?? this.rhPct,
    cloudPct: cloudPct ?? this.cloudPct,
    sunshineHours: sunshineHours ?? this.sunshineHours,
  );
  ClimateMonthRow copyWithCompanion(ClimateMonthsTableCompanion data) {
    return ClimateMonthRow(
      month: data.month.present ? data.month.value : this.month,
      avgLowF: data.avgLowF.present ? data.avgLowF.value : this.avgLowF,
      avgHighF: data.avgHighF.present ? data.avgHighF.value : this.avgHighF,
      precipIn: data.precipIn.present ? data.precipIn.value : this.precipIn,
      rhPct: data.rhPct.present ? data.rhPct.value : this.rhPct,
      cloudPct: data.cloudPct.present ? data.cloudPct.value : this.cloudPct,
      sunshineHours: data.sunshineHours.present
          ? data.sunshineHours.value
          : this.sunshineHours,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClimateMonthRow(')
          ..write('month: $month, ')
          ..write('avgLowF: $avgLowF, ')
          ..write('avgHighF: $avgHighF, ')
          ..write('precipIn: $precipIn, ')
          ..write('rhPct: $rhPct, ')
          ..write('cloudPct: $cloudPct, ')
          ..write('sunshineHours: $sunshineHours')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    month,
    avgLowF,
    avgHighF,
    precipIn,
    rhPct,
    cloudPct,
    sunshineHours,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClimateMonthRow &&
          other.month == this.month &&
          other.avgLowF == this.avgLowF &&
          other.avgHighF == this.avgHighF &&
          other.precipIn == this.precipIn &&
          other.rhPct == this.rhPct &&
          other.cloudPct == this.cloudPct &&
          other.sunshineHours == this.sunshineHours);
}

class ClimateMonthsTableCompanion extends UpdateCompanion<ClimateMonthRow> {
  final Value<int> month;
  final Value<double> avgLowF;
  final Value<double> avgHighF;
  final Value<double> precipIn;
  final Value<double> rhPct;
  final Value<double> cloudPct;
  final Value<double> sunshineHours;
  const ClimateMonthsTableCompanion({
    this.month = const Value.absent(),
    this.avgLowF = const Value.absent(),
    this.avgHighF = const Value.absent(),
    this.precipIn = const Value.absent(),
    this.rhPct = const Value.absent(),
    this.cloudPct = const Value.absent(),
    this.sunshineHours = const Value.absent(),
  });
  ClimateMonthsTableCompanion.insert({
    this.month = const Value.absent(),
    required double avgLowF,
    required double avgHighF,
    required double precipIn,
    required double rhPct,
    required double cloudPct,
    required double sunshineHours,
  }) : avgLowF = Value(avgLowF),
       avgHighF = Value(avgHighF),
       precipIn = Value(precipIn),
       rhPct = Value(rhPct),
       cloudPct = Value(cloudPct),
       sunshineHours = Value(sunshineHours);
  static Insertable<ClimateMonthRow> custom({
    Expression<int>? month,
    Expression<double>? avgLowF,
    Expression<double>? avgHighF,
    Expression<double>? precipIn,
    Expression<double>? rhPct,
    Expression<double>? cloudPct,
    Expression<double>? sunshineHours,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (avgLowF != null) 'avg_low_f': avgLowF,
      if (avgHighF != null) 'avg_high_f': avgHighF,
      if (precipIn != null) 'precip_in': precipIn,
      if (rhPct != null) 'rh_pct': rhPct,
      if (cloudPct != null) 'cloud_pct': cloudPct,
      if (sunshineHours != null) 'sunshine_hours': sunshineHours,
    });
  }

  ClimateMonthsTableCompanion copyWith({
    Value<int>? month,
    Value<double>? avgLowF,
    Value<double>? avgHighF,
    Value<double>? precipIn,
    Value<double>? rhPct,
    Value<double>? cloudPct,
    Value<double>? sunshineHours,
  }) {
    return ClimateMonthsTableCompanion(
      month: month ?? this.month,
      avgLowF: avgLowF ?? this.avgLowF,
      avgHighF: avgHighF ?? this.avgHighF,
      precipIn: precipIn ?? this.precipIn,
      rhPct: rhPct ?? this.rhPct,
      cloudPct: cloudPct ?? this.cloudPct,
      sunshineHours: sunshineHours ?? this.sunshineHours,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (avgLowF.present) {
      map['avg_low_f'] = Variable<double>(avgLowF.value);
    }
    if (avgHighF.present) {
      map['avg_high_f'] = Variable<double>(avgHighF.value);
    }
    if (precipIn.present) {
      map['precip_in'] = Variable<double>(precipIn.value);
    }
    if (rhPct.present) {
      map['rh_pct'] = Variable<double>(rhPct.value);
    }
    if (cloudPct.present) {
      map['cloud_pct'] = Variable<double>(cloudPct.value);
    }
    if (sunshineHours.present) {
      map['sunshine_hours'] = Variable<double>(sunshineHours.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClimateMonthsTableCompanion(')
          ..write('month: $month, ')
          ..write('avgLowF: $avgLowF, ')
          ..write('avgHighF: $avgHighF, ')
          ..write('precipIn: $precipIn, ')
          ..write('rhPct: $rhPct, ')
          ..write('cloudPct: $cloudPct, ')
          ..write('sunshineHours: $sunshineHours')
          ..write(')'))
        .toString();
  }
}

class $ClimateMetaTableTable extends ClimateMetaTable
    with TableInfo<$ClimateMetaTableTable, ClimateMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClimateMetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _annualExtremeMinFMeta = const VerificationMeta(
    'annualExtremeMinF',
  );
  @override
  late final GeneratedColumn<double> annualExtremeMinF =
      GeneratedColumn<double>(
        'annual_extreme_min_f',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _annualPrecipInMeta = const VerificationMeta(
    'annualPrecipIn',
  );
  @override
  late final GeneratedColumn<double> annualPrecipIn = GeneratedColumn<double>(
    'annual_precip_in',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualRhPctMeta = const VerificationMeta(
    'annualRhPct',
  );
  @override
  late final GeneratedColumn<double> annualRhPct = GeneratedColumn<double>(
    'annual_rh_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<String> zone = GeneratedColumn<String>(
    'zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ZoneSource, String> zoneSource =
      GeneratedColumn<String>(
        'zone_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ZoneSource>($ClimateMetaTableTable.$converterzoneSource);
  static const VerificationMeta _lastSpringFrostDoyMeta =
      const VerificationMeta('lastSpringFrostDoy');
  @override
  late final GeneratedColumn<int> lastSpringFrostDoy = GeneratedColumn<int>(
    'last_spring_frost_doy',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstFallFrostDoyMeta = const VerificationMeta(
    'firstFallFrostDoy',
  );
  @override
  late final GeneratedColumn<int> firstFallFrostDoy = GeneratedColumn<int>(
    'first_fall_frost_doy',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    annualExtremeMinF,
    annualPrecipIn,
    annualRhPct,
    zone,
    zoneSource,
    lastSpringFrostDoy,
    firstFallFrostDoy,
    lat,
    lon,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'climate_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClimateMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('annual_extreme_min_f')) {
      context.handle(
        _annualExtremeMinFMeta,
        annualExtremeMinF.isAcceptableOrUnknown(
          data['annual_extreme_min_f']!,
          _annualExtremeMinFMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualExtremeMinFMeta);
    }
    if (data.containsKey('annual_precip_in')) {
      context.handle(
        _annualPrecipInMeta,
        annualPrecipIn.isAcceptableOrUnknown(
          data['annual_precip_in']!,
          _annualPrecipInMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualPrecipInMeta);
    }
    if (data.containsKey('annual_rh_pct')) {
      context.handle(
        _annualRhPctMeta,
        annualRhPct.isAcceptableOrUnknown(
          data['annual_rh_pct']!,
          _annualRhPctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualRhPctMeta);
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneMeta);
    }
    if (data.containsKey('last_spring_frost_doy')) {
      context.handle(
        _lastSpringFrostDoyMeta,
        lastSpringFrostDoy.isAcceptableOrUnknown(
          data['last_spring_frost_doy']!,
          _lastSpringFrostDoyMeta,
        ),
      );
    }
    if (data.containsKey('first_fall_frost_doy')) {
      context.handle(
        _firstFallFrostDoyMeta,
        firstFallFrostDoy.isAcceptableOrUnknown(
          data['first_fall_frost_doy']!,
          _firstFallFrostDoyMeta,
        ),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClimateMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClimateMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      annualExtremeMinF: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_extreme_min_f'],
      )!,
      annualPrecipIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_precip_in'],
      )!,
      annualRhPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}annual_rh_pct'],
      )!,
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone'],
      )!,
      zoneSource: $ClimateMetaTableTable.$converterzoneSource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}zone_source'],
        )!,
      ),
      lastSpringFrostDoy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_spring_frost_doy'],
      ),
      firstFallFrostDoy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_fall_frost_doy'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $ClimateMetaTableTable createAlias(String alias) {
    return $ClimateMetaTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ZoneSource, String, String> $converterzoneSource =
      const EnumNameConverter<ZoneSource>(ZoneSource.values);
}

class ClimateMetaRow extends DataClass implements Insertable<ClimateMetaRow> {
  final int id;
  final double annualExtremeMinF;
  final double annualPrecipIn;
  final double annualRhPct;
  final String zone;
  final ZoneSource zoneSource;
  final int? lastSpringFrostDoy;
  final int? firstFallFrostDoy;
  final double lat;
  final double lon;
  final DateTime computedAt;
  const ClimateMetaRow({
    required this.id,
    required this.annualExtremeMinF,
    required this.annualPrecipIn,
    required this.annualRhPct,
    required this.zone,
    required this.zoneSource,
    this.lastSpringFrostDoy,
    this.firstFallFrostDoy,
    required this.lat,
    required this.lon,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['annual_extreme_min_f'] = Variable<double>(annualExtremeMinF);
    map['annual_precip_in'] = Variable<double>(annualPrecipIn);
    map['annual_rh_pct'] = Variable<double>(annualRhPct);
    map['zone'] = Variable<String>(zone);
    {
      map['zone_source'] = Variable<String>(
        $ClimateMetaTableTable.$converterzoneSource.toSql(zoneSource),
      );
    }
    if (!nullToAbsent || lastSpringFrostDoy != null) {
      map['last_spring_frost_doy'] = Variable<int>(lastSpringFrostDoy);
    }
    if (!nullToAbsent || firstFallFrostDoy != null) {
      map['first_fall_frost_doy'] = Variable<int>(firstFallFrostDoy);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  ClimateMetaTableCompanion toCompanion(bool nullToAbsent) {
    return ClimateMetaTableCompanion(
      id: Value(id),
      annualExtremeMinF: Value(annualExtremeMinF),
      annualPrecipIn: Value(annualPrecipIn),
      annualRhPct: Value(annualRhPct),
      zone: Value(zone),
      zoneSource: Value(zoneSource),
      lastSpringFrostDoy: lastSpringFrostDoy == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSpringFrostDoy),
      firstFallFrostDoy: firstFallFrostDoy == null && nullToAbsent
          ? const Value.absent()
          : Value(firstFallFrostDoy),
      lat: Value(lat),
      lon: Value(lon),
      computedAt: Value(computedAt),
    );
  }

  factory ClimateMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClimateMetaRow(
      id: serializer.fromJson<int>(json['id']),
      annualExtremeMinF: serializer.fromJson<double>(json['annualExtremeMinF']),
      annualPrecipIn: serializer.fromJson<double>(json['annualPrecipIn']),
      annualRhPct: serializer.fromJson<double>(json['annualRhPct']),
      zone: serializer.fromJson<String>(json['zone']),
      zoneSource: $ClimateMetaTableTable.$converterzoneSource.fromJson(
        serializer.fromJson<String>(json['zoneSource']),
      ),
      lastSpringFrostDoy: serializer.fromJson<int?>(json['lastSpringFrostDoy']),
      firstFallFrostDoy: serializer.fromJson<int?>(json['firstFallFrostDoy']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'annualExtremeMinF': serializer.toJson<double>(annualExtremeMinF),
      'annualPrecipIn': serializer.toJson<double>(annualPrecipIn),
      'annualRhPct': serializer.toJson<double>(annualRhPct),
      'zone': serializer.toJson<String>(zone),
      'zoneSource': serializer.toJson<String>(
        $ClimateMetaTableTable.$converterzoneSource.toJson(zoneSource),
      ),
      'lastSpringFrostDoy': serializer.toJson<int?>(lastSpringFrostDoy),
      'firstFallFrostDoy': serializer.toJson<int?>(firstFallFrostDoy),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  ClimateMetaRow copyWith({
    int? id,
    double? annualExtremeMinF,
    double? annualPrecipIn,
    double? annualRhPct,
    String? zone,
    ZoneSource? zoneSource,
    Value<int?> lastSpringFrostDoy = const Value.absent(),
    Value<int?> firstFallFrostDoy = const Value.absent(),
    double? lat,
    double? lon,
    DateTime? computedAt,
  }) => ClimateMetaRow(
    id: id ?? this.id,
    annualExtremeMinF: annualExtremeMinF ?? this.annualExtremeMinF,
    annualPrecipIn: annualPrecipIn ?? this.annualPrecipIn,
    annualRhPct: annualRhPct ?? this.annualRhPct,
    zone: zone ?? this.zone,
    zoneSource: zoneSource ?? this.zoneSource,
    lastSpringFrostDoy: lastSpringFrostDoy.present
        ? lastSpringFrostDoy.value
        : this.lastSpringFrostDoy,
    firstFallFrostDoy: firstFallFrostDoy.present
        ? firstFallFrostDoy.value
        : this.firstFallFrostDoy,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    computedAt: computedAt ?? this.computedAt,
  );
  ClimateMetaRow copyWithCompanion(ClimateMetaTableCompanion data) {
    return ClimateMetaRow(
      id: data.id.present ? data.id.value : this.id,
      annualExtremeMinF: data.annualExtremeMinF.present
          ? data.annualExtremeMinF.value
          : this.annualExtremeMinF,
      annualPrecipIn: data.annualPrecipIn.present
          ? data.annualPrecipIn.value
          : this.annualPrecipIn,
      annualRhPct: data.annualRhPct.present
          ? data.annualRhPct.value
          : this.annualRhPct,
      zone: data.zone.present ? data.zone.value : this.zone,
      zoneSource: data.zoneSource.present
          ? data.zoneSource.value
          : this.zoneSource,
      lastSpringFrostDoy: data.lastSpringFrostDoy.present
          ? data.lastSpringFrostDoy.value
          : this.lastSpringFrostDoy,
      firstFallFrostDoy: data.firstFallFrostDoy.present
          ? data.firstFallFrostDoy.value
          : this.firstFallFrostDoy,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClimateMetaRow(')
          ..write('id: $id, ')
          ..write('annualExtremeMinF: $annualExtremeMinF, ')
          ..write('annualPrecipIn: $annualPrecipIn, ')
          ..write('annualRhPct: $annualRhPct, ')
          ..write('zone: $zone, ')
          ..write('zoneSource: $zoneSource, ')
          ..write('lastSpringFrostDoy: $lastSpringFrostDoy, ')
          ..write('firstFallFrostDoy: $firstFallFrostDoy, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    annualExtremeMinF,
    annualPrecipIn,
    annualRhPct,
    zone,
    zoneSource,
    lastSpringFrostDoy,
    firstFallFrostDoy,
    lat,
    lon,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClimateMetaRow &&
          other.id == this.id &&
          other.annualExtremeMinF == this.annualExtremeMinF &&
          other.annualPrecipIn == this.annualPrecipIn &&
          other.annualRhPct == this.annualRhPct &&
          other.zone == this.zone &&
          other.zoneSource == this.zoneSource &&
          other.lastSpringFrostDoy == this.lastSpringFrostDoy &&
          other.firstFallFrostDoy == this.firstFallFrostDoy &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.computedAt == this.computedAt);
}

class ClimateMetaTableCompanion extends UpdateCompanion<ClimateMetaRow> {
  final Value<int> id;
  final Value<double> annualExtremeMinF;
  final Value<double> annualPrecipIn;
  final Value<double> annualRhPct;
  final Value<String> zone;
  final Value<ZoneSource> zoneSource;
  final Value<int?> lastSpringFrostDoy;
  final Value<int?> firstFallFrostDoy;
  final Value<double> lat;
  final Value<double> lon;
  final Value<DateTime> computedAt;
  const ClimateMetaTableCompanion({
    this.id = const Value.absent(),
    this.annualExtremeMinF = const Value.absent(),
    this.annualPrecipIn = const Value.absent(),
    this.annualRhPct = const Value.absent(),
    this.zone = const Value.absent(),
    this.zoneSource = const Value.absent(),
    this.lastSpringFrostDoy = const Value.absent(),
    this.firstFallFrostDoy = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.computedAt = const Value.absent(),
  });
  ClimateMetaTableCompanion.insert({
    this.id = const Value.absent(),
    required double annualExtremeMinF,
    required double annualPrecipIn,
    required double annualRhPct,
    required String zone,
    required ZoneSource zoneSource,
    this.lastSpringFrostDoy = const Value.absent(),
    this.firstFallFrostDoy = const Value.absent(),
    required double lat,
    required double lon,
    required DateTime computedAt,
  }) : annualExtremeMinF = Value(annualExtremeMinF),
       annualPrecipIn = Value(annualPrecipIn),
       annualRhPct = Value(annualRhPct),
       zone = Value(zone),
       zoneSource = Value(zoneSource),
       lat = Value(lat),
       lon = Value(lon),
       computedAt = Value(computedAt);
  static Insertable<ClimateMetaRow> custom({
    Expression<int>? id,
    Expression<double>? annualExtremeMinF,
    Expression<double>? annualPrecipIn,
    Expression<double>? annualRhPct,
    Expression<String>? zone,
    Expression<String>? zoneSource,
    Expression<int>? lastSpringFrostDoy,
    Expression<int>? firstFallFrostDoy,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<DateTime>? computedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (annualExtremeMinF != null) 'annual_extreme_min_f': annualExtremeMinF,
      if (annualPrecipIn != null) 'annual_precip_in': annualPrecipIn,
      if (annualRhPct != null) 'annual_rh_pct': annualRhPct,
      if (zone != null) 'zone': zone,
      if (zoneSource != null) 'zone_source': zoneSource,
      if (lastSpringFrostDoy != null)
        'last_spring_frost_doy': lastSpringFrostDoy,
      if (firstFallFrostDoy != null) 'first_fall_frost_doy': firstFallFrostDoy,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (computedAt != null) 'computed_at': computedAt,
    });
  }

  ClimateMetaTableCompanion copyWith({
    Value<int>? id,
    Value<double>? annualExtremeMinF,
    Value<double>? annualPrecipIn,
    Value<double>? annualRhPct,
    Value<String>? zone,
    Value<ZoneSource>? zoneSource,
    Value<int?>? lastSpringFrostDoy,
    Value<int?>? firstFallFrostDoy,
    Value<double>? lat,
    Value<double>? lon,
    Value<DateTime>? computedAt,
  }) {
    return ClimateMetaTableCompanion(
      id: id ?? this.id,
      annualExtremeMinF: annualExtremeMinF ?? this.annualExtremeMinF,
      annualPrecipIn: annualPrecipIn ?? this.annualPrecipIn,
      annualRhPct: annualRhPct ?? this.annualRhPct,
      zone: zone ?? this.zone,
      zoneSource: zoneSource ?? this.zoneSource,
      lastSpringFrostDoy: lastSpringFrostDoy ?? this.lastSpringFrostDoy,
      firstFallFrostDoy: firstFallFrostDoy ?? this.firstFallFrostDoy,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (annualExtremeMinF.present) {
      map['annual_extreme_min_f'] = Variable<double>(annualExtremeMinF.value);
    }
    if (annualPrecipIn.present) {
      map['annual_precip_in'] = Variable<double>(annualPrecipIn.value);
    }
    if (annualRhPct.present) {
      map['annual_rh_pct'] = Variable<double>(annualRhPct.value);
    }
    if (zone.present) {
      map['zone'] = Variable<String>(zone.value);
    }
    if (zoneSource.present) {
      map['zone_source'] = Variable<String>(
        $ClimateMetaTableTable.$converterzoneSource.toSql(zoneSource.value),
      );
    }
    if (lastSpringFrostDoy.present) {
      map['last_spring_frost_doy'] = Variable<int>(lastSpringFrostDoy.value);
    }
    if (firstFallFrostDoy.present) {
      map['first_fall_frost_doy'] = Variable<int>(firstFallFrostDoy.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClimateMetaTableCompanion(')
          ..write('id: $id, ')
          ..write('annualExtremeMinF: $annualExtremeMinF, ')
          ..write('annualPrecipIn: $annualPrecipIn, ')
          ..write('annualRhPct: $annualRhPct, ')
          ..write('zone: $zone, ')
          ..write('zoneSource: $zoneSource, ')
          ..write('lastSpringFrostDoy: $lastSpringFrostDoy, ')
          ..write('firstFallFrostDoy: $firstFallFrostDoy, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherDaysTableTable extends WeatherDaysTable
    with TableInfo<$WeatherDaysTableTable, WeatherDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherDaysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weatherCodeMeta = const VerificationMeta(
    'weatherCode',
  );
  @override
  late final GeneratedColumn<int> weatherCode = GeneratedColumn<int>(
    'weather_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tmaxFMeta = const VerificationMeta('tmaxF');
  @override
  late final GeneratedColumn<double> tmaxF = GeneratedColumn<double>(
    'tmax_f',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tminFMeta = const VerificationMeta('tminF');
  @override
  late final GeneratedColumn<double> tminF = GeneratedColumn<double>(
    'tmin_f',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precipInMeta = const VerificationMeta(
    'precipIn',
  );
  @override
  late final GeneratedColumn<double> precipIn = GeneratedColumn<double>(
    'precip_in',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precipProbMeta = const VerificationMeta(
    'precipProb',
  );
  @override
  late final GeneratedColumn<int> precipProb = GeneratedColumn<int>(
    'precip_prob',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uvMaxMeta = const VerificationMeta('uvMax');
  @override
  late final GeneratedColumn<double> uvMax = GeneratedColumn<double>(
    'uv_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sunshineSMeta = const VerificationMeta(
    'sunshineS',
  );
  @override
  late final GeneratedColumn<double> sunshineS = GeneratedColumn<double>(
    'sunshine_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daylightSMeta = const VerificationMeta(
    'daylightS',
  );
  @override
  late final GeneratedColumn<double> daylightS = GeneratedColumn<double>(
    'daylight_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _et0InMeta = const VerificationMeta('et0In');
  @override
  late final GeneratedColumn<double> et0In = GeneratedColumn<double>(
    'et0_in',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sunriseMeta = const VerificationMeta(
    'sunrise',
  );
  @override
  late final GeneratedColumn<String> sunrise = GeneratedColumn<String>(
    'sunrise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sunsetMeta = const VerificationMeta('sunset');
  @override
  late final GeneratedColumn<String> sunset = GeneratedColumn<String>(
    'sunset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    weatherCode,
    tmaxF,
    tminF,
    precipIn,
    precipProb,
    uvMax,
    sunshineS,
    daylightS,
    et0In,
    sunrise,
    sunset,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weather_code')) {
      context.handle(
        _weatherCodeMeta,
        weatherCode.isAcceptableOrUnknown(
          data['weather_code']!,
          _weatherCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weatherCodeMeta);
    }
    if (data.containsKey('tmax_f')) {
      context.handle(
        _tmaxFMeta,
        tmaxF.isAcceptableOrUnknown(data['tmax_f']!, _tmaxFMeta),
      );
    } else if (isInserting) {
      context.missing(_tmaxFMeta);
    }
    if (data.containsKey('tmin_f')) {
      context.handle(
        _tminFMeta,
        tminF.isAcceptableOrUnknown(data['tmin_f']!, _tminFMeta),
      );
    } else if (isInserting) {
      context.missing(_tminFMeta);
    }
    if (data.containsKey('precip_in')) {
      context.handle(
        _precipInMeta,
        precipIn.isAcceptableOrUnknown(data['precip_in']!, _precipInMeta),
      );
    } else if (isInserting) {
      context.missing(_precipInMeta);
    }
    if (data.containsKey('precip_prob')) {
      context.handle(
        _precipProbMeta,
        precipProb.isAcceptableOrUnknown(data['precip_prob']!, _precipProbMeta),
      );
    }
    if (data.containsKey('uv_max')) {
      context.handle(
        _uvMaxMeta,
        uvMax.isAcceptableOrUnknown(data['uv_max']!, _uvMaxMeta),
      );
    }
    if (data.containsKey('sunshine_s')) {
      context.handle(
        _sunshineSMeta,
        sunshineS.isAcceptableOrUnknown(data['sunshine_s']!, _sunshineSMeta),
      );
    } else if (isInserting) {
      context.missing(_sunshineSMeta);
    }
    if (data.containsKey('daylight_s')) {
      context.handle(
        _daylightSMeta,
        daylightS.isAcceptableOrUnknown(data['daylight_s']!, _daylightSMeta),
      );
    } else if (isInserting) {
      context.missing(_daylightSMeta);
    }
    if (data.containsKey('et0_in')) {
      context.handle(
        _et0InMeta,
        et0In.isAcceptableOrUnknown(data['et0_in']!, _et0InMeta),
      );
    } else if (isInserting) {
      context.missing(_et0InMeta);
    }
    if (data.containsKey('sunrise')) {
      context.handle(
        _sunriseMeta,
        sunrise.isAcceptableOrUnknown(data['sunrise']!, _sunriseMeta),
      );
    } else if (isInserting) {
      context.missing(_sunriseMeta);
    }
    if (data.containsKey('sunset')) {
      context.handle(
        _sunsetMeta,
        sunset.isAcceptableOrUnknown(data['sunset']!, _sunsetMeta),
      );
    } else if (isInserting) {
      context.missing(_sunsetMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  WeatherDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      weatherCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weather_code'],
      )!,
      tmaxF: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tmax_f'],
      )!,
      tminF: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tmin_f'],
      )!,
      precipIn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precip_in'],
      )!,
      precipProb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precip_prob'],
      ),
      uvMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}uv_max'],
      ),
      sunshineS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sunshine_s'],
      )!,
      daylightS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daylight_s'],
      )!,
      et0In: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}et0_in'],
      )!,
      sunrise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sunrise'],
      )!,
      sunset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sunset'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $WeatherDaysTableTable createAlias(String alias) {
    return $WeatherDaysTableTable(attachedDatabase, alias);
  }
}

class WeatherDayRow extends DataClass implements Insertable<WeatherDayRow> {
  final String date;
  final int weatherCode;
  final double tmaxF;
  final double tminF;
  final double precipIn;
  final int? precipProb;
  final double? uvMax;
  final double sunshineS;
  final double daylightS;
  final double et0In;
  final String sunrise;
  final String sunset;
  final DateTime fetchedAt;
  const WeatherDayRow({
    required this.date,
    required this.weatherCode,
    required this.tmaxF,
    required this.tminF,
    required this.precipIn,
    this.precipProb,
    this.uvMax,
    required this.sunshineS,
    required this.daylightS,
    required this.et0In,
    required this.sunrise,
    required this.sunset,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['weather_code'] = Variable<int>(weatherCode);
    map['tmax_f'] = Variable<double>(tmaxF);
    map['tmin_f'] = Variable<double>(tminF);
    map['precip_in'] = Variable<double>(precipIn);
    if (!nullToAbsent || precipProb != null) {
      map['precip_prob'] = Variable<int>(precipProb);
    }
    if (!nullToAbsent || uvMax != null) {
      map['uv_max'] = Variable<double>(uvMax);
    }
    map['sunshine_s'] = Variable<double>(sunshineS);
    map['daylight_s'] = Variable<double>(daylightS);
    map['et0_in'] = Variable<double>(et0In);
    map['sunrise'] = Variable<String>(sunrise);
    map['sunset'] = Variable<String>(sunset);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  WeatherDaysTableCompanion toCompanion(bool nullToAbsent) {
    return WeatherDaysTableCompanion(
      date: Value(date),
      weatherCode: Value(weatherCode),
      tmaxF: Value(tmaxF),
      tminF: Value(tminF),
      precipIn: Value(precipIn),
      precipProb: precipProb == null && nullToAbsent
          ? const Value.absent()
          : Value(precipProb),
      uvMax: uvMax == null && nullToAbsent
          ? const Value.absent()
          : Value(uvMax),
      sunshineS: Value(sunshineS),
      daylightS: Value(daylightS),
      et0In: Value(et0In),
      sunrise: Value(sunrise),
      sunset: Value(sunset),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory WeatherDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherDayRow(
      date: serializer.fromJson<String>(json['date']),
      weatherCode: serializer.fromJson<int>(json['weatherCode']),
      tmaxF: serializer.fromJson<double>(json['tmaxF']),
      tminF: serializer.fromJson<double>(json['tminF']),
      precipIn: serializer.fromJson<double>(json['precipIn']),
      precipProb: serializer.fromJson<int?>(json['precipProb']),
      uvMax: serializer.fromJson<double?>(json['uvMax']),
      sunshineS: serializer.fromJson<double>(json['sunshineS']),
      daylightS: serializer.fromJson<double>(json['daylightS']),
      et0In: serializer.fromJson<double>(json['et0In']),
      sunrise: serializer.fromJson<String>(json['sunrise']),
      sunset: serializer.fromJson<String>(json['sunset']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'weatherCode': serializer.toJson<int>(weatherCode),
      'tmaxF': serializer.toJson<double>(tmaxF),
      'tminF': serializer.toJson<double>(tminF),
      'precipIn': serializer.toJson<double>(precipIn),
      'precipProb': serializer.toJson<int?>(precipProb),
      'uvMax': serializer.toJson<double?>(uvMax),
      'sunshineS': serializer.toJson<double>(sunshineS),
      'daylightS': serializer.toJson<double>(daylightS),
      'et0In': serializer.toJson<double>(et0In),
      'sunrise': serializer.toJson<String>(sunrise),
      'sunset': serializer.toJson<String>(sunset),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  WeatherDayRow copyWith({
    String? date,
    int? weatherCode,
    double? tmaxF,
    double? tminF,
    double? precipIn,
    Value<int?> precipProb = const Value.absent(),
    Value<double?> uvMax = const Value.absent(),
    double? sunshineS,
    double? daylightS,
    double? et0In,
    String? sunrise,
    String? sunset,
    DateTime? fetchedAt,
  }) => WeatherDayRow(
    date: date ?? this.date,
    weatherCode: weatherCode ?? this.weatherCode,
    tmaxF: tmaxF ?? this.tmaxF,
    tminF: tminF ?? this.tminF,
    precipIn: precipIn ?? this.precipIn,
    precipProb: precipProb.present ? precipProb.value : this.precipProb,
    uvMax: uvMax.present ? uvMax.value : this.uvMax,
    sunshineS: sunshineS ?? this.sunshineS,
    daylightS: daylightS ?? this.daylightS,
    et0In: et0In ?? this.et0In,
    sunrise: sunrise ?? this.sunrise,
    sunset: sunset ?? this.sunset,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  WeatherDayRow copyWithCompanion(WeatherDaysTableCompanion data) {
    return WeatherDayRow(
      date: data.date.present ? data.date.value : this.date,
      weatherCode: data.weatherCode.present
          ? data.weatherCode.value
          : this.weatherCode,
      tmaxF: data.tmaxF.present ? data.tmaxF.value : this.tmaxF,
      tminF: data.tminF.present ? data.tminF.value : this.tminF,
      precipIn: data.precipIn.present ? data.precipIn.value : this.precipIn,
      precipProb: data.precipProb.present
          ? data.precipProb.value
          : this.precipProb,
      uvMax: data.uvMax.present ? data.uvMax.value : this.uvMax,
      sunshineS: data.sunshineS.present ? data.sunshineS.value : this.sunshineS,
      daylightS: data.daylightS.present ? data.daylightS.value : this.daylightS,
      et0In: data.et0In.present ? data.et0In.value : this.et0In,
      sunrise: data.sunrise.present ? data.sunrise.value : this.sunrise,
      sunset: data.sunset.present ? data.sunset.value : this.sunset,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherDayRow(')
          ..write('date: $date, ')
          ..write('weatherCode: $weatherCode, ')
          ..write('tmaxF: $tmaxF, ')
          ..write('tminF: $tminF, ')
          ..write('precipIn: $precipIn, ')
          ..write('precipProb: $precipProb, ')
          ..write('uvMax: $uvMax, ')
          ..write('sunshineS: $sunshineS, ')
          ..write('daylightS: $daylightS, ')
          ..write('et0In: $et0In, ')
          ..write('sunrise: $sunrise, ')
          ..write('sunset: $sunset, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    weatherCode,
    tmaxF,
    tminF,
    precipIn,
    precipProb,
    uvMax,
    sunshineS,
    daylightS,
    et0In,
    sunrise,
    sunset,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherDayRow &&
          other.date == this.date &&
          other.weatherCode == this.weatherCode &&
          other.tmaxF == this.tmaxF &&
          other.tminF == this.tminF &&
          other.precipIn == this.precipIn &&
          other.precipProb == this.precipProb &&
          other.uvMax == this.uvMax &&
          other.sunshineS == this.sunshineS &&
          other.daylightS == this.daylightS &&
          other.et0In == this.et0In &&
          other.sunrise == this.sunrise &&
          other.sunset == this.sunset &&
          other.fetchedAt == this.fetchedAt);
}

class WeatherDaysTableCompanion extends UpdateCompanion<WeatherDayRow> {
  final Value<String> date;
  final Value<int> weatherCode;
  final Value<double> tmaxF;
  final Value<double> tminF;
  final Value<double> precipIn;
  final Value<int?> precipProb;
  final Value<double?> uvMax;
  final Value<double> sunshineS;
  final Value<double> daylightS;
  final Value<double> et0In;
  final Value<String> sunrise;
  final Value<String> sunset;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const WeatherDaysTableCompanion({
    this.date = const Value.absent(),
    this.weatherCode = const Value.absent(),
    this.tmaxF = const Value.absent(),
    this.tminF = const Value.absent(),
    this.precipIn = const Value.absent(),
    this.precipProb = const Value.absent(),
    this.uvMax = const Value.absent(),
    this.sunshineS = const Value.absent(),
    this.daylightS = const Value.absent(),
    this.et0In = const Value.absent(),
    this.sunrise = const Value.absent(),
    this.sunset = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeatherDaysTableCompanion.insert({
    required String date,
    required int weatherCode,
    required double tmaxF,
    required double tminF,
    required double precipIn,
    this.precipProb = const Value.absent(),
    this.uvMax = const Value.absent(),
    required double sunshineS,
    required double daylightS,
    required double et0In,
    required String sunrise,
    required String sunset,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       weatherCode = Value(weatherCode),
       tmaxF = Value(tmaxF),
       tminF = Value(tminF),
       precipIn = Value(precipIn),
       sunshineS = Value(sunshineS),
       daylightS = Value(daylightS),
       et0In = Value(et0In),
       sunrise = Value(sunrise),
       sunset = Value(sunset),
       fetchedAt = Value(fetchedAt);
  static Insertable<WeatherDayRow> custom({
    Expression<String>? date,
    Expression<int>? weatherCode,
    Expression<double>? tmaxF,
    Expression<double>? tminF,
    Expression<double>? precipIn,
    Expression<int>? precipProb,
    Expression<double>? uvMax,
    Expression<double>? sunshineS,
    Expression<double>? daylightS,
    Expression<double>? et0In,
    Expression<String>? sunrise,
    Expression<String>? sunset,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (weatherCode != null) 'weather_code': weatherCode,
      if (tmaxF != null) 'tmax_f': tmaxF,
      if (tminF != null) 'tmin_f': tminF,
      if (precipIn != null) 'precip_in': precipIn,
      if (precipProb != null) 'precip_prob': precipProb,
      if (uvMax != null) 'uv_max': uvMax,
      if (sunshineS != null) 'sunshine_s': sunshineS,
      if (daylightS != null) 'daylight_s': daylightS,
      if (et0In != null) 'et0_in': et0In,
      if (sunrise != null) 'sunrise': sunrise,
      if (sunset != null) 'sunset': sunset,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeatherDaysTableCompanion copyWith({
    Value<String>? date,
    Value<int>? weatherCode,
    Value<double>? tmaxF,
    Value<double>? tminF,
    Value<double>? precipIn,
    Value<int?>? precipProb,
    Value<double?>? uvMax,
    Value<double>? sunshineS,
    Value<double>? daylightS,
    Value<double>? et0In,
    Value<String>? sunrise,
    Value<String>? sunset,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return WeatherDaysTableCompanion(
      date: date ?? this.date,
      weatherCode: weatherCode ?? this.weatherCode,
      tmaxF: tmaxF ?? this.tmaxF,
      tminF: tminF ?? this.tminF,
      precipIn: precipIn ?? this.precipIn,
      precipProb: precipProb ?? this.precipProb,
      uvMax: uvMax ?? this.uvMax,
      sunshineS: sunshineS ?? this.sunshineS,
      daylightS: daylightS ?? this.daylightS,
      et0In: et0In ?? this.et0In,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (weatherCode.present) {
      map['weather_code'] = Variable<int>(weatherCode.value);
    }
    if (tmaxF.present) {
      map['tmax_f'] = Variable<double>(tmaxF.value);
    }
    if (tminF.present) {
      map['tmin_f'] = Variable<double>(tminF.value);
    }
    if (precipIn.present) {
      map['precip_in'] = Variable<double>(precipIn.value);
    }
    if (precipProb.present) {
      map['precip_prob'] = Variable<int>(precipProb.value);
    }
    if (uvMax.present) {
      map['uv_max'] = Variable<double>(uvMax.value);
    }
    if (sunshineS.present) {
      map['sunshine_s'] = Variable<double>(sunshineS.value);
    }
    if (daylightS.present) {
      map['daylight_s'] = Variable<double>(daylightS.value);
    }
    if (et0In.present) {
      map['et0_in'] = Variable<double>(et0In.value);
    }
    if (sunrise.present) {
      map['sunrise'] = Variable<String>(sunrise.value);
    }
    if (sunset.present) {
      map['sunset'] = Variable<String>(sunset.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherDaysTableCompanion(')
          ..write('date: $date, ')
          ..write('weatherCode: $weatherCode, ')
          ..write('tmaxF: $tmaxF, ')
          ..write('tminF: $tminF, ')
          ..write('precipIn: $precipIn, ')
          ..write('precipProb: $precipProb, ')
          ..write('uvMax: $uvMax, ')
          ..write('sunshineS: $sunshineS, ')
          ..write('daylightS: $daylightS, ')
          ..write('et0In: $et0In, ')
          ..write('sunrise: $sunrise, ')
          ..write('sunset: $sunset, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeatherCurrentTableTable extends WeatherCurrentTable
    with TableInfo<$WeatherCurrentTableTable, WeatherCurrentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCurrentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_current';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCurrentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCurrentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCurrentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $WeatherCurrentTableTable createAlias(String alias) {
    return $WeatherCurrentTableTable(attachedDatabase, alias);
  }
}

class WeatherCurrentRow extends DataClass
    implements Insertable<WeatherCurrentRow> {
  final int id;
  final String json;
  final DateTime fetchedAt;
  const WeatherCurrentRow({
    required this.id,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  WeatherCurrentTableCompanion toCompanion(bool nullToAbsent) {
    return WeatherCurrentTableCompanion(
      id: Value(id),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory WeatherCurrentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCurrentRow(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  WeatherCurrentRow copyWith({int? id, String? json, DateTime? fetchedAt}) =>
      WeatherCurrentRow(
        id: id ?? this.id,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  WeatherCurrentRow copyWithCompanion(WeatherCurrentTableCompanion data) {
    return WeatherCurrentRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCurrentRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCurrentRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class WeatherCurrentTableCompanion extends UpdateCompanion<WeatherCurrentRow> {
  final Value<int> id;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  const WeatherCurrentTableCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  WeatherCurrentTableCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    required DateTime fetchedAt,
  }) : json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<WeatherCurrentRow> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  WeatherCurrentTableCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
  }) {
    return WeatherCurrentTableCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCurrentTableCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $PlantingsTableTable extends PlantingsTable
    with TableInfo<$PlantingsTableTable, PlantingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plantIdMeta = const VerificationMeta(
    'plantId',
  );
  @override
  late final GeneratedColumn<String> plantId = GeneratedColumn<String>(
    'plant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GrowSetup, String> setup =
      GeneratedColumn<String>(
        'setup',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GrowSetup>($PlantingsTableTable.$convertersetup);
  static const VerificationMeta _inContainerMeta = const VerificationMeta(
    'inContainer',
  );
  @override
  late final GeneratedColumn<bool> inContainer = GeneratedColumn<bool>(
    'in_container',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_container" IN (0, 1))',
    ),
  );
  static const VerificationMeta _startMethodMeta = const VerificationMeta(
    'startMethod',
  );
  @override
  late final GeneratedColumn<String> startMethod = GeneratedColumn<String>(
    'start_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plantedOnMeta = const VerificationMeta(
    'plantedOn',
  );
  @override
  late final GeneratedColumn<DateTime> plantedOn = GeneratedColumn<DateTime>(
    'planted_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlantingStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlantingStatus>($PlantingsTableTable.$converterstatus);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plantId,
    spaceId,
    nickname,
    setup,
    inContainer,
    startMethod,
    plantedOn,
    status,
    projectId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plantings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plant_id')) {
      context.handle(
        _plantIdMeta,
        plantId.isAcceptableOrUnknown(data['plant_id']!, _plantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plantIdMeta);
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spaceIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('in_container')) {
      context.handle(
        _inContainerMeta,
        inContainer.isAcceptableOrUnknown(
          data['in_container']!,
          _inContainerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inContainerMeta);
    }
    if (data.containsKey('start_method')) {
      context.handle(
        _startMethodMeta,
        startMethod.isAcceptableOrUnknown(
          data['start_method']!,
          _startMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startMethodMeta);
    }
    if (data.containsKey('planted_on')) {
      context.handle(
        _plantedOnMeta,
        plantedOn.isAcceptableOrUnknown(data['planted_on']!, _plantedOnMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlantingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plant_id'],
      )!,
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      setup: $PlantingsTableTable.$convertersetup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}setup'],
        )!,
      ),
      inContainer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_container'],
      )!,
      startMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_method'],
      )!,
      plantedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}planted_on'],
      ),
      status: $PlantingsTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlantingsTableTable createAlias(String alias) {
    return $PlantingsTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GrowSetup, String, String> $convertersetup =
      const EnumNameConverter<GrowSetup>(GrowSetup.values);
  static JsonTypeConverter2<PlantingStatus, String, String> $converterstatus =
      const EnumNameConverter<PlantingStatus>(PlantingStatus.values);
}

class PlantingRow extends DataClass implements Insertable<PlantingRow> {
  final String id;
  final String plantId;
  final String spaceId;
  final String nickname;
  final GrowSetup setup;
  final bool inContainer;
  final String startMethod;
  final DateTime? plantedOn;
  final PlantingStatus status;
  final String? projectId;
  final DateTime createdAt;
  const PlantingRow({
    required this.id,
    required this.plantId,
    required this.spaceId,
    required this.nickname,
    required this.setup,
    required this.inContainer,
    required this.startMethod,
    this.plantedOn,
    required this.status,
    this.projectId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plant_id'] = Variable<String>(plantId);
    map['space_id'] = Variable<String>(spaceId);
    map['nickname'] = Variable<String>(nickname);
    {
      map['setup'] = Variable<String>(
        $PlantingsTableTable.$convertersetup.toSql(setup),
      );
    }
    map['in_container'] = Variable<bool>(inContainer);
    map['start_method'] = Variable<String>(startMethod);
    if (!nullToAbsent || plantedOn != null) {
      map['planted_on'] = Variable<DateTime>(plantedOn);
    }
    {
      map['status'] = Variable<String>(
        $PlantingsTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlantingsTableCompanion toCompanion(bool nullToAbsent) {
    return PlantingsTableCompanion(
      id: Value(id),
      plantId: Value(plantId),
      spaceId: Value(spaceId),
      nickname: Value(nickname),
      setup: Value(setup),
      inContainer: Value(inContainer),
      startMethod: Value(startMethod),
      plantedOn: plantedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(plantedOn),
      status: Value(status),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      createdAt: Value(createdAt),
    );
  }

  factory PlantingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantingRow(
      id: serializer.fromJson<String>(json['id']),
      plantId: serializer.fromJson<String>(json['plantId']),
      spaceId: serializer.fromJson<String>(json['spaceId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      setup: $PlantingsTableTable.$convertersetup.fromJson(
        serializer.fromJson<String>(json['setup']),
      ),
      inContainer: serializer.fromJson<bool>(json['inContainer']),
      startMethod: serializer.fromJson<String>(json['startMethod']),
      plantedOn: serializer.fromJson<DateTime?>(json['plantedOn']),
      status: $PlantingsTableTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      projectId: serializer.fromJson<String?>(json['projectId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plantId': serializer.toJson<String>(plantId),
      'spaceId': serializer.toJson<String>(spaceId),
      'nickname': serializer.toJson<String>(nickname),
      'setup': serializer.toJson<String>(
        $PlantingsTableTable.$convertersetup.toJson(setup),
      ),
      'inContainer': serializer.toJson<bool>(inContainer),
      'startMethod': serializer.toJson<String>(startMethod),
      'plantedOn': serializer.toJson<DateTime?>(plantedOn),
      'status': serializer.toJson<String>(
        $PlantingsTableTable.$converterstatus.toJson(status),
      ),
      'projectId': serializer.toJson<String?>(projectId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlantingRow copyWith({
    String? id,
    String? plantId,
    String? spaceId,
    String? nickname,
    GrowSetup? setup,
    bool? inContainer,
    String? startMethod,
    Value<DateTime?> plantedOn = const Value.absent(),
    PlantingStatus? status,
    Value<String?> projectId = const Value.absent(),
    DateTime? createdAt,
  }) => PlantingRow(
    id: id ?? this.id,
    plantId: plantId ?? this.plantId,
    spaceId: spaceId ?? this.spaceId,
    nickname: nickname ?? this.nickname,
    setup: setup ?? this.setup,
    inContainer: inContainer ?? this.inContainer,
    startMethod: startMethod ?? this.startMethod,
    plantedOn: plantedOn.present ? plantedOn.value : this.plantedOn,
    status: status ?? this.status,
    projectId: projectId.present ? projectId.value : this.projectId,
    createdAt: createdAt ?? this.createdAt,
  );
  PlantingRow copyWithCompanion(PlantingsTableCompanion data) {
    return PlantingRow(
      id: data.id.present ? data.id.value : this.id,
      plantId: data.plantId.present ? data.plantId.value : this.plantId,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      setup: data.setup.present ? data.setup.value : this.setup,
      inContainer: data.inContainer.present
          ? data.inContainer.value
          : this.inContainer,
      startMethod: data.startMethod.present
          ? data.startMethod.value
          : this.startMethod,
      plantedOn: data.plantedOn.present ? data.plantedOn.value : this.plantedOn,
      status: data.status.present ? data.status.value : this.status,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantingRow(')
          ..write('id: $id, ')
          ..write('plantId: $plantId, ')
          ..write('spaceId: $spaceId, ')
          ..write('nickname: $nickname, ')
          ..write('setup: $setup, ')
          ..write('inContainer: $inContainer, ')
          ..write('startMethod: $startMethod, ')
          ..write('plantedOn: $plantedOn, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plantId,
    spaceId,
    nickname,
    setup,
    inContainer,
    startMethod,
    plantedOn,
    status,
    projectId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantingRow &&
          other.id == this.id &&
          other.plantId == this.plantId &&
          other.spaceId == this.spaceId &&
          other.nickname == this.nickname &&
          other.setup == this.setup &&
          other.inContainer == this.inContainer &&
          other.startMethod == this.startMethod &&
          other.plantedOn == this.plantedOn &&
          other.status == this.status &&
          other.projectId == this.projectId &&
          other.createdAt == this.createdAt);
}

class PlantingsTableCompanion extends UpdateCompanion<PlantingRow> {
  final Value<String> id;
  final Value<String> plantId;
  final Value<String> spaceId;
  final Value<String> nickname;
  final Value<GrowSetup> setup;
  final Value<bool> inContainer;
  final Value<String> startMethod;
  final Value<DateTime?> plantedOn;
  final Value<PlantingStatus> status;
  final Value<String?> projectId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlantingsTableCompanion({
    this.id = const Value.absent(),
    this.plantId = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.setup = const Value.absent(),
    this.inContainer = const Value.absent(),
    this.startMethod = const Value.absent(),
    this.plantedOn = const Value.absent(),
    this.status = const Value.absent(),
    this.projectId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantingsTableCompanion.insert({
    required String id,
    required String plantId,
    required String spaceId,
    required String nickname,
    required GrowSetup setup,
    required bool inContainer,
    required String startMethod,
    this.plantedOn = const Value.absent(),
    required PlantingStatus status,
    this.projectId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plantId = Value(plantId),
       spaceId = Value(spaceId),
       nickname = Value(nickname),
       setup = Value(setup),
       inContainer = Value(inContainer),
       startMethod = Value(startMethod),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<PlantingRow> custom({
    Expression<String>? id,
    Expression<String>? plantId,
    Expression<String>? spaceId,
    Expression<String>? nickname,
    Expression<String>? setup,
    Expression<bool>? inContainer,
    Expression<String>? startMethod,
    Expression<DateTime>? plantedOn,
    Expression<String>? status,
    Expression<String>? projectId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plantId != null) 'plant_id': plantId,
      if (spaceId != null) 'space_id': spaceId,
      if (nickname != null) 'nickname': nickname,
      if (setup != null) 'setup': setup,
      if (inContainer != null) 'in_container': inContainer,
      if (startMethod != null) 'start_method': startMethod,
      if (plantedOn != null) 'planted_on': plantedOn,
      if (status != null) 'status': status,
      if (projectId != null) 'project_id': projectId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantingsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? plantId,
    Value<String>? spaceId,
    Value<String>? nickname,
    Value<GrowSetup>? setup,
    Value<bool>? inContainer,
    Value<String>? startMethod,
    Value<DateTime?>? plantedOn,
    Value<PlantingStatus>? status,
    Value<String?>? projectId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlantingsTableCompanion(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      spaceId: spaceId ?? this.spaceId,
      nickname: nickname ?? this.nickname,
      setup: setup ?? this.setup,
      inContainer: inContainer ?? this.inContainer,
      startMethod: startMethod ?? this.startMethod,
      plantedOn: plantedOn ?? this.plantedOn,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (plantId.present) {
      map['plant_id'] = Variable<String>(plantId.value);
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (setup.present) {
      map['setup'] = Variable<String>(
        $PlantingsTableTable.$convertersetup.toSql(setup.value),
      );
    }
    if (inContainer.present) {
      map['in_container'] = Variable<bool>(inContainer.value);
    }
    if (startMethod.present) {
      map['start_method'] = Variable<String>(startMethod.value);
    }
    if (plantedOn.present) {
      map['planted_on'] = Variable<DateTime>(plantedOn.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PlantingsTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantingsTableCompanion(')
          ..write('id: $id, ')
          ..write('plantId: $plantId, ')
          ..write('spaceId: $spaceId, ')
          ..write('nickname: $nickname, ')
          ..write('setup: $setup, ')
          ..write('inContainer: $inContainer, ')
          ..write('startMethod: $startMethod, ')
          ..write('plantedOn: $plantedOn, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CareEventsTableTable extends CareEventsTable
    with TableInfo<$CareEventsTableTable, CareEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plantingIdMeta = const VerificationMeta(
    'plantingId',
  );
  @override
  late final GeneratedColumn<String> plantingId = GeneratedColumn<String>(
    'planting_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES plantings (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CareEventType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CareEventType>($CareEventsTableTable.$convertertype);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plantingId,
    type,
    at,
    note,
    photoPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('planting_id')) {
      context.handle(
        _plantingIdMeta,
        plantingId.isAcceptableOrUnknown(data['planting_id']!, _plantingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_plantingIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plantingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planting_id'],
      )!,
      type: $CareEventsTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $CareEventsTableTable createAlias(String alias) {
    return $CareEventsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<CareEventType, String> $convertertype =
      const CareEventTypeConverter();
}

class CareEventRow extends DataClass implements Insertable<CareEventRow> {
  final String id;
  final String plantingId;
  final CareEventType type;
  final DateTime at;
  final String? note;
  final String? photoPath;
  const CareEventRow({
    required this.id,
    required this.plantingId,
    required this.type,
    required this.at,
    this.note,
    this.photoPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['planting_id'] = Variable<String>(plantingId);
    {
      map['type'] = Variable<String>(
        $CareEventsTableTable.$convertertype.toSql(type),
      );
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  CareEventsTableCompanion toCompanion(bool nullToAbsent) {
    return CareEventsTableCompanion(
      id: Value(id),
      plantingId: Value(plantingId),
      type: Value(type),
      at: Value(at),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory CareEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareEventRow(
      id: serializer.fromJson<String>(json['id']),
      plantingId: serializer.fromJson<String>(json['plantingId']),
      type: serializer.fromJson<CareEventType>(json['type']),
      at: serializer.fromJson<DateTime>(json['at']),
      note: serializer.fromJson<String?>(json['note']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plantingId': serializer.toJson<String>(plantingId),
      'type': serializer.toJson<CareEventType>(type),
      'at': serializer.toJson<DateTime>(at),
      'note': serializer.toJson<String?>(note),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  CareEventRow copyWith({
    String? id,
    String? plantingId,
    CareEventType? type,
    DateTime? at,
    Value<String?> note = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
  }) => CareEventRow(
    id: id ?? this.id,
    plantingId: plantingId ?? this.plantingId,
    type: type ?? this.type,
    at: at ?? this.at,
    note: note.present ? note.value : this.note,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
  );
  CareEventRow copyWithCompanion(CareEventsTableCompanion data) {
    return CareEventRow(
      id: data.id.present ? data.id.value : this.id,
      plantingId: data.plantingId.present
          ? data.plantingId.value
          : this.plantingId,
      type: data.type.present ? data.type.value : this.type,
      at: data.at.present ? data.at.value : this.at,
      note: data.note.present ? data.note.value : this.note,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareEventRow(')
          ..write('id: $id, ')
          ..write('plantingId: $plantingId, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plantingId, type, at, note, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareEventRow &&
          other.id == this.id &&
          other.plantingId == this.plantingId &&
          other.type == this.type &&
          other.at == this.at &&
          other.note == this.note &&
          other.photoPath == this.photoPath);
}

class CareEventsTableCompanion extends UpdateCompanion<CareEventRow> {
  final Value<String> id;
  final Value<String> plantingId;
  final Value<CareEventType> type;
  final Value<DateTime> at;
  final Value<String?> note;
  final Value<String?> photoPath;
  final Value<int> rowid;
  const CareEventsTableCompanion({
    this.id = const Value.absent(),
    this.plantingId = const Value.absent(),
    this.type = const Value.absent(),
    this.at = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareEventsTableCompanion.insert({
    required String id,
    required String plantingId,
    required CareEventType type,
    required DateTime at,
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plantingId = Value(plantingId),
       type = Value(type),
       at = Value(at);
  static Insertable<CareEventRow> custom({
    Expression<String>? id,
    Expression<String>? plantingId,
    Expression<String>? type,
    Expression<DateTime>? at,
    Expression<String>? note,
    Expression<String>? photoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plantingId != null) 'planting_id': plantingId,
      if (type != null) 'type': type,
      if (at != null) 'at': at,
      if (note != null) 'note': note,
      if (photoPath != null) 'photo_path': photoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? plantingId,
    Value<CareEventType>? type,
    Value<DateTime>? at,
    Value<String?>? note,
    Value<String?>? photoPath,
    Value<int>? rowid,
  }) {
    return CareEventsTableCompanion(
      id: id ?? this.id,
      plantingId: plantingId ?? this.plantingId,
      type: type ?? this.type,
      at: at ?? this.at,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (plantingId.present) {
      map['planting_id'] = Variable<String>(plantingId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CareEventsTableTable.$convertertype.toSql(type.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('plantingId: $plantingId, ')
          ..write('type: $type, ')
          ..write('at: $at, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GuideProjectsTableTable extends GuideProjectsTable
    with TableInfo<$GuideProjectsTableTable, GuideProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuideProjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guideIdMeta = const VerificationMeta(
    'guideId',
  );
  @override
  late final GeneratedColumn<String> guideId = GeneratedColumn<String>(
    'guide_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _materialsJsonMeta = const VerificationMeta(
    'materialsJson',
  );
  @override
  late final GeneratedColumn<String> materialsJson = GeneratedColumn<String>(
    'materials_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsJsonMeta = const VerificationMeta(
    'stepsJson',
  );
  @override
  late final GeneratedColumn<String> stepsJson = GeneratedColumn<String>(
    'steps_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    guideId,
    title,
    coverUrl,
    materialsJson,
    stepsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guide_projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<GuideProjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('guide_id')) {
      context.handle(
        _guideIdMeta,
        guideId.isAcceptableOrUnknown(data['guide_id']!, _guideIdMeta),
      );
    } else if (isInserting) {
      context.missing(_guideIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('materials_json')) {
      context.handle(
        _materialsJsonMeta,
        materialsJson.isAcceptableOrUnknown(
          data['materials_json']!,
          _materialsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_materialsJsonMeta);
    }
    if (data.containsKey('steps_json')) {
      context.handle(
        _stepsJsonMeta,
        stepsJson.isAcceptableOrUnknown(data['steps_json']!, _stepsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuideProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuideProjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      guideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guide_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      materialsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}materials_json'],
      )!,
      stepsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}steps_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GuideProjectsTableTable createAlias(String alias) {
    return $GuideProjectsTableTable(attachedDatabase, alias);
  }
}

class GuideProjectRow extends DataClass implements Insertable<GuideProjectRow> {
  final String id;
  final String guideId;
  final String title;
  final String? coverUrl;
  final String materialsJson;
  final String stepsJson;
  final DateTime createdAt;
  const GuideProjectRow({
    required this.id,
    required this.guideId,
    required this.title,
    this.coverUrl,
    required this.materialsJson,
    required this.stepsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['guide_id'] = Variable<String>(guideId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['materials_json'] = Variable<String>(materialsJson);
    map['steps_json'] = Variable<String>(stepsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GuideProjectsTableCompanion toCompanion(bool nullToAbsent) {
    return GuideProjectsTableCompanion(
      id: Value(id),
      guideId: Value(guideId),
      title: Value(title),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      materialsJson: Value(materialsJson),
      stepsJson: Value(stepsJson),
      createdAt: Value(createdAt),
    );
  }

  factory GuideProjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuideProjectRow(
      id: serializer.fromJson<String>(json['id']),
      guideId: serializer.fromJson<String>(json['guideId']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      materialsJson: serializer.fromJson<String>(json['materialsJson']),
      stepsJson: serializer.fromJson<String>(json['stepsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'guideId': serializer.toJson<String>(guideId),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'materialsJson': serializer.toJson<String>(materialsJson),
      'stepsJson': serializer.toJson<String>(stepsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GuideProjectRow copyWith({
    String? id,
    String? guideId,
    String? title,
    Value<String?> coverUrl = const Value.absent(),
    String? materialsJson,
    String? stepsJson,
    DateTime? createdAt,
  }) => GuideProjectRow(
    id: id ?? this.id,
    guideId: guideId ?? this.guideId,
    title: title ?? this.title,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    materialsJson: materialsJson ?? this.materialsJson,
    stepsJson: stepsJson ?? this.stepsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  GuideProjectRow copyWithCompanion(GuideProjectsTableCompanion data) {
    return GuideProjectRow(
      id: data.id.present ? data.id.value : this.id,
      guideId: data.guideId.present ? data.guideId.value : this.guideId,
      title: data.title.present ? data.title.value : this.title,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      materialsJson: data.materialsJson.present
          ? data.materialsJson.value
          : this.materialsJson,
      stepsJson: data.stepsJson.present ? data.stepsJson.value : this.stepsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuideProjectRow(')
          ..write('id: $id, ')
          ..write('guideId: $guideId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('stepsJson: $stepsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    guideId,
    title,
    coverUrl,
    materialsJson,
    stepsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuideProjectRow &&
          other.id == this.id &&
          other.guideId == this.guideId &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.materialsJson == this.materialsJson &&
          other.stepsJson == this.stepsJson &&
          other.createdAt == this.createdAt);
}

class GuideProjectsTableCompanion extends UpdateCompanion<GuideProjectRow> {
  final Value<String> id;
  final Value<String> guideId;
  final Value<String> title;
  final Value<String?> coverUrl;
  final Value<String> materialsJson;
  final Value<String> stepsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GuideProjectsTableCompanion({
    this.id = const Value.absent(),
    this.guideId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.materialsJson = const Value.absent(),
    this.stepsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GuideProjectsTableCompanion.insert({
    required String id,
    required String guideId,
    required String title,
    this.coverUrl = const Value.absent(),
    required String materialsJson,
    required String stepsJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       guideId = Value(guideId),
       title = Value(title),
       materialsJson = Value(materialsJson),
       stepsJson = Value(stepsJson),
       createdAt = Value(createdAt);
  static Insertable<GuideProjectRow> custom({
    Expression<String>? id,
    Expression<String>? guideId,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<String>? materialsJson,
    Expression<String>? stepsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (guideId != null) 'guide_id': guideId,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (materialsJson != null) 'materials_json': materialsJson,
      if (stepsJson != null) 'steps_json': stepsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GuideProjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? guideId,
    Value<String>? title,
    Value<String?>? coverUrl,
    Value<String>? materialsJson,
    Value<String>? stepsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GuideProjectsTableCompanion(
      id: id ?? this.id,
      guideId: guideId ?? this.guideId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      materialsJson: materialsJson ?? this.materialsJson,
      stepsJson: stepsJson ?? this.stepsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (guideId.present) {
      map['guide_id'] = Variable<String>(guideId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (materialsJson.present) {
      map['materials_json'] = Variable<String>(materialsJson.value);
    }
    if (stepsJson.present) {
      map['steps_json'] = Variable<String>(stepsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuideProjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('guideId: $guideId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('materialsJson: $materialsJson, ')
          ..write('stepsJson: $stepsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfileTableTable userProfileTable = $UserProfileTableTable(
    this,
  );
  late final $SpacesTableTable spacesTable = $SpacesTableTable(this);
  late final $ClimateMonthsTableTable climateMonthsTable =
      $ClimateMonthsTableTable(this);
  late final $ClimateMetaTableTable climateMetaTable = $ClimateMetaTableTable(
    this,
  );
  late final $WeatherDaysTableTable weatherDaysTable = $WeatherDaysTableTable(
    this,
  );
  late final $WeatherCurrentTableTable weatherCurrentTable =
      $WeatherCurrentTableTable(this);
  late final $PlantingsTableTable plantingsTable = $PlantingsTableTable(this);
  late final $CareEventsTableTable careEventsTable = $CareEventsTableTable(
    this,
  );
  late final $GuideProjectsTableTable guideProjectsTable =
      $GuideProjectsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfileTable,
    spacesTable,
    climateMonthsTable,
    climateMetaTable,
    weatherDaysTable,
    weatherCurrentTable,
    plantingsTable,
    careEventsTable,
    guideProjectsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'plantings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('care_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$UserProfileTableTableCreateCompanionBuilder =
    UserProfileTableCompanion Function({
      Value<int> id,
      required String city,
      required String admin1,
      required String countryCode,
      Value<String?> postcode,
      required double lat,
      required double lon,
      required String timezone,
      required List<Goal> goals,
      Value<String?> goalOtherText,
      required Experience experience,
      Value<HeardFrom?> heardFrom,
      Value<String?> heardOtherText,
      required Availability availability,
      required String units,
      Value<bool> notificationsEnabled,
      Value<bool> notificationPermissionAsked,
      Value<bool> firstPlantPromptDismissed,
      Value<DateTime?> onboardingCompletedAt,
    });
typedef $$UserProfileTableTableUpdateCompanionBuilder =
    UserProfileTableCompanion Function({
      Value<int> id,
      Value<String> city,
      Value<String> admin1,
      Value<String> countryCode,
      Value<String?> postcode,
      Value<double> lat,
      Value<double> lon,
      Value<String> timezone,
      Value<List<Goal>> goals,
      Value<String?> goalOtherText,
      Value<Experience> experience,
      Value<HeardFrom?> heardFrom,
      Value<String?> heardOtherText,
      Value<Availability> availability,
      Value<String> units,
      Value<bool> notificationsEnabled,
      Value<bool> notificationPermissionAsked,
      Value<bool> firstPlantPromptDismissed,
      Value<DateTime?> onboardingCompletedAt,
    });

class $$UserProfileTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTableTable> {
  $$UserProfileTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get admin1 => $composableBuilder(
    column: $table.admin1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postcode => $composableBuilder(
    column: $table.postcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<Goal>, List<Goal>, String> get goals =>
      $composableBuilder(
        column: $table.goals,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get goalOtherText => $composableBuilder(
    column: $table.goalOtherText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Experience, Experience, String>
  get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<HeardFrom?, HeardFrom, String> get heardFrom =>
      $composableBuilder(
        column: $table.heardFrom,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get heardOtherText => $composableBuilder(
    column: $table.heardOtherText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Availability, Availability, String>
  get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationPermissionAsked => $composableBuilder(
    column: $table.notificationPermissionAsked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get firstPlantPromptDismissed => $composableBuilder(
    column: $table.firstPlantPromptDismissed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTableTable> {
  $$UserProfileTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get admin1 => $composableBuilder(
    column: $table.admin1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postcode => $composableBuilder(
    column: $table.postcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goals => $composableBuilder(
    column: $table.goals,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalOtherText => $composableBuilder(
    column: $table.goalOtherText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heardFrom => $composableBuilder(
    column: $table.heardFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heardOtherText => $composableBuilder(
    column: $table.heardOtherText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationPermissionAsked => $composableBuilder(
    column: $table.notificationPermissionAsked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get firstPlantPromptDismissed => $composableBuilder(
    column: $table.firstPlantPromptDismissed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTableTable> {
  $$UserProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get admin1 =>
      $composableBuilder(column: $table.admin1, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get postcode =>
      $composableBuilder(column: $table.postcode, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<Goal>, String> get goals =>
      $composableBuilder(column: $table.goals, builder: (column) => column);

  GeneratedColumn<String> get goalOtherText => $composableBuilder(
    column: $table.goalOtherText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Experience, String> get experience =>
      $composableBuilder(
        column: $table.experience,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<HeardFrom?, String> get heardFrom =>
      $composableBuilder(column: $table.heardFrom, builder: (column) => column);

  GeneratedColumn<String> get heardOtherText => $composableBuilder(
    column: $table.heardOtherText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Availability, String> get availability =>
      $composableBuilder(
        column: $table.availability,
        builder: (column) => column,
      );

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationPermissionAsked => $composableBuilder(
    column: $table.notificationPermissionAsked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get firstPlantPromptDismissed => $composableBuilder(
    column: $table.firstPlantPromptDismissed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get onboardingCompletedAt => $composableBuilder(
    column: $table.onboardingCompletedAt,
    builder: (column) => column,
  );
}

class $$UserProfileTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTableTable,
          UserProfileRow,
          $$UserProfileTableTableFilterComposer,
          $$UserProfileTableTableOrderingComposer,
          $$UserProfileTableTableAnnotationComposer,
          $$UserProfileTableTableCreateCompanionBuilder,
          $$UserProfileTableTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<
              _$AppDatabase,
              $UserProfileTableTable,
              UserProfileRow
            >,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableTableManager(
    _$AppDatabase db,
    $UserProfileTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> admin1 = const Value.absent(),
                Value<String> countryCode = const Value.absent(),
                Value<String?> postcode = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<List<Goal>> goals = const Value.absent(),
                Value<String?> goalOtherText = const Value.absent(),
                Value<Experience> experience = const Value.absent(),
                Value<HeardFrom?> heardFrom = const Value.absent(),
                Value<String?> heardOtherText = const Value.absent(),
                Value<Availability> availability = const Value.absent(),
                Value<String> units = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> notificationPermissionAsked = const Value.absent(),
                Value<bool> firstPlantPromptDismissed = const Value.absent(),
                Value<DateTime?> onboardingCompletedAt = const Value.absent(),
              }) => UserProfileTableCompanion(
                id: id,
                city: city,
                admin1: admin1,
                countryCode: countryCode,
                postcode: postcode,
                lat: lat,
                lon: lon,
                timezone: timezone,
                goals: goals,
                goalOtherText: goalOtherText,
                experience: experience,
                heardFrom: heardFrom,
                heardOtherText: heardOtherText,
                availability: availability,
                units: units,
                notificationsEnabled: notificationsEnabled,
                notificationPermissionAsked: notificationPermissionAsked,
                firstPlantPromptDismissed: firstPlantPromptDismissed,
                onboardingCompletedAt: onboardingCompletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String city,
                required String admin1,
                required String countryCode,
                Value<String?> postcode = const Value.absent(),
                required double lat,
                required double lon,
                required String timezone,
                required List<Goal> goals,
                Value<String?> goalOtherText = const Value.absent(),
                required Experience experience,
                Value<HeardFrom?> heardFrom = const Value.absent(),
                Value<String?> heardOtherText = const Value.absent(),
                required Availability availability,
                required String units,
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> notificationPermissionAsked = const Value.absent(),
                Value<bool> firstPlantPromptDismissed = const Value.absent(),
                Value<DateTime?> onboardingCompletedAt = const Value.absent(),
              }) => UserProfileTableCompanion.insert(
                id: id,
                city: city,
                admin1: admin1,
                countryCode: countryCode,
                postcode: postcode,
                lat: lat,
                lon: lon,
                timezone: timezone,
                goals: goals,
                goalOtherText: goalOtherText,
                experience: experience,
                heardFrom: heardFrom,
                heardOtherText: heardOtherText,
                availability: availability,
                units: units,
                notificationsEnabled: notificationsEnabled,
                notificationPermissionAsked: notificationPermissionAsked,
                firstPlantPromptDismissed: firstPlantPromptDismissed,
                onboardingCompletedAt: onboardingCompletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfileTableTable, UserProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfileTableTable,
                    UserProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTableTable,
      UserProfileRow,
      $$UserProfileTableTableFilterComposer,
      $$UserProfileTableTableOrderingComposer,
      $$UserProfileTableTableAnnotationComposer,
      $$UserProfileTableTableCreateCompanionBuilder,
      $$UserProfileTableTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfileTableTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SpacesTableTableCreateCompanionBuilder =
    SpacesTableCompanion Function({
      required String id,
      required SpaceType type,
      required int areaSqFt,
      required SunLevel sun,
      required bool sunUnsure,
      required bool rainExposed,
      required bool inContainerDefault,
      required bool isPrimary,
      Value<int> rowid,
    });
typedef $$SpacesTableTableUpdateCompanionBuilder =
    SpacesTableCompanion Function({
      Value<String> id,
      Value<SpaceType> type,
      Value<int> areaSqFt,
      Value<SunLevel> sun,
      Value<bool> sunUnsure,
      Value<bool> rainExposed,
      Value<bool> inContainerDefault,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

class $$SpacesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SpacesTableTable> {
  $$SpacesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SpaceType, SpaceType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get areaSqFt => $composableBuilder(
    column: $table.areaSqFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SunLevel, SunLevel, String> get sun =>
      $composableBuilder(
        column: $table.sun,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get sunUnsure => $composableBuilder(
    column: $table.sunUnsure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rainExposed => $composableBuilder(
    column: $table.rainExposed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inContainerDefault => $composableBuilder(
    column: $table.inContainerDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpacesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SpacesTableTable> {
  $$SpacesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get areaSqFt => $composableBuilder(
    column: $table.areaSqFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sun => $composableBuilder(
    column: $table.sun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sunUnsure => $composableBuilder(
    column: $table.sunUnsure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rainExposed => $composableBuilder(
    column: $table.rainExposed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inContainerDefault => $composableBuilder(
    column: $table.inContainerDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpacesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpacesTableTable> {
  $$SpacesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SpaceType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get areaSqFt =>
      $composableBuilder(column: $table.areaSqFt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SunLevel, String> get sun =>
      $composableBuilder(column: $table.sun, builder: (column) => column);

  GeneratedColumn<bool> get sunUnsure =>
      $composableBuilder(column: $table.sunUnsure, builder: (column) => column);

  GeneratedColumn<bool> get rainExposed => $composableBuilder(
    column: $table.rainExposed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get inContainerDefault => $composableBuilder(
    column: $table.inContainerDefault,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);
}

class $$SpacesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpacesTableTable,
          SpaceRow,
          $$SpacesTableTableFilterComposer,
          $$SpacesTableTableOrderingComposer,
          $$SpacesTableTableAnnotationComposer,
          $$SpacesTableTableCreateCompanionBuilder,
          $$SpacesTableTableUpdateCompanionBuilder,
          (
            SpaceRow,
            BaseReferences<_$AppDatabase, $SpacesTableTable, SpaceRow>,
          ),
          SpaceRow,
          PrefetchHooks Function()
        > {
  $$SpacesTableTableTableManager(_$AppDatabase db, $SpacesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpacesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpacesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpacesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SpaceType> type = const Value.absent(),
                Value<int> areaSqFt = const Value.absent(),
                Value<SunLevel> sun = const Value.absent(),
                Value<bool> sunUnsure = const Value.absent(),
                Value<bool> rainExposed = const Value.absent(),
                Value<bool> inContainerDefault = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpacesTableCompanion(
                id: id,
                type: type,
                areaSqFt: areaSqFt,
                sun: sun,
                sunUnsure: sunUnsure,
                rainExposed: rainExposed,
                inContainerDefault: inContainerDefault,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required SpaceType type,
                required int areaSqFt,
                required SunLevel sun,
                required bool sunUnsure,
                required bool rainExposed,
                required bool inContainerDefault,
                required bool isPrimary,
                Value<int> rowid = const Value.absent(),
              }) => SpacesTableCompanion.insert(
                id: id,
                type: type,
                areaSqFt: areaSqFt,
                sun: sun,
                sunUnsure: sunUnsure,
                rainExposed: rainExposed,
                inContainerDefault: inContainerDefault,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpacesTableTable, SpaceRow>(table),
                  BaseReferences<_$AppDatabase, $SpacesTableTable, SpaceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpacesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpacesTableTable,
      SpaceRow,
      $$SpacesTableTableFilterComposer,
      $$SpacesTableTableOrderingComposer,
      $$SpacesTableTableAnnotationComposer,
      $$SpacesTableTableCreateCompanionBuilder,
      $$SpacesTableTableUpdateCompanionBuilder,
      (SpaceRow, BaseReferences<_$AppDatabase, $SpacesTableTable, SpaceRow>),
      SpaceRow,
      PrefetchHooks Function()
    >;
typedef $$ClimateMonthsTableTableCreateCompanionBuilder =
    ClimateMonthsTableCompanion Function({
      Value<int> month,
      required double avgLowF,
      required double avgHighF,
      required double precipIn,
      required double rhPct,
      required double cloudPct,
      required double sunshineHours,
    });
typedef $$ClimateMonthsTableTableUpdateCompanionBuilder =
    ClimateMonthsTableCompanion Function({
      Value<int> month,
      Value<double> avgLowF,
      Value<double> avgHighF,
      Value<double> precipIn,
      Value<double> rhPct,
      Value<double> cloudPct,
      Value<double> sunshineHours,
    });

class $$ClimateMonthsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClimateMonthsTableTable> {
  $$ClimateMonthsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgLowF => $composableBuilder(
    column: $table.avgLowF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgHighF => $composableBuilder(
    column: $table.avgHighF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precipIn => $composableBuilder(
    column: $table.precipIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rhPct => $composableBuilder(
    column: $table.rhPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cloudPct => $composableBuilder(
    column: $table.cloudPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sunshineHours => $composableBuilder(
    column: $table.sunshineHours,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClimateMonthsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClimateMonthsTableTable> {
  $$ClimateMonthsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgLowF => $composableBuilder(
    column: $table.avgLowF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgHighF => $composableBuilder(
    column: $table.avgHighF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precipIn => $composableBuilder(
    column: $table.precipIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rhPct => $composableBuilder(
    column: $table.rhPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cloudPct => $composableBuilder(
    column: $table.cloudPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sunshineHours => $composableBuilder(
    column: $table.sunshineHours,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClimateMonthsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClimateMonthsTableTable> {
  $$ClimateMonthsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<double> get avgLowF =>
      $composableBuilder(column: $table.avgLowF, builder: (column) => column);

  GeneratedColumn<double> get avgHighF =>
      $composableBuilder(column: $table.avgHighF, builder: (column) => column);

  GeneratedColumn<double> get precipIn =>
      $composableBuilder(column: $table.precipIn, builder: (column) => column);

  GeneratedColumn<double> get rhPct =>
      $composableBuilder(column: $table.rhPct, builder: (column) => column);

  GeneratedColumn<double> get cloudPct =>
      $composableBuilder(column: $table.cloudPct, builder: (column) => column);

  GeneratedColumn<double> get sunshineHours => $composableBuilder(
    column: $table.sunshineHours,
    builder: (column) => column,
  );
}

class $$ClimateMonthsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClimateMonthsTableTable,
          ClimateMonthRow,
          $$ClimateMonthsTableTableFilterComposer,
          $$ClimateMonthsTableTableOrderingComposer,
          $$ClimateMonthsTableTableAnnotationComposer,
          $$ClimateMonthsTableTableCreateCompanionBuilder,
          $$ClimateMonthsTableTableUpdateCompanionBuilder,
          (
            ClimateMonthRow,
            BaseReferences<
              _$AppDatabase,
              $ClimateMonthsTableTable,
              ClimateMonthRow
            >,
          ),
          ClimateMonthRow,
          PrefetchHooks Function()
        > {
  $$ClimateMonthsTableTableTableManager(
    _$AppDatabase db,
    $ClimateMonthsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClimateMonthsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClimateMonthsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClimateMonthsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> month = const Value.absent(),
                Value<double> avgLowF = const Value.absent(),
                Value<double> avgHighF = const Value.absent(),
                Value<double> precipIn = const Value.absent(),
                Value<double> rhPct = const Value.absent(),
                Value<double> cloudPct = const Value.absent(),
                Value<double> sunshineHours = const Value.absent(),
              }) => ClimateMonthsTableCompanion(
                month: month,
                avgLowF: avgLowF,
                avgHighF: avgHighF,
                precipIn: precipIn,
                rhPct: rhPct,
                cloudPct: cloudPct,
                sunshineHours: sunshineHours,
              ),
          createCompanionCallback:
              ({
                Value<int> month = const Value.absent(),
                required double avgLowF,
                required double avgHighF,
                required double precipIn,
                required double rhPct,
                required double cloudPct,
                required double sunshineHours,
              }) => ClimateMonthsTableCompanion.insert(
                month: month,
                avgLowF: avgLowF,
                avgHighF: avgHighF,
                precipIn: precipIn,
                rhPct: rhPct,
                cloudPct: cloudPct,
                sunshineHours: sunshineHours,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClimateMonthsTableTable, ClimateMonthRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ClimateMonthsTableTable,
                    ClimateMonthRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClimateMonthsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClimateMonthsTableTable,
      ClimateMonthRow,
      $$ClimateMonthsTableTableFilterComposer,
      $$ClimateMonthsTableTableOrderingComposer,
      $$ClimateMonthsTableTableAnnotationComposer,
      $$ClimateMonthsTableTableCreateCompanionBuilder,
      $$ClimateMonthsTableTableUpdateCompanionBuilder,
      (
        ClimateMonthRow,
        BaseReferences<
          _$AppDatabase,
          $ClimateMonthsTableTable,
          ClimateMonthRow
        >,
      ),
      ClimateMonthRow,
      PrefetchHooks Function()
    >;
typedef $$ClimateMetaTableTableCreateCompanionBuilder =
    ClimateMetaTableCompanion Function({
      Value<int> id,
      required double annualExtremeMinF,
      required double annualPrecipIn,
      required double annualRhPct,
      required String zone,
      required ZoneSource zoneSource,
      Value<int?> lastSpringFrostDoy,
      Value<int?> firstFallFrostDoy,
      required double lat,
      required double lon,
      required DateTime computedAt,
    });
typedef $$ClimateMetaTableTableUpdateCompanionBuilder =
    ClimateMetaTableCompanion Function({
      Value<int> id,
      Value<double> annualExtremeMinF,
      Value<double> annualPrecipIn,
      Value<double> annualRhPct,
      Value<String> zone,
      Value<ZoneSource> zoneSource,
      Value<int?> lastSpringFrostDoy,
      Value<int?> firstFallFrostDoy,
      Value<double> lat,
      Value<double> lon,
      Value<DateTime> computedAt,
    });

class $$ClimateMetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClimateMetaTableTable> {
  $$ClimateMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualExtremeMinF => $composableBuilder(
    column: $table.annualExtremeMinF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualPrecipIn => $composableBuilder(
    column: $table.annualPrecipIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get annualRhPct => $composableBuilder(
    column: $table.annualRhPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ZoneSource, ZoneSource, String>
  get zoneSource => $composableBuilder(
    column: $table.zoneSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get lastSpringFrostDoy => $composableBuilder(
    column: $table.lastSpringFrostDoy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstFallFrostDoy => $composableBuilder(
    column: $table.firstFallFrostDoy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClimateMetaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClimateMetaTableTable> {
  $$ClimateMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualExtremeMinF => $composableBuilder(
    column: $table.annualExtremeMinF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualPrecipIn => $composableBuilder(
    column: $table.annualPrecipIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get annualRhPct => $composableBuilder(
    column: $table.annualRhPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneSource => $composableBuilder(
    column: $table.zoneSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSpringFrostDoy => $composableBuilder(
    column: $table.lastSpringFrostDoy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstFallFrostDoy => $composableBuilder(
    column: $table.firstFallFrostDoy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClimateMetaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClimateMetaTableTable> {
  $$ClimateMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get annualExtremeMinF => $composableBuilder(
    column: $table.annualExtremeMinF,
    builder: (column) => column,
  );

  GeneratedColumn<double> get annualPrecipIn => $composableBuilder(
    column: $table.annualPrecipIn,
    builder: (column) => column,
  );

  GeneratedColumn<double> get annualRhPct => $composableBuilder(
    column: $table.annualRhPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ZoneSource, String> get zoneSource =>
      $composableBuilder(
        column: $table.zoneSource,
        builder: (column) => column,
      );

  GeneratedColumn<int> get lastSpringFrostDoy => $composableBuilder(
    column: $table.lastSpringFrostDoy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstFallFrostDoy => $composableBuilder(
    column: $table.firstFallFrostDoy,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$ClimateMetaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClimateMetaTableTable,
          ClimateMetaRow,
          $$ClimateMetaTableTableFilterComposer,
          $$ClimateMetaTableTableOrderingComposer,
          $$ClimateMetaTableTableAnnotationComposer,
          $$ClimateMetaTableTableCreateCompanionBuilder,
          $$ClimateMetaTableTableUpdateCompanionBuilder,
          (
            ClimateMetaRow,
            BaseReferences<
              _$AppDatabase,
              $ClimateMetaTableTable,
              ClimateMetaRow
            >,
          ),
          ClimateMetaRow,
          PrefetchHooks Function()
        > {
  $$ClimateMetaTableTableTableManager(
    _$AppDatabase db,
    $ClimateMetaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClimateMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClimateMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClimateMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> annualExtremeMinF = const Value.absent(),
                Value<double> annualPrecipIn = const Value.absent(),
                Value<double> annualRhPct = const Value.absent(),
                Value<String> zone = const Value.absent(),
                Value<ZoneSource> zoneSource = const Value.absent(),
                Value<int?> lastSpringFrostDoy = const Value.absent(),
                Value<int?> firstFallFrostDoy = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
              }) => ClimateMetaTableCompanion(
                id: id,
                annualExtremeMinF: annualExtremeMinF,
                annualPrecipIn: annualPrecipIn,
                annualRhPct: annualRhPct,
                zone: zone,
                zoneSource: zoneSource,
                lastSpringFrostDoy: lastSpringFrostDoy,
                firstFallFrostDoy: firstFallFrostDoy,
                lat: lat,
                lon: lon,
                computedAt: computedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double annualExtremeMinF,
                required double annualPrecipIn,
                required double annualRhPct,
                required String zone,
                required ZoneSource zoneSource,
                Value<int?> lastSpringFrostDoy = const Value.absent(),
                Value<int?> firstFallFrostDoy = const Value.absent(),
                required double lat,
                required double lon,
                required DateTime computedAt,
              }) => ClimateMetaTableCompanion.insert(
                id: id,
                annualExtremeMinF: annualExtremeMinF,
                annualPrecipIn: annualPrecipIn,
                annualRhPct: annualRhPct,
                zone: zone,
                zoneSource: zoneSource,
                lastSpringFrostDoy: lastSpringFrostDoy,
                firstFallFrostDoy: firstFallFrostDoy,
                lat: lat,
                lon: lon,
                computedAt: computedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClimateMetaTableTable, ClimateMetaRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ClimateMetaTableTable,
                    ClimateMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClimateMetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClimateMetaTableTable,
      ClimateMetaRow,
      $$ClimateMetaTableTableFilterComposer,
      $$ClimateMetaTableTableOrderingComposer,
      $$ClimateMetaTableTableAnnotationComposer,
      $$ClimateMetaTableTableCreateCompanionBuilder,
      $$ClimateMetaTableTableUpdateCompanionBuilder,
      (
        ClimateMetaRow,
        BaseReferences<_$AppDatabase, $ClimateMetaTableTable, ClimateMetaRow>,
      ),
      ClimateMetaRow,
      PrefetchHooks Function()
    >;
typedef $$WeatherDaysTableTableCreateCompanionBuilder =
    WeatherDaysTableCompanion Function({
      required String date,
      required int weatherCode,
      required double tmaxF,
      required double tminF,
      required double precipIn,
      Value<int?> precipProb,
      Value<double?> uvMax,
      required double sunshineS,
      required double daylightS,
      required double et0In,
      required String sunrise,
      required String sunset,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$WeatherDaysTableTableUpdateCompanionBuilder =
    WeatherDaysTableCompanion Function({
      Value<String> date,
      Value<int> weatherCode,
      Value<double> tmaxF,
      Value<double> tminF,
      Value<double> precipIn,
      Value<int?> precipProb,
      Value<double?> uvMax,
      Value<double> sunshineS,
      Value<double> daylightS,
      Value<double> et0In,
      Value<String> sunrise,
      Value<String> sunset,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$WeatherDaysTableTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherDaysTableTable> {
  $$WeatherDaysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tmaxF => $composableBuilder(
    column: $table.tmaxF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tminF => $composableBuilder(
    column: $table.tminF,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precipIn => $composableBuilder(
    column: $table.precipIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precipProb => $composableBuilder(
    column: $table.precipProb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get uvMax => $composableBuilder(
    column: $table.uvMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sunshineS => $composableBuilder(
    column: $table.sunshineS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get daylightS => $composableBuilder(
    column: $table.daylightS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get et0In => $composableBuilder(
    column: $table.et0In,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sunrise => $composableBuilder(
    column: $table.sunrise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sunset => $composableBuilder(
    column: $table.sunset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherDaysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherDaysTableTable> {
  $$WeatherDaysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tmaxF => $composableBuilder(
    column: $table.tmaxF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tminF => $composableBuilder(
    column: $table.tminF,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precipIn => $composableBuilder(
    column: $table.precipIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precipProb => $composableBuilder(
    column: $table.precipProb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get uvMax => $composableBuilder(
    column: $table.uvMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sunshineS => $composableBuilder(
    column: $table.sunshineS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get daylightS => $composableBuilder(
    column: $table.daylightS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get et0In => $composableBuilder(
    column: $table.et0In,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sunrise => $composableBuilder(
    column: $table.sunrise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sunset => $composableBuilder(
    column: $table.sunset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherDaysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherDaysTableTable> {
  $$WeatherDaysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get weatherCode => $composableBuilder(
    column: $table.weatherCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tmaxF =>
      $composableBuilder(column: $table.tmaxF, builder: (column) => column);

  GeneratedColumn<double> get tminF =>
      $composableBuilder(column: $table.tminF, builder: (column) => column);

  GeneratedColumn<double> get precipIn =>
      $composableBuilder(column: $table.precipIn, builder: (column) => column);

  GeneratedColumn<int> get precipProb => $composableBuilder(
    column: $table.precipProb,
    builder: (column) => column,
  );

  GeneratedColumn<double> get uvMax =>
      $composableBuilder(column: $table.uvMax, builder: (column) => column);

  GeneratedColumn<double> get sunshineS =>
      $composableBuilder(column: $table.sunshineS, builder: (column) => column);

  GeneratedColumn<double> get daylightS =>
      $composableBuilder(column: $table.daylightS, builder: (column) => column);

  GeneratedColumn<double> get et0In =>
      $composableBuilder(column: $table.et0In, builder: (column) => column);

  GeneratedColumn<String> get sunrise =>
      $composableBuilder(column: $table.sunrise, builder: (column) => column);

  GeneratedColumn<String> get sunset =>
      $composableBuilder(column: $table.sunset, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$WeatherDaysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherDaysTableTable,
          WeatherDayRow,
          $$WeatherDaysTableTableFilterComposer,
          $$WeatherDaysTableTableOrderingComposer,
          $$WeatherDaysTableTableAnnotationComposer,
          $$WeatherDaysTableTableCreateCompanionBuilder,
          $$WeatherDaysTableTableUpdateCompanionBuilder,
          (
            WeatherDayRow,
            BaseReferences<
              _$AppDatabase,
              $WeatherDaysTableTable,
              WeatherDayRow
            >,
          ),
          WeatherDayRow,
          PrefetchHooks Function()
        > {
  $$WeatherDaysTableTableTableManager(
    _$AppDatabase db,
    $WeatherDaysTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherDaysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherDaysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherDaysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> weatherCode = const Value.absent(),
                Value<double> tmaxF = const Value.absent(),
                Value<double> tminF = const Value.absent(),
                Value<double> precipIn = const Value.absent(),
                Value<int?> precipProb = const Value.absent(),
                Value<double?> uvMax = const Value.absent(),
                Value<double> sunshineS = const Value.absent(),
                Value<double> daylightS = const Value.absent(),
                Value<double> et0In = const Value.absent(),
                Value<String> sunrise = const Value.absent(),
                Value<String> sunset = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeatherDaysTableCompanion(
                date: date,
                weatherCode: weatherCode,
                tmaxF: tmaxF,
                tminF: tminF,
                precipIn: precipIn,
                precipProb: precipProb,
                uvMax: uvMax,
                sunshineS: sunshineS,
                daylightS: daylightS,
                et0In: et0In,
                sunrise: sunrise,
                sunset: sunset,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int weatherCode,
                required double tmaxF,
                required double tminF,
                required double precipIn,
                Value<int?> precipProb = const Value.absent(),
                Value<double?> uvMax = const Value.absent(),
                required double sunshineS,
                required double daylightS,
                required double et0In,
                required String sunrise,
                required String sunset,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => WeatherDaysTableCompanion.insert(
                date: date,
                weatherCode: weatherCode,
                tmaxF: tmaxF,
                tminF: tminF,
                precipIn: precipIn,
                precipProb: precipProb,
                uvMax: uvMax,
                sunshineS: sunshineS,
                daylightS: daylightS,
                et0In: et0In,
                sunrise: sunrise,
                sunset: sunset,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeatherDaysTableTable, WeatherDayRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WeatherDaysTableTable,
                    WeatherDayRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherDaysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherDaysTableTable,
      WeatherDayRow,
      $$WeatherDaysTableTableFilterComposer,
      $$WeatherDaysTableTableOrderingComposer,
      $$WeatherDaysTableTableAnnotationComposer,
      $$WeatherDaysTableTableCreateCompanionBuilder,
      $$WeatherDaysTableTableUpdateCompanionBuilder,
      (
        WeatherDayRow,
        BaseReferences<_$AppDatabase, $WeatherDaysTableTable, WeatherDayRow>,
      ),
      WeatherDayRow,
      PrefetchHooks Function()
    >;
typedef $$WeatherCurrentTableTableCreateCompanionBuilder =
    WeatherCurrentTableCompanion Function({
      Value<int> id,
      required String json,
      required DateTime fetchedAt,
    });
typedef $$WeatherCurrentTableTableUpdateCompanionBuilder =
    WeatherCurrentTableCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<DateTime> fetchedAt,
    });

class $$WeatherCurrentTableTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCurrentTableTable> {
  $$WeatherCurrentTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCurrentTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCurrentTableTable> {
  $$WeatherCurrentTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCurrentTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCurrentTableTable> {
  $$WeatherCurrentTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$WeatherCurrentTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCurrentTableTable,
          WeatherCurrentRow,
          $$WeatherCurrentTableTableFilterComposer,
          $$WeatherCurrentTableTableOrderingComposer,
          $$WeatherCurrentTableTableAnnotationComposer,
          $$WeatherCurrentTableTableCreateCompanionBuilder,
          $$WeatherCurrentTableTableUpdateCompanionBuilder,
          (
            WeatherCurrentRow,
            BaseReferences<
              _$AppDatabase,
              $WeatherCurrentTableTable,
              WeatherCurrentRow
            >,
          ),
          WeatherCurrentRow,
          PrefetchHooks Function()
        > {
  $$WeatherCurrentTableTableTableManager(
    _$AppDatabase db,
    $WeatherCurrentTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCurrentTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherCurrentTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WeatherCurrentTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => WeatherCurrentTableCompanion(
                id: id,
                json: json,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                required DateTime fetchedAt,
              }) => WeatherCurrentTableCompanion.insert(
                id: id,
                json: json,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeatherCurrentTableTable, WeatherCurrentRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $WeatherCurrentTableTable,
                    WeatherCurrentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCurrentTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCurrentTableTable,
      WeatherCurrentRow,
      $$WeatherCurrentTableTableFilterComposer,
      $$WeatherCurrentTableTableOrderingComposer,
      $$WeatherCurrentTableTableAnnotationComposer,
      $$WeatherCurrentTableTableCreateCompanionBuilder,
      $$WeatherCurrentTableTableUpdateCompanionBuilder,
      (
        WeatherCurrentRow,
        BaseReferences<
          _$AppDatabase,
          $WeatherCurrentTableTable,
          WeatherCurrentRow
        >,
      ),
      WeatherCurrentRow,
      PrefetchHooks Function()
    >;
typedef $$PlantingsTableTableCreateCompanionBuilder =
    PlantingsTableCompanion Function({
      required String id,
      required String plantId,
      required String spaceId,
      required String nickname,
      required GrowSetup setup,
      required bool inContainer,
      required String startMethod,
      Value<DateTime?> plantedOn,
      required PlantingStatus status,
      Value<String?> projectId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlantingsTableTableUpdateCompanionBuilder =
    PlantingsTableCompanion Function({
      Value<String> id,
      Value<String> plantId,
      Value<String> spaceId,
      Value<String> nickname,
      Value<GrowSetup> setup,
      Value<bool> inContainer,
      Value<String> startMethod,
      Value<DateTime?> plantedOn,
      Value<PlantingStatus> status,
      Value<String?> projectId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PlantingsTableTableReferences
    extends BaseReferences<_$AppDatabase, $PlantingsTableTable, PlantingRow> {
  $$PlantingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CareEventsTableTable, List<CareEventRow>>
  _careEventsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.careEventsTable,
    aliasName: 'plantings__id__care_events__planting_id',
  );

  $$CareEventsTableTableProcessedTableManager get careEventsTableRefs {
    final manager = $$CareEventsTableTableTableManager(
      $_db,
      $_db.careEventsTable,
    ).filter((f) => f.plantingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _careEventsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlantingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlantingsTableTable> {
  $$PlantingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plantId => $composableBuilder(
    column: $table.plantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GrowSetup, GrowSetup, String> get setup =>
      $composableBuilder(
        column: $table.setup,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get inContainer => $composableBuilder(
    column: $table.inContainer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startMethod => $composableBuilder(
    column: $table.startMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get plantedOn => $composableBuilder(
    column: $table.plantedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlantingStatus, PlantingStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> careEventsTableRefs(
    Expression<bool> Function($$CareEventsTableTableFilterComposer f) f,
  ) {
    final $$CareEventsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.careEventsTable,
      getReferencedColumn: (t) => t.plantingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CareEventsTableTableFilterComposer(
            $db: $db,
            $table: $db.careEventsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlantingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantingsTableTable> {
  $$PlantingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plantId => $composableBuilder(
    column: $table.plantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setup => $composableBuilder(
    column: $table.setup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inContainer => $composableBuilder(
    column: $table.inContainer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startMethod => $composableBuilder(
    column: $table.startMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get plantedOn => $composableBuilder(
    column: $table.plantedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlantingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantingsTableTable> {
  $$PlantingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get plantId =>
      $composableBuilder(column: $table.plantId, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GrowSetup, String> get setup =>
      $composableBuilder(column: $table.setup, builder: (column) => column);

  GeneratedColumn<bool> get inContainer => $composableBuilder(
    column: $table.inContainer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startMethod => $composableBuilder(
    column: $table.startMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get plantedOn =>
      $composableBuilder(column: $table.plantedOn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlantingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> careEventsTableRefs<T extends Object>(
    Expression<T> Function($$CareEventsTableTableAnnotationComposer a) f,
  ) {
    final $$CareEventsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.careEventsTable,
      getReferencedColumn: (t) => t.plantingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CareEventsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.careEventsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlantingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantingsTableTable,
          PlantingRow,
          $$PlantingsTableTableFilterComposer,
          $$PlantingsTableTableOrderingComposer,
          $$PlantingsTableTableAnnotationComposer,
          $$PlantingsTableTableCreateCompanionBuilder,
          $$PlantingsTableTableUpdateCompanionBuilder,
          (PlantingRow, $$PlantingsTableTableReferences),
          PlantingRow,
          PrefetchHooks Function({bool careEventsTableRefs})
        > {
  $$PlantingsTableTableTableManager(
    _$AppDatabase db,
    $PlantingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plantId = const Value.absent(),
                Value<String> spaceId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<GrowSetup> setup = const Value.absent(),
                Value<bool> inContainer = const Value.absent(),
                Value<String> startMethod = const Value.absent(),
                Value<DateTime?> plantedOn = const Value.absent(),
                Value<PlantingStatus> status = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantingsTableCompanion(
                id: id,
                plantId: plantId,
                spaceId: spaceId,
                nickname: nickname,
                setup: setup,
                inContainer: inContainer,
                startMethod: startMethod,
                plantedOn: plantedOn,
                status: status,
                projectId: projectId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plantId,
                required String spaceId,
                required String nickname,
                required GrowSetup setup,
                required bool inContainer,
                required String startMethod,
                Value<DateTime?> plantedOn = const Value.absent(),
                required PlantingStatus status,
                Value<String?> projectId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlantingsTableCompanion.insert(
                id: id,
                plantId: plantId,
                spaceId: spaceId,
                nickname: nickname,
                setup: setup,
                inContainer: inContainer,
                startMethod: startMethod,
                plantedOn: plantedOn,
                status: status,
                projectId: projectId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlantingsTableTable, PlantingRow>(table),
                  $$PlantingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({careEventsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (careEventsTableRefs) db.careEventsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (careEventsTableRefs)
                    await $_getPrefetchedData<
                      PlantingRow,
                      $PlantingsTableTable,
                      CareEventRow
                    >(
                      currentTable: table,
                      referencedTable: $$PlantingsTableTableReferences
                          ._careEventsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlantingsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).careEventsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.plantingId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlantingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantingsTableTable,
      PlantingRow,
      $$PlantingsTableTableFilterComposer,
      $$PlantingsTableTableOrderingComposer,
      $$PlantingsTableTableAnnotationComposer,
      $$PlantingsTableTableCreateCompanionBuilder,
      $$PlantingsTableTableUpdateCompanionBuilder,
      (PlantingRow, $$PlantingsTableTableReferences),
      PlantingRow,
      PrefetchHooks Function({bool careEventsTableRefs})
    >;
typedef $$CareEventsTableTableCreateCompanionBuilder =
    CareEventsTableCompanion Function({
      required String id,
      required String plantingId,
      required CareEventType type,
      required DateTime at,
      Value<String?> note,
      Value<String?> photoPath,
      Value<int> rowid,
    });
typedef $$CareEventsTableTableUpdateCompanionBuilder =
    CareEventsTableCompanion Function({
      Value<String> id,
      Value<String> plantingId,
      Value<CareEventType> type,
      Value<DateTime> at,
      Value<String?> note,
      Value<String?> photoPath,
      Value<int> rowid,
    });

final class $$CareEventsTableTableReferences
    extends BaseReferences<_$AppDatabase, $CareEventsTableTable, CareEventRow> {
  $$CareEventsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlantingsTableTable _plantingIdTable(_$AppDatabase db) =>
      db.plantingsTable.createAlias('care_events__planting_id__plantings__id');

  $$PlantingsTableTableProcessedTableManager get plantingId {
    final $_column = $_itemColumn<String>('planting_id')!;

    final manager = $$PlantingsTableTableTableManager(
      $_db,
      $_db.plantingsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plantingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CareEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CareEventsTableTable> {
  $$CareEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CareEventType, CareEventType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  $$PlantingsTableTableFilterComposer get plantingId {
    final $$PlantingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantingId,
      referencedTable: $db.plantingsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantingsTableTableFilterComposer(
            $db: $db,
            $table: $db.plantingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CareEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CareEventsTableTable> {
  $$CareEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlantingsTableTableOrderingComposer get plantingId {
    final $$PlantingsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantingId,
      referencedTable: $db.plantingsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantingsTableTableOrderingComposer(
            $db: $db,
            $table: $db.plantingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CareEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareEventsTableTable> {
  $$CareEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CareEventType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  $$PlantingsTableTableAnnotationComposer get plantingId {
    final $$PlantingsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plantingId,
      referencedTable: $db.plantingsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlantingsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.plantingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CareEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareEventsTableTable,
          CareEventRow,
          $$CareEventsTableTableFilterComposer,
          $$CareEventsTableTableOrderingComposer,
          $$CareEventsTableTableAnnotationComposer,
          $$CareEventsTableTableCreateCompanionBuilder,
          $$CareEventsTableTableUpdateCompanionBuilder,
          (CareEventRow, $$CareEventsTableTableReferences),
          CareEventRow,
          PrefetchHooks Function({bool plantingId})
        > {
  $$CareEventsTableTableTableManager(
    _$AppDatabase db,
    $CareEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareEventsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plantingId = const Value.absent(),
                Value<CareEventType> type = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareEventsTableCompanion(
                id: id,
                plantingId: plantingId,
                type: type,
                at: at,
                note: note,
                photoPath: photoPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plantingId,
                required CareEventType type,
                required DateTime at,
                Value<String?> note = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CareEventsTableCompanion.insert(
                id: id,
                plantingId: plantingId,
                type: type,
                at: at,
                note: note,
                photoPath: photoPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareEventsTableTable, CareEventRow>(table),
                  $$CareEventsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plantingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (plantingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.plantingId,
                        referencedTable: $$CareEventsTableTableReferences
                            ._plantingIdTable(db),
                        referencedColumn: $$CareEventsTableTableReferences
                            ._plantingIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CareEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareEventsTableTable,
      CareEventRow,
      $$CareEventsTableTableFilterComposer,
      $$CareEventsTableTableOrderingComposer,
      $$CareEventsTableTableAnnotationComposer,
      $$CareEventsTableTableCreateCompanionBuilder,
      $$CareEventsTableTableUpdateCompanionBuilder,
      (CareEventRow, $$CareEventsTableTableReferences),
      CareEventRow,
      PrefetchHooks Function({bool plantingId})
    >;
typedef $$GuideProjectsTableTableCreateCompanionBuilder =
    GuideProjectsTableCompanion Function({
      required String id,
      required String guideId,
      required String title,
      Value<String?> coverUrl,
      required String materialsJson,
      required String stepsJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$GuideProjectsTableTableUpdateCompanionBuilder =
    GuideProjectsTableCompanion Function({
      Value<String> id,
      Value<String> guideId,
      Value<String> title,
      Value<String?> coverUrl,
      Value<String> materialsJson,
      Value<String> stepsJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$GuideProjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GuideProjectsTableTable> {
  $$GuideProjectsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guideId => $composableBuilder(
    column: $table.guideId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepsJson => $composableBuilder(
    column: $table.stepsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GuideProjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GuideProjectsTableTable> {
  $$GuideProjectsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guideId => $composableBuilder(
    column: $table.guideId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepsJson => $composableBuilder(
    column: $table.stepsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GuideProjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuideProjectsTableTable> {
  $$GuideProjectsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guideId =>
      $composableBuilder(column: $table.guideId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get materialsJson => $composableBuilder(
    column: $table.materialsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stepsJson =>
      $composableBuilder(column: $table.stepsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GuideProjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuideProjectsTableTable,
          GuideProjectRow,
          $$GuideProjectsTableTableFilterComposer,
          $$GuideProjectsTableTableOrderingComposer,
          $$GuideProjectsTableTableAnnotationComposer,
          $$GuideProjectsTableTableCreateCompanionBuilder,
          $$GuideProjectsTableTableUpdateCompanionBuilder,
          (
            GuideProjectRow,
            BaseReferences<
              _$AppDatabase,
              $GuideProjectsTableTable,
              GuideProjectRow
            >,
          ),
          GuideProjectRow,
          PrefetchHooks Function()
        > {
  $$GuideProjectsTableTableTableManager(
    _$AppDatabase db,
    $GuideProjectsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuideProjectsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuideProjectsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuideProjectsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> guideId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String> materialsJson = const Value.absent(),
                Value<String> stepsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GuideProjectsTableCompanion(
                id: id,
                guideId: guideId,
                title: title,
                coverUrl: coverUrl,
                materialsJson: materialsJson,
                stepsJson: stepsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String guideId,
                required String title,
                Value<String?> coverUrl = const Value.absent(),
                required String materialsJson,
                required String stepsJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GuideProjectsTableCompanion.insert(
                id: id,
                guideId: guideId,
                title: title,
                coverUrl: coverUrl,
                materialsJson: materialsJson,
                stepsJson: stepsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GuideProjectsTableTable, GuideProjectRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $GuideProjectsTableTable,
                    GuideProjectRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GuideProjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuideProjectsTableTable,
      GuideProjectRow,
      $$GuideProjectsTableTableFilterComposer,
      $$GuideProjectsTableTableOrderingComposer,
      $$GuideProjectsTableTableAnnotationComposer,
      $$GuideProjectsTableTableCreateCompanionBuilder,
      $$GuideProjectsTableTableUpdateCompanionBuilder,
      (
        GuideProjectRow,
        BaseReferences<
          _$AppDatabase,
          $GuideProjectsTableTable,
          GuideProjectRow
        >,
      ),
      GuideProjectRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfileTableTableTableManager get userProfileTable =>
      $$UserProfileTableTableTableManager(_db, _db.userProfileTable);
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db, _db.spacesTable);
  $$ClimateMonthsTableTableTableManager get climateMonthsTable =>
      $$ClimateMonthsTableTableTableManager(_db, _db.climateMonthsTable);
  $$ClimateMetaTableTableTableManager get climateMetaTable =>
      $$ClimateMetaTableTableTableManager(_db, _db.climateMetaTable);
  $$WeatherDaysTableTableTableManager get weatherDaysTable =>
      $$WeatherDaysTableTableTableManager(_db, _db.weatherDaysTable);
  $$WeatherCurrentTableTableTableManager get weatherCurrentTable =>
      $$WeatherCurrentTableTableTableManager(_db, _db.weatherCurrentTable);
  $$PlantingsTableTableTableManager get plantingsTable =>
      $$PlantingsTableTableTableManager(_db, _db.plantingsTable);
  $$CareEventsTableTableTableManager get careEventsTable =>
      $$CareEventsTableTableTableManager(_db, _db.careEventsTable);
  $$GuideProjectsTableTableTableManager get guideProjectsTable =>
      $$GuideProjectsTableTableTableManager(_db, _db.guideProjectsTable);
}
