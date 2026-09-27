// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
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
  static const VerificationMeta _initialsMeta = const VerificationMeta(
    'initials',
  );
  @override
  late final GeneratedColumn<String> initials = GeneratedColumn<String>(
    'initials',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handicapIndexMeta = const VerificationMeta(
    'handicapIndex',
  );
  @override
  late final GeneratedColumn<double> handicapIndex = GeneratedColumn<double>(
    'handicap_index',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredTeeMeta = const VerificationMeta(
    'preferredTee',
  );
  @override
  late final GeneratedColumn<String> preferredTee = GeneratedColumn<String>(
    'preferred_tee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ghinNumberMeta = const VerificationMeta(
    'ghinNumber',
  );
  @override
  late final GeneratedColumn<String> ghinNumber = GeneratedColumn<String>(
    'ghin_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    nickname,
    initials,
    handicapIndex,
    preferredTee,
    ghinNumber,
    phoneNumber,
    email,
    photoPath,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('initials')) {
      context.handle(
        _initialsMeta,
        initials.isAcceptableOrUnknown(data['initials']!, _initialsMeta),
      );
    } else if (isInserting) {
      context.missing(_initialsMeta);
    }
    if (data.containsKey('handicap_index')) {
      context.handle(
        _handicapIndexMeta,
        handicapIndex.isAcceptableOrUnknown(
          data['handicap_index']!,
          _handicapIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_handicapIndexMeta);
    }
    if (data.containsKey('preferred_tee')) {
      context.handle(
        _preferredTeeMeta,
        preferredTee.isAcceptableOrUnknown(
          data['preferred_tee']!,
          _preferredTeeMeta,
        ),
      );
    }
    if (data.containsKey('ghin_number')) {
      context.handle(
        _ghinNumberMeta,
        ghinNumber.isAcceptableOrUnknown(data['ghin_number']!, _ghinNumberMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      initials: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initials'],
      )!,
      handicapIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}handicap_index'],
      )!,
      preferredTee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_tee'],
      ),
      ghinNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ghin_number'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final String id;
  final String fullName;
  final String nickname;
  final String initials;
  final double handicapIndex;
  final String? preferredTee;
  final String? ghinNumber;
  final String? phoneNumber;
  final String? email;
  final String? photoPath;
  final bool isActive;
  final int createdAt;
  const Player({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.initials,
    required this.handicapIndex,
    this.preferredTee,
    this.ghinNumber,
    this.phoneNumber,
    this.email,
    this.photoPath,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['nickname'] = Variable<String>(nickname);
    map['initials'] = Variable<String>(initials);
    map['handicap_index'] = Variable<double>(handicapIndex);
    if (!nullToAbsent || preferredTee != null) {
      map['preferred_tee'] = Variable<String>(preferredTee);
    }
    if (!nullToAbsent || ghinNumber != null) {
      map['ghin_number'] = Variable<String>(ghinNumber);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      nickname: Value(nickname),
      initials: Value(initials),
      handicapIndex: Value(handicapIndex),
      preferredTee: preferredTee == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredTee),
      ghinNumber: ghinNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(ghinNumber),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      nickname: serializer.fromJson<String>(json['nickname']),
      initials: serializer.fromJson<String>(json['initials']),
      handicapIndex: serializer.fromJson<double>(json['handicapIndex']),
      preferredTee: serializer.fromJson<String?>(json['preferredTee']),
      ghinNumber: serializer.fromJson<String?>(json['ghinNumber']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      email: serializer.fromJson<String?>(json['email']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'nickname': serializer.toJson<String>(nickname),
      'initials': serializer.toJson<String>(initials),
      'handicapIndex': serializer.toJson<double>(handicapIndex),
      'preferredTee': serializer.toJson<String?>(preferredTee),
      'ghinNumber': serializer.toJson<String?>(ghinNumber),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'email': serializer.toJson<String?>(email),
      'photoPath': serializer.toJson<String?>(photoPath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Player copyWith({
    String? id,
    String? fullName,
    String? nickname,
    String? initials,
    double? handicapIndex,
    Value<String?> preferredTee = const Value.absent(),
    Value<String?> ghinNumber = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    bool? isActive,
    int? createdAt,
  }) => Player(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    nickname: nickname ?? this.nickname,
    initials: initials ?? this.initials,
    handicapIndex: handicapIndex ?? this.handicapIndex,
    preferredTee: preferredTee.present ? preferredTee.value : this.preferredTee,
    ghinNumber: ghinNumber.present ? ghinNumber.value : this.ghinNumber,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    email: email.present ? email.value : this.email,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      initials: data.initials.present ? data.initials.value : this.initials,
      handicapIndex: data.handicapIndex.present
          ? data.handicapIndex.value
          : this.handicapIndex,
      preferredTee: data.preferredTee.present
          ? data.preferredTee.value
          : this.preferredTee,
      ghinNumber: data.ghinNumber.present
          ? data.ghinNumber.value
          : this.ghinNumber,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      email: data.email.present ? data.email.value : this.email,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('nickname: $nickname, ')
          ..write('initials: $initials, ')
          ..write('handicapIndex: $handicapIndex, ')
          ..write('preferredTee: $preferredTee, ')
          ..write('ghinNumber: $ghinNumber, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('photoPath: $photoPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    nickname,
    initials,
    handicapIndex,
    preferredTee,
    ghinNumber,
    phoneNumber,
    email,
    photoPath,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.nickname == this.nickname &&
          other.initials == this.initials &&
          other.handicapIndex == this.handicapIndex &&
          other.preferredTee == this.preferredTee &&
          other.ghinNumber == this.ghinNumber &&
          other.phoneNumber == this.phoneNumber &&
          other.email == this.email &&
          other.photoPath == this.photoPath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> nickname;
  final Value<String> initials;
  final Value<double> handicapIndex;
  final Value<String?> preferredTee;
  final Value<String?> ghinNumber;
  final Value<String?> phoneNumber;
  final Value<String?> email;
  final Value<String?> photoPath;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.nickname = const Value.absent(),
    this.initials = const Value.absent(),
    this.handicapIndex = const Value.absent(),
    this.preferredTee = const Value.absent(),
    this.ghinNumber = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String id,
    required String fullName,
    required String nickname,
    required String initials,
    required double handicapIndex,
    this.preferredTee = const Value.absent(),
    this.ghinNumber = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       nickname = Value(nickname),
       initials = Value(initials),
       handicapIndex = Value(handicapIndex),
       createdAt = Value(createdAt);
  static Insertable<Player> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? nickname,
    Expression<String>? initials,
    Expression<double>? handicapIndex,
    Expression<String>? preferredTee,
    Expression<String>? ghinNumber,
    Expression<String>? phoneNumber,
    Expression<String>? email,
    Expression<String>? photoPath,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (nickname != null) 'nickname': nickname,
      if (initials != null) 'initials': initials,
      if (handicapIndex != null) 'handicap_index': handicapIndex,
      if (preferredTee != null) 'preferred_tee': preferredTee,
      if (ghinNumber != null) 'ghin_number': ghinNumber,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (photoPath != null) 'photo_path': photoPath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? nickname,
    Value<String>? initials,
    Value<double>? handicapIndex,
    Value<String?>? preferredTee,
    Value<String?>? ghinNumber,
    Value<String?>? phoneNumber,
    Value<String?>? email,
    Value<String?>? photoPath,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      initials: initials ?? this.initials,
      handicapIndex: handicapIndex ?? this.handicapIndex,
      preferredTee: preferredTee ?? this.preferredTee,
      ghinNumber: ghinNumber ?? this.ghinNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
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
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (initials.present) {
      map['initials'] = Variable<String>(initials.value);
    }
    if (handicapIndex.present) {
      map['handicap_index'] = Variable<double>(handicapIndex.value);
    }
    if (preferredTee.present) {
      map['preferred_tee'] = Variable<String>(preferredTee.value);
    }
    if (ghinNumber.present) {
      map['ghin_number'] = Variable<String>(ghinNumber.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('nickname: $nickname, ')
          ..write('initials: $initials, ')
          ..write('handicapIndex: $handicapIndex, ')
          ..write('preferredTee: $preferredTee, ')
          ..write('ghinNumber: $ghinNumber, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('photoPath: $photoPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holeCountMeta = const VerificationMeta(
    'holeCount',
  );
  @override
  late final GeneratedColumn<int> holeCount = GeneratedColumn<int>(
    'hole_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(18),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    city,
    state,
    holeCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('hole_count')) {
      context.handle(
        _holeCountMeta,
        holeCount.isAcceptableOrUnknown(data['hole_count']!, _holeCountMeta),
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
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      holeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hole_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  final String id;
  final String name;
  final String city;
  final String state;
  final int holeCount;
  final int createdAt;
  const Course({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.holeCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['city'] = Variable<String>(city);
    map['state'] = Variable<String>(state);
    map['hole_count'] = Variable<int>(holeCount);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      name: Value(name),
      city: Value(city),
      state: Value(state),
      holeCount: Value(holeCount),
      createdAt: Value(createdAt),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      city: serializer.fromJson<String>(json['city']),
      state: serializer.fromJson<String>(json['state']),
      holeCount: serializer.fromJson<int>(json['holeCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'city': serializer.toJson<String>(city),
      'state': serializer.toJson<String>(state),
      'holeCount': serializer.toJson<int>(holeCount),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Course copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    int? holeCount,
    int? createdAt,
  }) => Course(
    id: id ?? this.id,
    name: name ?? this.name,
    city: city ?? this.city,
    state: state ?? this.state,
    holeCount: holeCount ?? this.holeCount,
    createdAt: createdAt ?? this.createdAt,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      holeCount: data.holeCount.present ? data.holeCount.value : this.holeCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('holeCount: $holeCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, city, state, holeCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.name == this.name &&
          other.city == this.city &&
          other.state == this.state &&
          other.holeCount == this.holeCount &&
          other.createdAt == this.createdAt);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> city;
  final Value<String> state;
  final Value<int> holeCount;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.holeCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoursesCompanion.insert({
    required String id,
    required String name,
    required String city,
    required String state,
    this.holeCount = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       city = Value(city),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<Course> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? city,
    Expression<String>? state,
    Expression<int>? holeCount,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (holeCount != null) 'hole_count': holeCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoursesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? city,
    Value<String>? state,
    Value<int>? holeCount,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      holeCount: holeCount ?? this.holeCount,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (holeCount.present) {
      map['hole_count'] = Variable<int>(holeCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('holeCount: $holeCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseHolesTable extends CourseHoles
    with TableInfo<$CourseHolesTable, CourseHole> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseHolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _holeNumberMeta = const VerificationMeta(
    'holeNumber',
  );
  @override
  late final GeneratedColumn<int> holeNumber = GeneratedColumn<int>(
    'hole_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parMeta = const VerificationMeta('par');
  @override
  late final GeneratedColumn<int> par = GeneratedColumn<int>(
    'par',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _strokeIndexMeta = const VerificationMeta(
    'strokeIndex',
  );
  @override
  late final GeneratedColumn<int> strokeIndex = GeneratedColumn<int>(
    'stroke_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(18),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    holeNumber,
    par,
    strokeIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_holes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseHole> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('hole_number')) {
      context.handle(
        _holeNumberMeta,
        holeNumber.isAcceptableOrUnknown(data['hole_number']!, _holeNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_holeNumberMeta);
    }
    if (data.containsKey('par')) {
      context.handle(
        _parMeta,
        par.isAcceptableOrUnknown(data['par']!, _parMeta),
      );
    }
    if (data.containsKey('stroke_index')) {
      context.handle(
        _strokeIndexMeta,
        strokeIndex.isAcceptableOrUnknown(
          data['stroke_index']!,
          _strokeIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {courseId, holeNumber},
  ];
  @override
  CourseHole map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseHole(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      holeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hole_number'],
      )!,
      par: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}par'],
      )!,
      strokeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_index'],
      )!,
    );
  }

  @override
  $CourseHolesTable createAlias(String alias) {
    return $CourseHolesTable(attachedDatabase, alias);
  }
}

class CourseHole extends DataClass implements Insertable<CourseHole> {
  final String id;
  final String courseId;
  final int holeNumber;
  final int par;
  final int strokeIndex;
  const CourseHole({
    required this.id,
    required this.courseId,
    required this.holeNumber,
    required this.par,
    required this.strokeIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['hole_number'] = Variable<int>(holeNumber);
    map['par'] = Variable<int>(par);
    map['stroke_index'] = Variable<int>(strokeIndex);
    return map;
  }

  CourseHolesCompanion toCompanion(bool nullToAbsent) {
    return CourseHolesCompanion(
      id: Value(id),
      courseId: Value(courseId),
      holeNumber: Value(holeNumber),
      par: Value(par),
      strokeIndex: Value(strokeIndex),
    );
  }

  factory CourseHole.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseHole(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      holeNumber: serializer.fromJson<int>(json['holeNumber']),
      par: serializer.fromJson<int>(json['par']),
      strokeIndex: serializer.fromJson<int>(json['strokeIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'holeNumber': serializer.toJson<int>(holeNumber),
      'par': serializer.toJson<int>(par),
      'strokeIndex': serializer.toJson<int>(strokeIndex),
    };
  }

  CourseHole copyWith({
    String? id,
    String? courseId,
    int? holeNumber,
    int? par,
    int? strokeIndex,
  }) => CourseHole(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    holeNumber: holeNumber ?? this.holeNumber,
    par: par ?? this.par,
    strokeIndex: strokeIndex ?? this.strokeIndex,
  );
  CourseHole copyWithCompanion(CourseHolesCompanion data) {
    return CourseHole(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      holeNumber: data.holeNumber.present
          ? data.holeNumber.value
          : this.holeNumber,
      par: data.par.present ? data.par.value : this.par,
      strokeIndex: data.strokeIndex.present
          ? data.strokeIndex.value
          : this.strokeIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseHole(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('holeNumber: $holeNumber, ')
          ..write('par: $par, ')
          ..write('strokeIndex: $strokeIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, courseId, holeNumber, par, strokeIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseHole &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.holeNumber == this.holeNumber &&
          other.par == this.par &&
          other.strokeIndex == this.strokeIndex);
}

class CourseHolesCompanion extends UpdateCompanion<CourseHole> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<int> holeNumber;
  final Value<int> par;
  final Value<int> strokeIndex;
  final Value<int> rowid;
  const CourseHolesCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.holeNumber = const Value.absent(),
    this.par = const Value.absent(),
    this.strokeIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseHolesCompanion.insert({
    required String id,
    required String courseId,
    required int holeNumber,
    this.par = const Value.absent(),
    this.strokeIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       holeNumber = Value(holeNumber);
  static Insertable<CourseHole> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<int>? holeNumber,
    Expression<int>? par,
    Expression<int>? strokeIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (holeNumber != null) 'hole_number': holeNumber,
      if (par != null) 'par': par,
      if (strokeIndex != null) 'stroke_index': strokeIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseHolesCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<int>? holeNumber,
    Value<int>? par,
    Value<int>? strokeIndex,
    Value<int>? rowid,
  }) {
    return CourseHolesCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      strokeIndex: strokeIndex ?? this.strokeIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (holeNumber.present) {
      map['hole_number'] = Variable<int>(holeNumber.value);
    }
    if (par.present) {
      map['par'] = Variable<int>(par.value);
    }
    if (strokeIndex.present) {
      map['stroke_index'] = Variable<int>(strokeIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseHolesCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('holeNumber: $holeNumber, ')
          ..write('par: $par, ')
          ..write('strokeIndex: $strokeIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeeBoxesTable extends TeeBoxes with TableInfo<$TeeBoxesTable, TeeBox> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeeBoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseRatingMeta = const VerificationMeta(
    'courseRating',
  );
  @override
  late final GeneratedColumn<double> courseRating = GeneratedColumn<double>(
    'course_rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slopeRatingMeta = const VerificationMeta(
    'slopeRating',
  );
  @override
  late final GeneratedColumn<int> slopeRating = GeneratedColumn<int>(
    'slope_rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalYardageMeta = const VerificationMeta(
    'totalYardage',
  );
  @override
  late final GeneratedColumn<int> totalYardage = GeneratedColumn<int>(
    'total_yardage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    name,
    colorHex,
    courseRating,
    slopeRating,
    totalYardage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tee_boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeeBox> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('course_rating')) {
      context.handle(
        _courseRatingMeta,
        courseRating.isAcceptableOrUnknown(
          data['course_rating']!,
          _courseRatingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseRatingMeta);
    }
    if (data.containsKey('slope_rating')) {
      context.handle(
        _slopeRatingMeta,
        slopeRating.isAcceptableOrUnknown(
          data['slope_rating']!,
          _slopeRatingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_slopeRatingMeta);
    }
    if (data.containsKey('total_yardage')) {
      context.handle(
        _totalYardageMeta,
        totalYardage.isAcceptableOrUnknown(
          data['total_yardage']!,
          _totalYardageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeeBox map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeeBox(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      courseRating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}course_rating'],
      )!,
      slopeRating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slope_rating'],
      )!,
      totalYardage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_yardage'],
      )!,
    );
  }

  @override
  $TeeBoxesTable createAlias(String alias) {
    return $TeeBoxesTable(attachedDatabase, alias);
  }
}

class TeeBox extends DataClass implements Insertable<TeeBox> {
  final String id;
  final String courseId;
  final String name;
  final String? colorHex;
  final double courseRating;
  final int slopeRating;
  final int totalYardage;
  const TeeBox({
    required this.id,
    required this.courseId,
    required this.name,
    this.colorHex,
    required this.courseRating,
    required this.slopeRating,
    required this.totalYardage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['course_rating'] = Variable<double>(courseRating);
    map['slope_rating'] = Variable<int>(slopeRating);
    map['total_yardage'] = Variable<int>(totalYardage);
    return map;
  }

  TeeBoxesCompanion toCompanion(bool nullToAbsent) {
    return TeeBoxesCompanion(
      id: Value(id),
      courseId: Value(courseId),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      courseRating: Value(courseRating),
      slopeRating: Value(slopeRating),
      totalYardage: Value(totalYardage),
    );
  }

  factory TeeBox.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeeBox(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['courseId']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      courseRating: serializer.fromJson<double>(json['courseRating']),
      slopeRating: serializer.fromJson<int>(json['slopeRating']),
      totalYardage: serializer.fromJson<int>(json['totalYardage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'courseId': serializer.toJson<String>(courseId),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'courseRating': serializer.toJson<double>(courseRating),
      'slopeRating': serializer.toJson<int>(slopeRating),
      'totalYardage': serializer.toJson<int>(totalYardage),
    };
  }

  TeeBox copyWith({
    String? id,
    String? courseId,
    String? name,
    Value<String?> colorHex = const Value.absent(),
    double? courseRating,
    int? slopeRating,
    int? totalYardage,
  }) => TeeBox(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    name: name ?? this.name,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    courseRating: courseRating ?? this.courseRating,
    slopeRating: slopeRating ?? this.slopeRating,
    totalYardage: totalYardage ?? this.totalYardage,
  );
  TeeBox copyWithCompanion(TeeBoxesCompanion data) {
    return TeeBox(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      courseRating: data.courseRating.present
          ? data.courseRating.value
          : this.courseRating,
      slopeRating: data.slopeRating.present
          ? data.slopeRating.value
          : this.slopeRating,
      totalYardage: data.totalYardage.present
          ? data.totalYardage.value
          : this.totalYardage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeeBox(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('courseRating: $courseRating, ')
          ..write('slopeRating: $slopeRating, ')
          ..write('totalYardage: $totalYardage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    name,
    colorHex,
    courseRating,
    slopeRating,
    totalYardage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeeBox &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.courseRating == this.courseRating &&
          other.slopeRating == this.slopeRating &&
          other.totalYardage == this.totalYardage);
}

class TeeBoxesCompanion extends UpdateCompanion<TeeBox> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<double> courseRating;
  final Value<int> slopeRating;
  final Value<int> totalYardage;
  final Value<int> rowid;
  const TeeBoxesCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.courseRating = const Value.absent(),
    this.slopeRating = const Value.absent(),
    this.totalYardage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeeBoxesCompanion.insert({
    required String id,
    required String courseId,
    required String name,
    this.colorHex = const Value.absent(),
    required double courseRating,
    required int slopeRating,
    this.totalYardage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       name = Value(name),
       courseRating = Value(courseRating),
       slopeRating = Value(slopeRating);
  static Insertable<TeeBox> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<double>? courseRating,
    Expression<int>? slopeRating,
    Expression<int>? totalYardage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (courseRating != null) 'course_rating': courseRating,
      if (slopeRating != null) 'slope_rating': slopeRating,
      if (totalYardage != null) 'total_yardage': totalYardage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeeBoxesCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? name,
    Value<String?>? colorHex,
    Value<double>? courseRating,
    Value<int>? slopeRating,
    Value<int>? totalYardage,
    Value<int>? rowid,
  }) {
    return TeeBoxesCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      courseRating: courseRating ?? this.courseRating,
      slopeRating: slopeRating ?? this.slopeRating,
      totalYardage: totalYardage ?? this.totalYardage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (courseRating.present) {
      map['course_rating'] = Variable<double>(courseRating.value);
    }
    if (slopeRating.present) {
      map['slope_rating'] = Variable<int>(slopeRating.value);
    }
    if (totalYardage.present) {
      map['total_yardage'] = Variable<int>(totalYardage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeeBoxesCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('courseRating: $courseRating, ')
          ..write('slopeRating: $slopeRating, ')
          ..write('totalYardage: $totalYardage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HoleYardagesTable extends HoleYardages
    with TableInfo<$HoleYardagesTable, HoleYardage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoleYardagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _teeBoxIdMeta = const VerificationMeta(
    'teeBoxId',
  );
  @override
  late final GeneratedColumn<String> teeBoxId = GeneratedColumn<String>(
    'tee_box_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tee_boxes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _courseHoleIdMeta = const VerificationMeta(
    'courseHoleId',
  );
  @override
  late final GeneratedColumn<String> courseHoleId = GeneratedColumn<String>(
    'course_hole_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_holes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _yardageMeta = const VerificationMeta(
    'yardage',
  );
  @override
  late final GeneratedColumn<int> yardage = GeneratedColumn<int>(
    'yardage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [teeBoxId, courseHoleId, yardage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hole_yardages';
  @override
  VerificationContext validateIntegrity(
    Insertable<HoleYardage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tee_box_id')) {
      context.handle(
        _teeBoxIdMeta,
        teeBoxId.isAcceptableOrUnknown(data['tee_box_id']!, _teeBoxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teeBoxIdMeta);
    }
    if (data.containsKey('course_hole_id')) {
      context.handle(
        _courseHoleIdMeta,
        courseHoleId.isAcceptableOrUnknown(
          data['course_hole_id']!,
          _courseHoleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_courseHoleIdMeta);
    }
    if (data.containsKey('yardage')) {
      context.handle(
        _yardageMeta,
        yardage.isAcceptableOrUnknown(data['yardage']!, _yardageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {teeBoxId, courseHoleId};
  @override
  HoleYardage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HoleYardage(
      teeBoxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tee_box_id'],
      )!,
      courseHoleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_hole_id'],
      )!,
      yardage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yardage'],
      )!,
    );
  }

  @override
  $HoleYardagesTable createAlias(String alias) {
    return $HoleYardagesTable(attachedDatabase, alias);
  }
}

class HoleYardage extends DataClass implements Insertable<HoleYardage> {
  final String teeBoxId;
  final String courseHoleId;
  final int yardage;
  const HoleYardage({
    required this.teeBoxId,
    required this.courseHoleId,
    required this.yardage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tee_box_id'] = Variable<String>(teeBoxId);
    map['course_hole_id'] = Variable<String>(courseHoleId);
    map['yardage'] = Variable<int>(yardage);
    return map;
  }

  HoleYardagesCompanion toCompanion(bool nullToAbsent) {
    return HoleYardagesCompanion(
      teeBoxId: Value(teeBoxId),
      courseHoleId: Value(courseHoleId),
      yardage: Value(yardage),
    );
  }

  factory HoleYardage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HoleYardage(
      teeBoxId: serializer.fromJson<String>(json['teeBoxId']),
      courseHoleId: serializer.fromJson<String>(json['courseHoleId']),
      yardage: serializer.fromJson<int>(json['yardage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'teeBoxId': serializer.toJson<String>(teeBoxId),
      'courseHoleId': serializer.toJson<String>(courseHoleId),
      'yardage': serializer.toJson<int>(yardage),
    };
  }

  HoleYardage copyWith({
    String? teeBoxId,
    String? courseHoleId,
    int? yardage,
  }) => HoleYardage(
    teeBoxId: teeBoxId ?? this.teeBoxId,
    courseHoleId: courseHoleId ?? this.courseHoleId,
    yardage: yardage ?? this.yardage,
  );
  HoleYardage copyWithCompanion(HoleYardagesCompanion data) {
    return HoleYardage(
      teeBoxId: data.teeBoxId.present ? data.teeBoxId.value : this.teeBoxId,
      courseHoleId: data.courseHoleId.present
          ? data.courseHoleId.value
          : this.courseHoleId,
      yardage: data.yardage.present ? data.yardage.value : this.yardage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HoleYardage(')
          ..write('teeBoxId: $teeBoxId, ')
          ..write('courseHoleId: $courseHoleId, ')
          ..write('yardage: $yardage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(teeBoxId, courseHoleId, yardage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HoleYardage &&
          other.teeBoxId == this.teeBoxId &&
          other.courseHoleId == this.courseHoleId &&
          other.yardage == this.yardage);
}

class HoleYardagesCompanion extends UpdateCompanion<HoleYardage> {
  final Value<String> teeBoxId;
  final Value<String> courseHoleId;
  final Value<int> yardage;
  final Value<int> rowid;
  const HoleYardagesCompanion({
    this.teeBoxId = const Value.absent(),
    this.courseHoleId = const Value.absent(),
    this.yardage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HoleYardagesCompanion.insert({
    required String teeBoxId,
    required String courseHoleId,
    this.yardage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : teeBoxId = Value(teeBoxId),
       courseHoleId = Value(courseHoleId);
  static Insertable<HoleYardage> custom({
    Expression<String>? teeBoxId,
    Expression<String>? courseHoleId,
    Expression<int>? yardage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (teeBoxId != null) 'tee_box_id': teeBoxId,
      if (courseHoleId != null) 'course_hole_id': courseHoleId,
      if (yardage != null) 'yardage': yardage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HoleYardagesCompanion copyWith({
    Value<String>? teeBoxId,
    Value<String>? courseHoleId,
    Value<int>? yardage,
    Value<int>? rowid,
  }) {
    return HoleYardagesCompanion(
      teeBoxId: teeBoxId ?? this.teeBoxId,
      courseHoleId: courseHoleId ?? this.courseHoleId,
      yardage: yardage ?? this.yardage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (teeBoxId.present) {
      map['tee_box_id'] = Variable<String>(teeBoxId.value);
    }
    if (courseHoleId.present) {
      map['course_hole_id'] = Variable<String>(courseHoleId.value);
    }
    if (yardage.present) {
      map['yardage'] = Variable<int>(yardage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoleYardagesCompanion(')
          ..write('teeBoxId: $teeBoxId, ')
          ..write('courseHoleId: $courseHoleId, ')
          ..write('yardage: $yardage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TournamentsTable extends Tournaments
    with TableInfo<$TournamentsTable, Tournament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TournamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<int> endDate = GeneratedColumn<int>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatTypeMeta = const VerificationMeta(
    'formatType',
  );
  @override
  late final GeneratedColumn<String> formatType = GeneratedColumn<String>(
    'format_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('hybrid'),
  );
  static const VerificationMeta _teamANameMeta = const VerificationMeta(
    'teamAName',
  );
  @override
  late final GeneratedColumn<String> teamAName = GeneratedColumn<String>(
    'team_a_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Team Blue'),
  );
  static const VerificationMeta _teamBNameMeta = const VerificationMeta(
    'teamBName',
  );
  @override
  late final GeneratedColumn<String> teamBName = GeneratedColumn<String>(
    'team_b_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Team Red'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startDate,
    endDate,
    formatType,
    teamAName,
    teamBName,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tournament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('format_type')) {
      context.handle(
        _formatTypeMeta,
        formatType.isAcceptableOrUnknown(data['format_type']!, _formatTypeMeta),
      );
    }
    if (data.containsKey('team_a_name')) {
      context.handle(
        _teamANameMeta,
        teamAName.isAcceptableOrUnknown(data['team_a_name']!, _teamANameMeta),
      );
    }
    if (data.containsKey('team_b_name')) {
      context.handle(
        _teamBNameMeta,
        teamBName.isAcceptableOrUnknown(data['team_b_name']!, _teamBNameMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  Tournament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tournament(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_date'],
      )!,
      formatType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format_type'],
      )!,
      teamAName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_a_name'],
      )!,
      teamBName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_b_name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TournamentsTable createAlias(String alias) {
    return $TournamentsTable(attachedDatabase, alias);
  }
}

class Tournament extends DataClass implements Insertable<Tournament> {
  final String id;
  final String name;
  final int startDate;
  final int endDate;
  final String formatType;
  final String teamAName;
  final String teamBName;
  final bool isActive;
  final int createdAt;
  const Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.formatType,
    required this.teamAName,
    required this.teamBName,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<int>(startDate);
    map['end_date'] = Variable<int>(endDate);
    map['format_type'] = Variable<String>(formatType);
    map['team_a_name'] = Variable<String>(teamAName);
    map['team_b_name'] = Variable<String>(teamBName);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TournamentsCompanion toCompanion(bool nullToAbsent) {
    return TournamentsCompanion(
      id: Value(id),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      formatType: Value(formatType),
      teamAName: Value(teamAName),
      teamBName: Value(teamBName),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Tournament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tournament(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<int>(json['startDate']),
      endDate: serializer.fromJson<int>(json['endDate']),
      formatType: serializer.fromJson<String>(json['formatType']),
      teamAName: serializer.fromJson<String>(json['teamAName']),
      teamBName: serializer.fromJson<String>(json['teamBName']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<int>(startDate),
      'endDate': serializer.toJson<int>(endDate),
      'formatType': serializer.toJson<String>(formatType),
      'teamAName': serializer.toJson<String>(teamAName),
      'teamBName': serializer.toJson<String>(teamBName),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    int? startDate,
    int? endDate,
    String? formatType,
    String? teamAName,
    String? teamBName,
    bool? isActive,
    int? createdAt,
  }) => Tournament(
    id: id ?? this.id,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    formatType: formatType ?? this.formatType,
    teamAName: teamAName ?? this.teamAName,
    teamBName: teamBName ?? this.teamBName,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  Tournament copyWithCompanion(TournamentsCompanion data) {
    return Tournament(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      formatType: data.formatType.present
          ? data.formatType.value
          : this.formatType,
      teamAName: data.teamAName.present ? data.teamAName.value : this.teamAName,
      teamBName: data.teamBName.present ? data.teamBName.value : this.teamBName,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tournament(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('formatType: $formatType, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startDate,
    endDate,
    formatType,
    teamAName,
    teamBName,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tournament &&
          other.id == this.id &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.formatType == this.formatType &&
          other.teamAName == this.teamAName &&
          other.teamBName == this.teamBName &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class TournamentsCompanion extends UpdateCompanion<Tournament> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> startDate;
  final Value<int> endDate;
  final Value<String> formatType;
  final Value<String> teamAName;
  final Value<String> teamBName;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TournamentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.formatType = const Value.absent(),
    this.teamAName = const Value.absent(),
    this.teamBName = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TournamentsCompanion.insert({
    required String id,
    required String name,
    required int startDate,
    required int endDate,
    this.formatType = const Value.absent(),
    this.teamAName = const Value.absent(),
    this.teamBName = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate),
       endDate = Value(endDate),
       createdAt = Value(createdAt);
  static Insertable<Tournament> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? startDate,
    Expression<int>? endDate,
    Expression<String>? formatType,
    Expression<String>? teamAName,
    Expression<String>? teamBName,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (formatType != null) 'format_type': formatType,
      if (teamAName != null) 'team_a_name': teamAName,
      if (teamBName != null) 'team_b_name': teamBName,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TournamentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? startDate,
    Value<int>? endDate,
    Value<String>? formatType,
    Value<String>? teamAName,
    Value<String>? teamBName,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return TournamentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      formatType: formatType ?? this.formatType,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      isActive: isActive ?? this.isActive,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<int>(endDate.value);
    }
    if (formatType.present) {
      map['format_type'] = Variable<String>(formatType.value);
    }
    if (teamAName.present) {
      map['team_a_name'] = Variable<String>(teamAName.value);
    }
    if (teamBName.present) {
      map['team_b_name'] = Variable<String>(teamBName.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TournamentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('formatType: $formatType, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TournamentPlayersTable extends TournamentPlayers
    with TableInfo<$TournamentPlayersTable, TournamentPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TournamentPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tournaments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _customHandicapMeta = const VerificationMeta(
    'customHandicap',
  );
  @override
  late final GeneratedColumn<double> customHandicap = GeneratedColumn<double>(
    'custom_handicap',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tournamentId,
    playerId,
    teamId,
    customHandicap,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournament_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<TournamentPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('custom_handicap')) {
      context.handle(
        _customHandicapMeta,
        customHandicap.isAcceptableOrUnknown(
          data['custom_handicap']!,
          _customHandicapMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tournamentId, playerId};
  @override
  TournamentPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TournamentPlayer(
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournament_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      customHandicap: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}custom_handicap'],
      ),
    );
  }

  @override
  $TournamentPlayersTable createAlias(String alias) {
    return $TournamentPlayersTable(attachedDatabase, alias);
  }
}

class TournamentPlayer extends DataClass
    implements Insertable<TournamentPlayer> {
  final String tournamentId;
  final String playerId;
  final String teamId;
  final double? customHandicap;
  const TournamentPlayer({
    required this.tournamentId,
    required this.playerId,
    required this.teamId,
    this.customHandicap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tournament_id'] = Variable<String>(tournamentId);
    map['player_id'] = Variable<String>(playerId);
    map['team_id'] = Variable<String>(teamId);
    if (!nullToAbsent || customHandicap != null) {
      map['custom_handicap'] = Variable<double>(customHandicap);
    }
    return map;
  }

  TournamentPlayersCompanion toCompanion(bool nullToAbsent) {
    return TournamentPlayersCompanion(
      tournamentId: Value(tournamentId),
      playerId: Value(playerId),
      teamId: Value(teamId),
      customHandicap: customHandicap == null && nullToAbsent
          ? const Value.absent()
          : Value(customHandicap),
    );
  }

  factory TournamentPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TournamentPlayer(
      tournamentId: serializer.fromJson<String>(json['tournamentId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      teamId: serializer.fromJson<String>(json['teamId']),
      customHandicap: serializer.fromJson<double?>(json['customHandicap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tournamentId': serializer.toJson<String>(tournamentId),
      'playerId': serializer.toJson<String>(playerId),
      'teamId': serializer.toJson<String>(teamId),
      'customHandicap': serializer.toJson<double?>(customHandicap),
    };
  }

  TournamentPlayer copyWith({
    String? tournamentId,
    String? playerId,
    String? teamId,
    Value<double?> customHandicap = const Value.absent(),
  }) => TournamentPlayer(
    tournamentId: tournamentId ?? this.tournamentId,
    playerId: playerId ?? this.playerId,
    teamId: teamId ?? this.teamId,
    customHandicap: customHandicap.present
        ? customHandicap.value
        : this.customHandicap,
  );
  TournamentPlayer copyWithCompanion(TournamentPlayersCompanion data) {
    return TournamentPlayer(
      tournamentId: data.tournamentId.present
          ? data.tournamentId.value
          : this.tournamentId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      customHandicap: data.customHandicap.present
          ? data.customHandicap.value
          : this.customHandicap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TournamentPlayer(')
          ..write('tournamentId: $tournamentId, ')
          ..write('playerId: $playerId, ')
          ..write('teamId: $teamId, ')
          ..write('customHandicap: $customHandicap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tournamentId, playerId, teamId, customHandicap);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TournamentPlayer &&
          other.tournamentId == this.tournamentId &&
          other.playerId == this.playerId &&
          other.teamId == this.teamId &&
          other.customHandicap == this.customHandicap);
}

class TournamentPlayersCompanion extends UpdateCompanion<TournamentPlayer> {
  final Value<String> tournamentId;
  final Value<String> playerId;
  final Value<String> teamId;
  final Value<double?> customHandicap;
  final Value<int> rowid;
  const TournamentPlayersCompanion({
    this.tournamentId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.customHandicap = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TournamentPlayersCompanion.insert({
    required String tournamentId,
    required String playerId,
    this.teamId = const Value.absent(),
    this.customHandicap = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tournamentId = Value(tournamentId),
       playerId = Value(playerId);
  static Insertable<TournamentPlayer> custom({
    Expression<String>? tournamentId,
    Expression<String>? playerId,
    Expression<String>? teamId,
    Expression<double>? customHandicap,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (playerId != null) 'player_id': playerId,
      if (teamId != null) 'team_id': teamId,
      if (customHandicap != null) 'custom_handicap': customHandicap,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TournamentPlayersCompanion copyWith({
    Value<String>? tournamentId,
    Value<String>? playerId,
    Value<String>? teamId,
    Value<double?>? customHandicap,
    Value<int>? rowid,
  }) {
    return TournamentPlayersCompanion(
      tournamentId: tournamentId ?? this.tournamentId,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      customHandicap: customHandicap ?? this.customHandicap,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (customHandicap.present) {
      map['custom_handicap'] = Variable<double>(customHandicap.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TournamentPlayersCompanion(')
          ..write('tournamentId: $tournamentId, ')
          ..write('playerId: $playerId, ')
          ..write('teamId: $teamId, ')
          ..write('customHandicap: $customHandicap, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedRoundsTable extends SavedRounds
    with TableInfo<$SavedRoundsTable, SavedRound> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedRoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tournaments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundNumberMeta = const VerificationMeta(
    'roundNumber',
  );
  @override
  late final GeneratedColumn<int> roundNumber = GeneratedColumn<int>(
    'round_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _datePlayedMeta = const VerificationMeta(
    'datePlayed',
  );
  @override
  late final GeneratedColumn<int> datePlayed = GeneratedColumn<int>(
    'date_played',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('stroke'),
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _winnerNameMeta = const VerificationMeta(
    'winnerName',
  );
  @override
  late final GeneratedColumn<String> winnerName = GeneratedColumn<String>(
    'winner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roundPayloadJsonMeta = const VerificationMeta(
    'roundPayloadJson',
  );
  @override
  late final GeneratedColumn<String> roundPayloadJson = GeneratedColumn<String>(
    'round_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tournamentId,
    courseId,
    courseName,
    roundNumber,
    datePlayed,
    format,
    isComplete,
    winnerName,
    roundPayloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedRound> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('round_number')) {
      context.handle(
        _roundNumberMeta,
        roundNumber.isAcceptableOrUnknown(
          data['round_number']!,
          _roundNumberMeta,
        ),
      );
    }
    if (data.containsKey('date_played')) {
      context.handle(
        _datePlayedMeta,
        datePlayed.isAcceptableOrUnknown(data['date_played']!, _datePlayedMeta),
      );
    } else if (isInserting) {
      context.missing(_datePlayedMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('winner_name')) {
      context.handle(
        _winnerNameMeta,
        winnerName.isAcceptableOrUnknown(data['winner_name']!, _winnerNameMeta),
      );
    }
    if (data.containsKey('round_payload_json')) {
      context.handle(
        _roundPayloadJsonMeta,
        roundPayloadJson.isAcceptableOrUnknown(
          data['round_payload_json']!,
          _roundPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundPayloadJsonMeta);
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
  SavedRound map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedRound(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournament_id'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      )!,
      roundNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_number'],
      )!,
      datePlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_played'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      winnerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_name'],
      ),
      roundPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedRoundsTable createAlias(String alias) {
    return $SavedRoundsTable(attachedDatabase, alias);
  }
}

class SavedRound extends DataClass implements Insertable<SavedRound> {
  final String id;
  final String? tournamentId;
  final String courseId;
  final String courseName;
  final int roundNumber;
  final int datePlayed;
  final String format;
  final bool isComplete;
  final String? winnerName;
  final String roundPayloadJson;
  final int createdAt;
  const SavedRound({
    required this.id,
    this.tournamentId,
    required this.courseId,
    required this.courseName,
    required this.roundNumber,
    required this.datePlayed,
    required this.format,
    required this.isComplete,
    this.winnerName,
    required this.roundPayloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || tournamentId != null) {
      map['tournament_id'] = Variable<String>(tournamentId);
    }
    map['course_id'] = Variable<String>(courseId);
    map['course_name'] = Variable<String>(courseName);
    map['round_number'] = Variable<int>(roundNumber);
    map['date_played'] = Variable<int>(datePlayed);
    map['format'] = Variable<String>(format);
    map['is_complete'] = Variable<bool>(isComplete);
    if (!nullToAbsent || winnerName != null) {
      map['winner_name'] = Variable<String>(winnerName);
    }
    map['round_payload_json'] = Variable<String>(roundPayloadJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SavedRoundsCompanion toCompanion(bool nullToAbsent) {
    return SavedRoundsCompanion(
      id: Value(id),
      tournamentId: tournamentId == null && nullToAbsent
          ? const Value.absent()
          : Value(tournamentId),
      courseId: Value(courseId),
      courseName: Value(courseName),
      roundNumber: Value(roundNumber),
      datePlayed: Value(datePlayed),
      format: Value(format),
      isComplete: Value(isComplete),
      winnerName: winnerName == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerName),
      roundPayloadJson: Value(roundPayloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory SavedRound.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedRound(
      id: serializer.fromJson<String>(json['id']),
      tournamentId: serializer.fromJson<String?>(json['tournamentId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      courseName: serializer.fromJson<String>(json['courseName']),
      roundNumber: serializer.fromJson<int>(json['roundNumber']),
      datePlayed: serializer.fromJson<int>(json['datePlayed']),
      format: serializer.fromJson<String>(json['format']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      winnerName: serializer.fromJson<String?>(json['winnerName']),
      roundPayloadJson: serializer.fromJson<String>(json['roundPayloadJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tournamentId': serializer.toJson<String?>(tournamentId),
      'courseId': serializer.toJson<String>(courseId),
      'courseName': serializer.toJson<String>(courseName),
      'roundNumber': serializer.toJson<int>(roundNumber),
      'datePlayed': serializer.toJson<int>(datePlayed),
      'format': serializer.toJson<String>(format),
      'isComplete': serializer.toJson<bool>(isComplete),
      'winnerName': serializer.toJson<String?>(winnerName),
      'roundPayloadJson': serializer.toJson<String>(roundPayloadJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SavedRound copyWith({
    String? id,
    Value<String?> tournamentId = const Value.absent(),
    String? courseId,
    String? courseName,
    int? roundNumber,
    int? datePlayed,
    String? format,
    bool? isComplete,
    Value<String?> winnerName = const Value.absent(),
    String? roundPayloadJson,
    int? createdAt,
  }) => SavedRound(
    id: id ?? this.id,
    tournamentId: tournamentId.present ? tournamentId.value : this.tournamentId,
    courseId: courseId ?? this.courseId,
    courseName: courseName ?? this.courseName,
    roundNumber: roundNumber ?? this.roundNumber,
    datePlayed: datePlayed ?? this.datePlayed,
    format: format ?? this.format,
    isComplete: isComplete ?? this.isComplete,
    winnerName: winnerName.present ? winnerName.value : this.winnerName,
    roundPayloadJson: roundPayloadJson ?? this.roundPayloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedRound copyWithCompanion(SavedRoundsCompanion data) {
    return SavedRound(
      id: data.id.present ? data.id.value : this.id,
      tournamentId: data.tournamentId.present
          ? data.tournamentId.value
          : this.tournamentId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      roundNumber: data.roundNumber.present
          ? data.roundNumber.value
          : this.roundNumber,
      datePlayed: data.datePlayed.present
          ? data.datePlayed.value
          : this.datePlayed,
      format: data.format.present ? data.format.value : this.format,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      winnerName: data.winnerName.present
          ? data.winnerName.value
          : this.winnerName,
      roundPayloadJson: data.roundPayloadJson.present
          ? data.roundPayloadJson.value
          : this.roundPayloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedRound(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('datePlayed: $datePlayed, ')
          ..write('format: $format, ')
          ..write('isComplete: $isComplete, ')
          ..write('winnerName: $winnerName, ')
          ..write('roundPayloadJson: $roundPayloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tournamentId,
    courseId,
    courseName,
    roundNumber,
    datePlayed,
    format,
    isComplete,
    winnerName,
    roundPayloadJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedRound &&
          other.id == this.id &&
          other.tournamentId == this.tournamentId &&
          other.courseId == this.courseId &&
          other.courseName == this.courseName &&
          other.roundNumber == this.roundNumber &&
          other.datePlayed == this.datePlayed &&
          other.format == this.format &&
          other.isComplete == this.isComplete &&
          other.winnerName == this.winnerName &&
          other.roundPayloadJson == this.roundPayloadJson &&
          other.createdAt == this.createdAt);
}

class SavedRoundsCompanion extends UpdateCompanion<SavedRound> {
  final Value<String> id;
  final Value<String?> tournamentId;
  final Value<String> courseId;
  final Value<String> courseName;
  final Value<int> roundNumber;
  final Value<int> datePlayed;
  final Value<String> format;
  final Value<bool> isComplete;
  final Value<String?> winnerName;
  final Value<String> roundPayloadJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SavedRoundsCompanion({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.courseName = const Value.absent(),
    this.roundNumber = const Value.absent(),
    this.datePlayed = const Value.absent(),
    this.format = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.winnerName = const Value.absent(),
    this.roundPayloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedRoundsCompanion.insert({
    required String id,
    this.tournamentId = const Value.absent(),
    required String courseId,
    required String courseName,
    this.roundNumber = const Value.absent(),
    required int datePlayed,
    this.format = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.winnerName = const Value.absent(),
    required String roundPayloadJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       courseName = Value(courseName),
       datePlayed = Value(datePlayed),
       roundPayloadJson = Value(roundPayloadJson),
       createdAt = Value(createdAt);
  static Insertable<SavedRound> custom({
    Expression<String>? id,
    Expression<String>? tournamentId,
    Expression<String>? courseId,
    Expression<String>? courseName,
    Expression<int>? roundNumber,
    Expression<int>? datePlayed,
    Expression<String>? format,
    Expression<bool>? isComplete,
    Expression<String>? winnerName,
    Expression<String>? roundPayloadJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (courseId != null) 'course_id': courseId,
      if (courseName != null) 'course_name': courseName,
      if (roundNumber != null) 'round_number': roundNumber,
      if (datePlayed != null) 'date_played': datePlayed,
      if (format != null) 'format': format,
      if (isComplete != null) 'is_complete': isComplete,
      if (winnerName != null) 'winner_name': winnerName,
      if (roundPayloadJson != null) 'round_payload_json': roundPayloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedRoundsCompanion copyWith({
    Value<String>? id,
    Value<String?>? tournamentId,
    Value<String>? courseId,
    Value<String>? courseName,
    Value<int>? roundNumber,
    Value<int>? datePlayed,
    Value<String>? format,
    Value<bool>? isComplete,
    Value<String?>? winnerName,
    Value<String>? roundPayloadJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedRoundsCompanion(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      roundNumber: roundNumber ?? this.roundNumber,
      datePlayed: datePlayed ?? this.datePlayed,
      format: format ?? this.format,
      isComplete: isComplete ?? this.isComplete,
      winnerName: winnerName ?? this.winnerName,
      roundPayloadJson: roundPayloadJson ?? this.roundPayloadJson,
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
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (roundNumber.present) {
      map['round_number'] = Variable<int>(roundNumber.value);
    }
    if (datePlayed.present) {
      map['date_played'] = Variable<int>(datePlayed.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (winnerName.present) {
      map['winner_name'] = Variable<String>(winnerName.value);
    }
    if (roundPayloadJson.present) {
      map['round_payload_json'] = Variable<String>(roundPayloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedRoundsCompanion(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('roundNumber: $roundNumber, ')
          ..write('datePlayed: $datePlayed, ')
          ..write('format: $format, ')
          ..write('isComplete: $isComplete, ')
          ..write('winnerName: $winnerName, ')
          ..write('roundPayloadJson: $roundPayloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActiveRoundDraftTable extends ActiveRoundDraft
    with TableInfo<$ActiveRoundDraftTable, ActiveRoundDraftData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveRoundDraftTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<String> tournamentId = GeneratedColumn<String>(
    'tournament_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundPayloadJsonMeta = const VerificationMeta(
    'roundPayloadJson',
  );
  @override
  late final GeneratedColumn<String> roundPayloadJson = GeneratedColumn<String>(
    'round_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tournamentId,
    courseId,
    roundPayloadJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_round_draft';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveRoundDraftData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('round_payload_json')) {
      context.handle(
        _roundPayloadJsonMeta,
        roundPayloadJson.isAcceptableOrUnknown(
          data['round_payload_json']!,
          _roundPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roundPayloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveRoundDraftData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveRoundDraftData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournament_id'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      roundPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActiveRoundDraftTable createAlias(String alias) {
    return $ActiveRoundDraftTable(attachedDatabase, alias);
  }
}

class ActiveRoundDraftData extends DataClass
    implements Insertable<ActiveRoundDraftData> {
  final int id;
  final String? tournamentId;
  final String courseId;
  final String roundPayloadJson;
  final int updatedAt;
  const ActiveRoundDraftData({
    required this.id,
    this.tournamentId,
    required this.courseId,
    required this.roundPayloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tournamentId != null) {
      map['tournament_id'] = Variable<String>(tournamentId);
    }
    map['course_id'] = Variable<String>(courseId);
    map['round_payload_json'] = Variable<String>(roundPayloadJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ActiveRoundDraftCompanion toCompanion(bool nullToAbsent) {
    return ActiveRoundDraftCompanion(
      id: Value(id),
      tournamentId: tournamentId == null && nullToAbsent
          ? const Value.absent()
          : Value(tournamentId),
      courseId: Value(courseId),
      roundPayloadJson: Value(roundPayloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActiveRoundDraftData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveRoundDraftData(
      id: serializer.fromJson<int>(json['id']),
      tournamentId: serializer.fromJson<String?>(json['tournamentId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      roundPayloadJson: serializer.fromJson<String>(json['roundPayloadJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tournamentId': serializer.toJson<String?>(tournamentId),
      'courseId': serializer.toJson<String>(courseId),
      'roundPayloadJson': serializer.toJson<String>(roundPayloadJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ActiveRoundDraftData copyWith({
    int? id,
    Value<String?> tournamentId = const Value.absent(),
    String? courseId,
    String? roundPayloadJson,
    int? updatedAt,
  }) => ActiveRoundDraftData(
    id: id ?? this.id,
    tournamentId: tournamentId.present ? tournamentId.value : this.tournamentId,
    courseId: courseId ?? this.courseId,
    roundPayloadJson: roundPayloadJson ?? this.roundPayloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActiveRoundDraftData copyWithCompanion(ActiveRoundDraftCompanion data) {
    return ActiveRoundDraftData(
      id: data.id.present ? data.id.value : this.id,
      tournamentId: data.tournamentId.present
          ? data.tournamentId.value
          : this.tournamentId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      roundPayloadJson: data.roundPayloadJson.present
          ? data.roundPayloadJson.value
          : this.roundPayloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveRoundDraftData(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('courseId: $courseId, ')
          ..write('roundPayloadJson: $roundPayloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tournamentId, courseId, roundPayloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveRoundDraftData &&
          other.id == this.id &&
          other.tournamentId == this.tournamentId &&
          other.courseId == this.courseId &&
          other.roundPayloadJson == this.roundPayloadJson &&
          other.updatedAt == this.updatedAt);
}

class ActiveRoundDraftCompanion extends UpdateCompanion<ActiveRoundDraftData> {
  final Value<int> id;
  final Value<String?> tournamentId;
  final Value<String> courseId;
  final Value<String> roundPayloadJson;
  final Value<int> updatedAt;
  const ActiveRoundDraftCompanion({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.roundPayloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActiveRoundDraftCompanion.insert({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    required String courseId,
    required String roundPayloadJson,
    required int updatedAt,
  }) : courseId = Value(courseId),
       roundPayloadJson = Value(roundPayloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<ActiveRoundDraftData> custom({
    Expression<int>? id,
    Expression<String>? tournamentId,
    Expression<String>? courseId,
    Expression<String>? roundPayloadJson,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (courseId != null) 'course_id': courseId,
      if (roundPayloadJson != null) 'round_payload_json': roundPayloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActiveRoundDraftCompanion copyWith({
    Value<int>? id,
    Value<String?>? tournamentId,
    Value<String>? courseId,
    Value<String>? roundPayloadJson,
    Value<int>? updatedAt,
  }) {
    return ActiveRoundDraftCompanion(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      courseId: courseId ?? this.courseId,
      roundPayloadJson: roundPayloadJson ?? this.roundPayloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<String>(tournamentId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (roundPayloadJson.present) {
      map['round_payload_json'] = Variable<String>(roundPayloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveRoundDraftCompanion(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('courseId: $courseId, ')
          ..write('roundPayloadJson: $roundPayloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, settingsJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String settingsJson;
  final int updatedAt;
  const AppSetting({
    required this.id,
    required this.settingsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['settings_json'] = Variable<String>(settingsJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      settingsJson: Value(settingsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'settingsJson': serializer.toJson<String>(settingsJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith({int? id, String? settingsJson, int? updatedAt}) =>
      AppSetting(
        id: id ?? this.id,
        settingsJson: settingsJson ?? this.settingsJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, settingsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.settingsJson == this.settingsJson &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> settingsJson;
  final Value<int> updatedAt;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String settingsJson,
    required int updatedAt,
  }) : settingsJson = Value(settingsJson),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? settingsJson,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? settingsJson,
    Value<int>? updatedAt,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      settingsJson: settingsJson ?? this.settingsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $CourseHolesTable courseHoles = $CourseHolesTable(this);
  late final $TeeBoxesTable teeBoxes = $TeeBoxesTable(this);
  late final $HoleYardagesTable holeYardages = $HoleYardagesTable(this);
  late final $TournamentsTable tournaments = $TournamentsTable(this);
  late final $TournamentPlayersTable tournamentPlayers =
      $TournamentPlayersTable(this);
  late final $SavedRoundsTable savedRounds = $SavedRoundsTable(this);
  late final $ActiveRoundDraftTable activeRoundDraft = $ActiveRoundDraftTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    courses,
    courseHoles,
    teeBoxes,
    holeYardages,
    tournaments,
    tournamentPlayers,
    savedRounds,
    activeRoundDraft,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'courses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_holes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'courses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tee_boxes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tee_boxes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hole_yardages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_holes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('hole_yardages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tournaments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tournament_players', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tournament_players', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tournaments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('saved_rounds', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      required String id,
      required String fullName,
      required String nickname,
      required String initials,
      required double handicapIndex,
      Value<String?> preferredTee,
      Value<String?> ghinNumber,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<String?> photoPath,
      Value<bool> isActive,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String> nickname,
      Value<String> initials,
      Value<double> handicapIndex,
      Value<String?> preferredTee,
      Value<String?> ghinNumber,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<String?> photoPath,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, Player> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TournamentPlayersTable, List<TournamentPlayer>>
  _tournamentPlayersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.tournamentPlayers,
        aliasName: 'players__id__tournament_players__player_id',
      );

  $$TournamentPlayersTableProcessedTableManager get tournamentPlayersRefs {
    final manager = $$TournamentPlayersTableTableManager(
      $_db,
      $_db.tournamentPlayers,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _tournamentPlayersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initials => $composableBuilder(
    column: $table.initials,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get handicapIndex => $composableBuilder(
    column: $table.handicapIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredTee => $composableBuilder(
    column: $table.preferredTee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ghinNumber => $composableBuilder(
    column: $table.ghinNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tournamentPlayersRefs(
    Expression<bool> Function($$TournamentPlayersTableFilterComposer f) f,
  ) {
    final $$TournamentPlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tournamentPlayers,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentPlayersTableFilterComposer(
            $db: $db,
            $table: $db.tournamentPlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initials => $composableBuilder(
    column: $table.initials,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get handicapIndex => $composableBuilder(
    column: $table.handicapIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredTee => $composableBuilder(
    column: $table.preferredTee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ghinNumber => $composableBuilder(
    column: $table.ghinNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get initials =>
      $composableBuilder(column: $table.initials, builder: (column) => column);

  GeneratedColumn<double> get handicapIndex => $composableBuilder(
    column: $table.handicapIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredTee => $composableBuilder(
    column: $table.preferredTee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ghinNumber => $composableBuilder(
    column: $table.ghinNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tournamentPlayersRefs<T extends Object>(
    Expression<T> Function($$TournamentPlayersTableAnnotationComposer a) f,
  ) {
    final $$TournamentPlayersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.tournamentPlayers,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TournamentPlayersTableAnnotationComposer(
                $db: $db,
                $table: $db.tournamentPlayers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, $$PlayersTableReferences),
          Player,
          PrefetchHooks Function({bool tournamentPlayersRefs})
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> initials = const Value.absent(),
                Value<double> handicapIndex = const Value.absent(),
                Value<String?> preferredTee = const Value.absent(),
                Value<String?> ghinNumber = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                fullName: fullName,
                nickname: nickname,
                initials: initials,
                handicapIndex: handicapIndex,
                preferredTee: preferredTee,
                ghinNumber: ghinNumber,
                phoneNumber: phoneNumber,
                email: email,
                photoPath: photoPath,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                required String nickname,
                required String initials,
                required double handicapIndex,
                Value<String?> preferredTee = const Value.absent(),
                Value<String?> ghinNumber = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                fullName: fullName,
                nickname: nickname,
                initials: initials,
                handicapIndex: handicapIndex,
                preferredTee: preferredTee,
                ghinNumber: ghinNumber,
                phoneNumber: phoneNumber,
                email: email,
                photoPath: photoPath,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayersTable, Player>(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tournamentPlayersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tournamentPlayersRefs) db.tournamentPlayers,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tournamentPlayersRefs)
                    await $_getPrefetchedData<
                      Player,
                      $PlayersTable,
                      TournamentPlayer
                    >(
                      currentTable: table,
                      referencedTable: $$PlayersTableReferences
                          ._tournamentPlayersRefsTable(db),
                      managerFromTypedResult: (p0) => $$PlayersTableReferences(
                        db,
                        table,
                        p0,
                      ).tournamentPlayersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, $$PlayersTableReferences),
      Player,
      PrefetchHooks Function({bool tournamentPlayersRefs})
    >;
typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      required String id,
      required String name,
      required String city,
      required String state,
      Value<int> holeCount,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> city,
      Value<String> state,
      Value<int> holeCount,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, Course> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseHolesTable, List<CourseHole>>
  _courseHolesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseHoles,
    aliasName: 'courses__id__course_holes__course_id',
  );

  $$CourseHolesTableProcessedTableManager get courseHolesRefs {
    final manager = $$CourseHolesTableTableManager(
      $_db,
      $_db.courseHoles,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseHolesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TeeBoxesTable, List<TeeBox>> _teeBoxesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.teeBoxes,
    aliasName: 'courses__id__tee_boxes__course_id',
  );

  $$TeeBoxesTableProcessedTableManager get teeBoxesRefs {
    final manager = $$TeeBoxesTableTableManager(
      $_db,
      $_db.teeBoxes,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_teeBoxesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavedRoundsTable, List<SavedRound>>
  _savedRoundsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savedRounds,
    aliasName: 'courses__id__saved_rounds__course_id',
  );

  $$SavedRoundsTableProcessedTableManager get savedRoundsRefs {
    final manager = $$SavedRoundsTableTableManager(
      $_db,
      $_db.savedRounds,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedRoundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holeCount => $composableBuilder(
    column: $table.holeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseHolesRefs(
    Expression<bool> Function($$CourseHolesTableFilterComposer f) f,
  ) {
    final $$CourseHolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseHoles,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseHolesTableFilterComposer(
            $db: $db,
            $table: $db.courseHoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> teeBoxesRefs(
    Expression<bool> Function($$TeeBoxesTableFilterComposer f) f,
  ) {
    final $$TeeBoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teeBoxes,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeeBoxesTableFilterComposer(
            $db: $db,
            $table: $db.teeBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savedRoundsRefs(
    Expression<bool> Function($$SavedRoundsTableFilterComposer f) f,
  ) {
    final $$SavedRoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedRounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedRoundsTableFilterComposer(
            $db: $db,
            $table: $db.savedRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holeCount => $composableBuilder(
    column: $table.holeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get holeCount =>
      $composableBuilder(column: $table.holeCount, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> courseHolesRefs<T extends Object>(
    Expression<T> Function($$CourseHolesTableAnnotationComposer a) f,
  ) {
    final $$CourseHolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseHoles,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseHolesTableAnnotationComposer(
            $db: $db,
            $table: $db.courseHoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> teeBoxesRefs<T extends Object>(
    Expression<T> Function($$TeeBoxesTableAnnotationComposer a) f,
  ) {
    final $$TeeBoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teeBoxes,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeeBoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.teeBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savedRoundsRefs<T extends Object>(
    Expression<T> Function($$SavedRoundsTableAnnotationComposer a) f,
  ) {
    final $$SavedRoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedRounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedRoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, $$CoursesTableReferences),
          Course,
          PrefetchHooks Function({
            bool courseHolesRefs,
            bool teeBoxesRefs,
            bool savedRoundsRefs,
          })
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> holeCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                name: name,
                city: city,
                state: state,
                holeCount: holeCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String city,
                required String state,
                Value<int> holeCount = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                name: name,
                city: city,
                state: state,
                holeCount: holeCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoursesTable, Course>(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseHolesRefs = false,
                teeBoxesRefs = false,
                savedRoundsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseHolesRefs) db.courseHoles,
                    if (teeBoxesRefs) db.teeBoxes,
                    if (savedRoundsRefs) db.savedRounds,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseHolesRefs)
                        await $_getPrefetchedData<
                          Course,
                          $CoursesTable,
                          CourseHole
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._courseHolesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseHolesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (teeBoxesRefs)
                        await $_getPrefetchedData<
                          Course,
                          $CoursesTable,
                          TeeBox
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._teeBoxesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).teeBoxesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savedRoundsRefs)
                        await $_getPrefetchedData<
                          Course,
                          $CoursesTable,
                          SavedRound
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._savedRoundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).savedRoundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, $$CoursesTableReferences),
      Course,
      PrefetchHooks Function({
        bool courseHolesRefs,
        bool teeBoxesRefs,
        bool savedRoundsRefs,
      })
    >;
typedef $$CourseHolesTableCreateCompanionBuilder =
    CourseHolesCompanion Function({
      required String id,
      required String courseId,
      required int holeNumber,
      Value<int> par,
      Value<int> strokeIndex,
      Value<int> rowid,
    });
typedef $$CourseHolesTableUpdateCompanionBuilder =
    CourseHolesCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<int> holeNumber,
      Value<int> par,
      Value<int> strokeIndex,
      Value<int> rowid,
    });

final class $$CourseHolesTableReferences
    extends BaseReferences<_$AppDatabase, $CourseHolesTable, CourseHole> {
  $$CourseHolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_holes__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HoleYardagesTable, List<HoleYardage>>
  _holeYardagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.holeYardages,
    aliasName: 'course_holes__id__hole_yardages__course_hole_id',
  );

  $$HoleYardagesTableProcessedTableManager get holeYardagesRefs {
    final manager = $$HoleYardagesTableTableManager(
      $_db,
      $_db.holeYardages,
    ).filter((f) => f.courseHoleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_holeYardagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CourseHolesTableFilterComposer
    extends Composer<_$AppDatabase, $CourseHolesTable> {
  $$CourseHolesTableFilterComposer({
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

  ColumnFilters<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get par => $composableBuilder(
    column: $table.par,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeIndex => $composableBuilder(
    column: $table.strokeIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> holeYardagesRefs(
    Expression<bool> Function($$HoleYardagesTableFilterComposer f) f,
  ) {
    final $$HoleYardagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeYardages,
      getReferencedColumn: (t) => t.courseHoleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleYardagesTableFilterComposer(
            $db: $db,
            $table: $db.holeYardages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseHolesTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseHolesTable> {
  $$CourseHolesTableOrderingComposer({
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

  ColumnOrderings<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get par => $composableBuilder(
    column: $table.par,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeIndex => $composableBuilder(
    column: $table.strokeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseHolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseHolesTable> {
  $$CourseHolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get par =>
      $composableBuilder(column: $table.par, builder: (column) => column);

  GeneratedColumn<int> get strokeIndex => $composableBuilder(
    column: $table.strokeIndex,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> holeYardagesRefs<T extends Object>(
    Expression<T> Function($$HoleYardagesTableAnnotationComposer a) f,
  ) {
    final $$HoleYardagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeYardages,
      getReferencedColumn: (t) => t.courseHoleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleYardagesTableAnnotationComposer(
            $db: $db,
            $table: $db.holeYardages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseHolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseHolesTable,
          CourseHole,
          $$CourseHolesTableFilterComposer,
          $$CourseHolesTableOrderingComposer,
          $$CourseHolesTableAnnotationComposer,
          $$CourseHolesTableCreateCompanionBuilder,
          $$CourseHolesTableUpdateCompanionBuilder,
          (CourseHole, $$CourseHolesTableReferences),
          CourseHole,
          PrefetchHooks Function({bool courseId, bool holeYardagesRefs})
        > {
  $$CourseHolesTableTableManager(_$AppDatabase db, $CourseHolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseHolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseHolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseHolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<int> holeNumber = const Value.absent(),
                Value<int> par = const Value.absent(),
                Value<int> strokeIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseHolesCompanion(
                id: id,
                courseId: courseId,
                holeNumber: holeNumber,
                par: par,
                strokeIndex: strokeIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required int holeNumber,
                Value<int> par = const Value.absent(),
                Value<int> strokeIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseHolesCompanion.insert(
                id: id,
                courseId: courseId,
                holeNumber: holeNumber,
                par: par,
                strokeIndex: strokeIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseHolesTable, CourseHole>(table),
                  $$CourseHolesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseId = false, holeYardagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (holeYardagesRefs) db.holeYardages,
                  ],
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
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable:
                                        $$CourseHolesTableReferences
                                            ._courseIdTable(db),
                                    referencedColumn:
                                        $$CourseHolesTableReferences
                                            ._courseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (holeYardagesRefs)
                        await $_getPrefetchedData<
                          CourseHole,
                          $CourseHolesTable,
                          HoleYardage
                        >(
                          currentTable: table,
                          referencedTable: $$CourseHolesTableReferences
                              ._holeYardagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseHolesTableReferences(
                                db,
                                table,
                                p0,
                              ).holeYardagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseHoleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CourseHolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseHolesTable,
      CourseHole,
      $$CourseHolesTableFilterComposer,
      $$CourseHolesTableOrderingComposer,
      $$CourseHolesTableAnnotationComposer,
      $$CourseHolesTableCreateCompanionBuilder,
      $$CourseHolesTableUpdateCompanionBuilder,
      (CourseHole, $$CourseHolesTableReferences),
      CourseHole,
      PrefetchHooks Function({bool courseId, bool holeYardagesRefs})
    >;
typedef $$TeeBoxesTableCreateCompanionBuilder =
    TeeBoxesCompanion Function({
      required String id,
      required String courseId,
      required String name,
      Value<String?> colorHex,
      required double courseRating,
      required int slopeRating,
      Value<int> totalYardage,
      Value<int> rowid,
    });
typedef $$TeeBoxesTableUpdateCompanionBuilder =
    TeeBoxesCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> name,
      Value<String?> colorHex,
      Value<double> courseRating,
      Value<int> slopeRating,
      Value<int> totalYardage,
      Value<int> rowid,
    });

final class $$TeeBoxesTableReferences
    extends BaseReferences<_$AppDatabase, $TeeBoxesTable, TeeBox> {
  $$TeeBoxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('tee_boxes__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HoleYardagesTable, List<HoleYardage>>
  _holeYardagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.holeYardages,
    aliasName: 'tee_boxes__id__hole_yardages__tee_box_id',
  );

  $$HoleYardagesTableProcessedTableManager get holeYardagesRefs {
    final manager = $$HoleYardagesTableTableManager(
      $_db,
      $_db.holeYardages,
    ).filter((f) => f.teeBoxId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_holeYardagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeeBoxesTableFilterComposer
    extends Composer<_$AppDatabase, $TeeBoxesTable> {
  $$TeeBoxesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get courseRating => $composableBuilder(
    column: $table.courseRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slopeRating => $composableBuilder(
    column: $table.slopeRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalYardage => $composableBuilder(
    column: $table.totalYardage,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> holeYardagesRefs(
    Expression<bool> Function($$HoleYardagesTableFilterComposer f) f,
  ) {
    final $$HoleYardagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeYardages,
      getReferencedColumn: (t) => t.teeBoxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleYardagesTableFilterComposer(
            $db: $db,
            $table: $db.holeYardages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeeBoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $TeeBoxesTable> {
  $$TeeBoxesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get courseRating => $composableBuilder(
    column: $table.courseRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slopeRating => $composableBuilder(
    column: $table.slopeRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalYardage => $composableBuilder(
    column: $table.totalYardage,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeeBoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeeBoxesTable> {
  $$TeeBoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<double> get courseRating => $composableBuilder(
    column: $table.courseRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get slopeRating => $composableBuilder(
    column: $table.slopeRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalYardage => $composableBuilder(
    column: $table.totalYardage,
    builder: (column) => column,
  );

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> holeYardagesRefs<T extends Object>(
    Expression<T> Function($$HoleYardagesTableAnnotationComposer a) f,
  ) {
    final $$HoleYardagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeYardages,
      getReferencedColumn: (t) => t.teeBoxId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleYardagesTableAnnotationComposer(
            $db: $db,
            $table: $db.holeYardages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeeBoxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeeBoxesTable,
          TeeBox,
          $$TeeBoxesTableFilterComposer,
          $$TeeBoxesTableOrderingComposer,
          $$TeeBoxesTableAnnotationComposer,
          $$TeeBoxesTableCreateCompanionBuilder,
          $$TeeBoxesTableUpdateCompanionBuilder,
          (TeeBox, $$TeeBoxesTableReferences),
          TeeBox,
          PrefetchHooks Function({bool courseId, bool holeYardagesRefs})
        > {
  $$TeeBoxesTableTableManager(_$AppDatabase db, $TeeBoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeeBoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeeBoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeeBoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<double> courseRating = const Value.absent(),
                Value<int> slopeRating = const Value.absent(),
                Value<int> totalYardage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeeBoxesCompanion(
                id: id,
                courseId: courseId,
                name: name,
                colorHex: colorHex,
                courseRating: courseRating,
                slopeRating: slopeRating,
                totalYardage: totalYardage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String name,
                Value<String?> colorHex = const Value.absent(),
                required double courseRating,
                required int slopeRating,
                Value<int> totalYardage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeeBoxesCompanion.insert(
                id: id,
                courseId: courseId,
                name: name,
                colorHex: colorHex,
                courseRating: courseRating,
                slopeRating: slopeRating,
                totalYardage: totalYardage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeeBoxesTable, TeeBox>(table),
                  $$TeeBoxesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseId = false, holeYardagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (holeYardagesRefs) db.holeYardages,
                  ],
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
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable: $$TeeBoxesTableReferences
                                        ._courseIdTable(db),
                                    referencedColumn: $$TeeBoxesTableReferences
                                        ._courseIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (holeYardagesRefs)
                        await $_getPrefetchedData<
                          TeeBox,
                          $TeeBoxesTable,
                          HoleYardage
                        >(
                          currentTable: table,
                          referencedTable: $$TeeBoxesTableReferences
                              ._holeYardagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeeBoxesTableReferences(
                                db,
                                table,
                                p0,
                              ).holeYardagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teeBoxId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TeeBoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeeBoxesTable,
      TeeBox,
      $$TeeBoxesTableFilterComposer,
      $$TeeBoxesTableOrderingComposer,
      $$TeeBoxesTableAnnotationComposer,
      $$TeeBoxesTableCreateCompanionBuilder,
      $$TeeBoxesTableUpdateCompanionBuilder,
      (TeeBox, $$TeeBoxesTableReferences),
      TeeBox,
      PrefetchHooks Function({bool courseId, bool holeYardagesRefs})
    >;
typedef $$HoleYardagesTableCreateCompanionBuilder =
    HoleYardagesCompanion Function({
      required String teeBoxId,
      required String courseHoleId,
      Value<int> yardage,
      Value<int> rowid,
    });
typedef $$HoleYardagesTableUpdateCompanionBuilder =
    HoleYardagesCompanion Function({
      Value<String> teeBoxId,
      Value<String> courseHoleId,
      Value<int> yardage,
      Value<int> rowid,
    });

final class $$HoleYardagesTableReferences
    extends BaseReferences<_$AppDatabase, $HoleYardagesTable, HoleYardage> {
  $$HoleYardagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeeBoxesTable _teeBoxIdTable(_$AppDatabase db) =>
      db.teeBoxes.createAlias('hole_yardages__tee_box_id__tee_boxes__id');

  $$TeeBoxesTableProcessedTableManager get teeBoxId {
    final $_column = $_itemColumn<String>('tee_box_id')!;

    final manager = $$TeeBoxesTableTableManager(
      $_db,
      $_db.teeBoxes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teeBoxIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CourseHolesTable _courseHoleIdTable(_$AppDatabase db) => db
      .courseHoles
      .createAlias('hole_yardages__course_hole_id__course_holes__id');

  $$CourseHolesTableProcessedTableManager get courseHoleId {
    final $_column = $_itemColumn<String>('course_hole_id')!;

    final manager = $$CourseHolesTableTableManager(
      $_db,
      $_db.courseHoles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseHoleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HoleYardagesTableFilterComposer
    extends Composer<_$AppDatabase, $HoleYardagesTable> {
  $$HoleYardagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get yardage => $composableBuilder(
    column: $table.yardage,
    builder: (column) => ColumnFilters(column),
  );

  $$TeeBoxesTableFilterComposer get teeBoxId {
    final $$TeeBoxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teeBoxId,
      referencedTable: $db.teeBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeeBoxesTableFilterComposer(
            $db: $db,
            $table: $db.teeBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseHolesTableFilterComposer get courseHoleId {
    final $$CourseHolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseHoleId,
      referencedTable: $db.courseHoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseHolesTableFilterComposer(
            $db: $db,
            $table: $db.courseHoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleYardagesTableOrderingComposer
    extends Composer<_$AppDatabase, $HoleYardagesTable> {
  $$HoleYardagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get yardage => $composableBuilder(
    column: $table.yardage,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeeBoxesTableOrderingComposer get teeBoxId {
    final $$TeeBoxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teeBoxId,
      referencedTable: $db.teeBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeeBoxesTableOrderingComposer(
            $db: $db,
            $table: $db.teeBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseHolesTableOrderingComposer get courseHoleId {
    final $$CourseHolesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseHoleId,
      referencedTable: $db.courseHoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseHolesTableOrderingComposer(
            $db: $db,
            $table: $db.courseHoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleYardagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HoleYardagesTable> {
  $$HoleYardagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get yardage =>
      $composableBuilder(column: $table.yardage, builder: (column) => column);

  $$TeeBoxesTableAnnotationComposer get teeBoxId {
    final $$TeeBoxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teeBoxId,
      referencedTable: $db.teeBoxes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeeBoxesTableAnnotationComposer(
            $db: $db,
            $table: $db.teeBoxes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseHolesTableAnnotationComposer get courseHoleId {
    final $$CourseHolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseHoleId,
      referencedTable: $db.courseHoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseHolesTableAnnotationComposer(
            $db: $db,
            $table: $db.courseHoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleYardagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HoleYardagesTable,
          HoleYardage,
          $$HoleYardagesTableFilterComposer,
          $$HoleYardagesTableOrderingComposer,
          $$HoleYardagesTableAnnotationComposer,
          $$HoleYardagesTableCreateCompanionBuilder,
          $$HoleYardagesTableUpdateCompanionBuilder,
          (HoleYardage, $$HoleYardagesTableReferences),
          HoleYardage,
          PrefetchHooks Function({bool teeBoxId, bool courseHoleId})
        > {
  $$HoleYardagesTableTableManager(_$AppDatabase db, $HoleYardagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HoleYardagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HoleYardagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HoleYardagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> teeBoxId = const Value.absent(),
                Value<String> courseHoleId = const Value.absent(),
                Value<int> yardage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HoleYardagesCompanion(
                teeBoxId: teeBoxId,
                courseHoleId: courseHoleId,
                yardage: yardage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String teeBoxId,
                required String courseHoleId,
                Value<int> yardage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HoleYardagesCompanion.insert(
                teeBoxId: teeBoxId,
                courseHoleId: courseHoleId,
                yardage: yardage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HoleYardagesTable, HoleYardage>(table),
                  $$HoleYardagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teeBoxId = false, courseHoleId = false}) {
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
                    if (teeBoxId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teeBoxId,
                                referencedTable: $$HoleYardagesTableReferences
                                    ._teeBoxIdTable(db),
                                referencedColumn: $$HoleYardagesTableReferences
                                    ._teeBoxIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (courseHoleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseHoleId,
                                referencedTable: $$HoleYardagesTableReferences
                                    ._courseHoleIdTable(db),
                                referencedColumn: $$HoleYardagesTableReferences
                                    ._courseHoleIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$HoleYardagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HoleYardagesTable,
      HoleYardage,
      $$HoleYardagesTableFilterComposer,
      $$HoleYardagesTableOrderingComposer,
      $$HoleYardagesTableAnnotationComposer,
      $$HoleYardagesTableCreateCompanionBuilder,
      $$HoleYardagesTableUpdateCompanionBuilder,
      (HoleYardage, $$HoleYardagesTableReferences),
      HoleYardage,
      PrefetchHooks Function({bool teeBoxId, bool courseHoleId})
    >;
typedef $$TournamentsTableCreateCompanionBuilder =
    TournamentsCompanion Function({
      required String id,
      required String name,
      required int startDate,
      required int endDate,
      Value<String> formatType,
      Value<String> teamAName,
      Value<String> teamBName,
      Value<bool> isActive,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$TournamentsTableUpdateCompanionBuilder =
    TournamentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> startDate,
      Value<int> endDate,
      Value<String> formatType,
      Value<String> teamAName,
      Value<String> teamBName,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$TournamentsTableReferences
    extends BaseReferences<_$AppDatabase, $TournamentsTable, Tournament> {
  $$TournamentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TournamentPlayersTable, List<TournamentPlayer>>
  _tournamentPlayersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.tournamentPlayers,
        aliasName: 'tournaments__id__tournament_players__tournament_id',
      );

  $$TournamentPlayersTableProcessedTableManager get tournamentPlayersRefs {
    final manager = $$TournamentPlayersTableTableManager(
      $_db,
      $_db.tournamentPlayers,
    ).filter((f) => f.tournamentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _tournamentPlayersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavedRoundsTable, List<SavedRound>>
  _savedRoundsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savedRounds,
    aliasName: 'tournaments__id__saved_rounds__tournament_id',
  );

  $$SavedRoundsTableProcessedTableManager get savedRoundsRefs {
    final manager = $$SavedRoundsTableTableManager(
      $_db,
      $_db.savedRounds,
    ).filter((f) => f.tournamentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedRoundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TournamentsTableFilterComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formatType => $composableBuilder(
    column: $table.formatType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamAName => $composableBuilder(
    column: $table.teamAName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamBName => $composableBuilder(
    column: $table.teamBName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tournamentPlayersRefs(
    Expression<bool> Function($$TournamentPlayersTableFilterComposer f) f,
  ) {
    final $$TournamentPlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tournamentPlayers,
      getReferencedColumn: (t) => t.tournamentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentPlayersTableFilterComposer(
            $db: $db,
            $table: $db.tournamentPlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savedRoundsRefs(
    Expression<bool> Function($$SavedRoundsTableFilterComposer f) f,
  ) {
    final $$SavedRoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedRounds,
      getReferencedColumn: (t) => t.tournamentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedRoundsTableFilterComposer(
            $db: $db,
            $table: $db.savedRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TournamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formatType => $composableBuilder(
    column: $table.formatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamAName => $composableBuilder(
    column: $table.teamAName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamBName => $composableBuilder(
    column: $table.teamBName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TournamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get formatType => $composableBuilder(
    column: $table.formatType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamAName =>
      $composableBuilder(column: $table.teamAName, builder: (column) => column);

  GeneratedColumn<String> get teamBName =>
      $composableBuilder(column: $table.teamBName, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> tournamentPlayersRefs<T extends Object>(
    Expression<T> Function($$TournamentPlayersTableAnnotationComposer a) f,
  ) {
    final $$TournamentPlayersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.tournamentPlayers,
          getReferencedColumn: (t) => t.tournamentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TournamentPlayersTableAnnotationComposer(
                $db: $db,
                $table: $db.tournamentPlayers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> savedRoundsRefs<T extends Object>(
    Expression<T> Function($$SavedRoundsTableAnnotationComposer a) f,
  ) {
    final $$SavedRoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedRounds,
      getReferencedColumn: (t) => t.tournamentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedRoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TournamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TournamentsTable,
          Tournament,
          $$TournamentsTableFilterComposer,
          $$TournamentsTableOrderingComposer,
          $$TournamentsTableAnnotationComposer,
          $$TournamentsTableCreateCompanionBuilder,
          $$TournamentsTableUpdateCompanionBuilder,
          (Tournament, $$TournamentsTableReferences),
          Tournament,
          PrefetchHooks Function({
            bool tournamentPlayersRefs,
            bool savedRoundsRefs,
          })
        > {
  $$TournamentsTableTableManager(_$AppDatabase db, $TournamentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TournamentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TournamentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TournamentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<int> endDate = const Value.absent(),
                Value<String> formatType = const Value.absent(),
                Value<String> teamAName = const Value.absent(),
                Value<String> teamBName = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TournamentsCompanion(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                formatType: formatType,
                teamAName: teamAName,
                teamBName: teamBName,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int startDate,
                required int endDate,
                Value<String> formatType = const Value.absent(),
                Value<String> teamAName = const Value.absent(),
                Value<String> teamBName = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TournamentsCompanion.insert(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                formatType: formatType,
                teamAName: teamAName,
                teamBName: teamBName,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TournamentsTable, Tournament>(table),
                  $$TournamentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tournamentPlayersRefs = false, savedRoundsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tournamentPlayersRefs) db.tournamentPlayers,
                    if (savedRoundsRefs) db.savedRounds,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tournamentPlayersRefs)
                        await $_getPrefetchedData<
                          Tournament,
                          $TournamentsTable,
                          TournamentPlayer
                        >(
                          currentTable: table,
                          referencedTable: $$TournamentsTableReferences
                              ._tournamentPlayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TournamentsTableReferences(
                                db,
                                table,
                                p0,
                              ).tournamentPlayersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tournamentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savedRoundsRefs)
                        await $_getPrefetchedData<
                          Tournament,
                          $TournamentsTable,
                          SavedRound
                        >(
                          currentTable: table,
                          referencedTable: $$TournamentsTableReferences
                              ._savedRoundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TournamentsTableReferences(
                                db,
                                table,
                                p0,
                              ).savedRoundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tournamentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TournamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TournamentsTable,
      Tournament,
      $$TournamentsTableFilterComposer,
      $$TournamentsTableOrderingComposer,
      $$TournamentsTableAnnotationComposer,
      $$TournamentsTableCreateCompanionBuilder,
      $$TournamentsTableUpdateCompanionBuilder,
      (Tournament, $$TournamentsTableReferences),
      Tournament,
      PrefetchHooks Function({bool tournamentPlayersRefs, bool savedRoundsRefs})
    >;
typedef $$TournamentPlayersTableCreateCompanionBuilder =
    TournamentPlayersCompanion Function({
      required String tournamentId,
      required String playerId,
      Value<String> teamId,
      Value<double?> customHandicap,
      Value<int> rowid,
    });
typedef $$TournamentPlayersTableUpdateCompanionBuilder =
    TournamentPlayersCompanion Function({
      Value<String> tournamentId,
      Value<String> playerId,
      Value<String> teamId,
      Value<double?> customHandicap,
      Value<int> rowid,
    });

final class $$TournamentPlayersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TournamentPlayersTable,
          TournamentPlayer
        > {
  $$TournamentPlayersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TournamentsTable _tournamentIdTable(_$AppDatabase db) => db
      .tournaments
      .createAlias('tournament_players__tournament_id__tournaments__id');

  $$TournamentsTableProcessedTableManager get tournamentId {
    final $_column = $_itemColumn<String>('tournament_id')!;

    final manager = $$TournamentsTableTableManager(
      $_db,
      $_db.tournaments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tournamentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('tournament_players__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<String>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TournamentPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $TournamentPlayersTable> {
  $$TournamentPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get customHandicap => $composableBuilder(
    column: $table.customHandicap,
    builder: (column) => ColumnFilters(column),
  );

  $$TournamentsTableFilterComposer get tournamentId {
    final $$TournamentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableFilterComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TournamentPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $TournamentPlayersTable> {
  $$TournamentPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get customHandicap => $composableBuilder(
    column: $table.customHandicap,
    builder: (column) => ColumnOrderings(column),
  );

  $$TournamentsTableOrderingComposer get tournamentId {
    final $$TournamentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableOrderingComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TournamentPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TournamentPlayersTable> {
  $$TournamentPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<double> get customHandicap => $composableBuilder(
    column: $table.customHandicap,
    builder: (column) => column,
  );

  $$TournamentsTableAnnotationComposer get tournamentId {
    final $$TournamentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableAnnotationComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TournamentPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TournamentPlayersTable,
          TournamentPlayer,
          $$TournamentPlayersTableFilterComposer,
          $$TournamentPlayersTableOrderingComposer,
          $$TournamentPlayersTableAnnotationComposer,
          $$TournamentPlayersTableCreateCompanionBuilder,
          $$TournamentPlayersTableUpdateCompanionBuilder,
          (TournamentPlayer, $$TournamentPlayersTableReferences),
          TournamentPlayer,
          PrefetchHooks Function({bool tournamentId, bool playerId})
        > {
  $$TournamentPlayersTableTableManager(
    _$AppDatabase db,
    $TournamentPlayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TournamentPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TournamentPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TournamentPlayersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tournamentId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<double?> customHandicap = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TournamentPlayersCompanion(
                tournamentId: tournamentId,
                playerId: playerId,
                teamId: teamId,
                customHandicap: customHandicap,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tournamentId,
                required String playerId,
                Value<String> teamId = const Value.absent(),
                Value<double?> customHandicap = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TournamentPlayersCompanion.insert(
                tournamentId: tournamentId,
                playerId: playerId,
                teamId: teamId,
                customHandicap: customHandicap,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TournamentPlayersTable, TournamentPlayer>(table),
                  $$TournamentPlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tournamentId = false, playerId = false}) {
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
                    if (tournamentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tournamentId,
                                referencedTable:
                                    $$TournamentPlayersTableReferences
                                        ._tournamentIdTable(db),
                                referencedColumn:
                                    $$TournamentPlayersTableReferences
                                        ._tournamentIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$TournamentPlayersTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$TournamentPlayersTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TournamentPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TournamentPlayersTable,
      TournamentPlayer,
      $$TournamentPlayersTableFilterComposer,
      $$TournamentPlayersTableOrderingComposer,
      $$TournamentPlayersTableAnnotationComposer,
      $$TournamentPlayersTableCreateCompanionBuilder,
      $$TournamentPlayersTableUpdateCompanionBuilder,
      (TournamentPlayer, $$TournamentPlayersTableReferences),
      TournamentPlayer,
      PrefetchHooks Function({bool tournamentId, bool playerId})
    >;
typedef $$SavedRoundsTableCreateCompanionBuilder =
    SavedRoundsCompanion Function({
      required String id,
      Value<String?> tournamentId,
      required String courseId,
      required String courseName,
      Value<int> roundNumber,
      required int datePlayed,
      Value<String> format,
      Value<bool> isComplete,
      Value<String?> winnerName,
      required String roundPayloadJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SavedRoundsTableUpdateCompanionBuilder =
    SavedRoundsCompanion Function({
      Value<String> id,
      Value<String?> tournamentId,
      Value<String> courseId,
      Value<String> courseName,
      Value<int> roundNumber,
      Value<int> datePlayed,
      Value<String> format,
      Value<bool> isComplete,
      Value<String?> winnerName,
      Value<String> roundPayloadJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$SavedRoundsTableReferences
    extends BaseReferences<_$AppDatabase, $SavedRoundsTable, SavedRound> {
  $$SavedRoundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TournamentsTable _tournamentIdTable(_$AppDatabase db) => db
      .tournaments
      .createAlias('saved_rounds__tournament_id__tournaments__id');

  $$TournamentsTableProcessedTableManager? get tournamentId {
    final $_column = $_itemColumn<String>('tournament_id');
    if ($_column == null) return null;
    final manager = $$TournamentsTableTableManager(
      $_db,
      $_db.tournaments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tournamentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('saved_rounds__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavedRoundsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedRoundsTable> {
  $$SavedRoundsTableFilterComposer({
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

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get datePlayed => $composableBuilder(
    column: $table.datePlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerName => $composableBuilder(
    column: $table.winnerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TournamentsTableFilterComposer get tournamentId {
    final $$TournamentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableFilterComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedRoundsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedRoundsTable> {
  $$SavedRoundsTableOrderingComposer({
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

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get datePlayed => $composableBuilder(
    column: $table.datePlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerName => $composableBuilder(
    column: $table.winnerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TournamentsTableOrderingComposer get tournamentId {
    final $$TournamentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableOrderingComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedRoundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedRoundsTable> {
  $$SavedRoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundNumber => $composableBuilder(
    column: $table.roundNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get datePlayed => $composableBuilder(
    column: $table.datePlayed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerName => $composableBuilder(
    column: $table.winnerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TournamentsTableAnnotationComposer get tournamentId {
    final $$TournamentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tournamentId,
      referencedTable: $db.tournaments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TournamentsTableAnnotationComposer(
            $db: $db,
            $table: $db.tournaments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedRoundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedRoundsTable,
          SavedRound,
          $$SavedRoundsTableFilterComposer,
          $$SavedRoundsTableOrderingComposer,
          $$SavedRoundsTableAnnotationComposer,
          $$SavedRoundsTableCreateCompanionBuilder,
          $$SavedRoundsTableUpdateCompanionBuilder,
          (SavedRound, $$SavedRoundsTableReferences),
          SavedRound,
          PrefetchHooks Function({bool tournamentId, bool courseId})
        > {
  $$SavedRoundsTableTableManager(_$AppDatabase db, $SavedRoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedRoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedRoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedRoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<int> roundNumber = const Value.absent(),
                Value<int> datePlayed = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<String?> winnerName = const Value.absent(),
                Value<String> roundPayloadJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedRoundsCompanion(
                id: id,
                tournamentId: tournamentId,
                courseId: courseId,
                courseName: courseName,
                roundNumber: roundNumber,
                datePlayed: datePlayed,
                format: format,
                isComplete: isComplete,
                winnerName: winnerName,
                roundPayloadJson: roundPayloadJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> tournamentId = const Value.absent(),
                required String courseId,
                required String courseName,
                Value<int> roundNumber = const Value.absent(),
                required int datePlayed,
                Value<String> format = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<String?> winnerName = const Value.absent(),
                required String roundPayloadJson,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedRoundsCompanion.insert(
                id: id,
                tournamentId: tournamentId,
                courseId: courseId,
                courseName: courseName,
                roundNumber: roundNumber,
                datePlayed: datePlayed,
                format: format,
                isComplete: isComplete,
                winnerName: winnerName,
                roundPayloadJson: roundPayloadJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedRoundsTable, SavedRound>(table),
                  $$SavedRoundsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tournamentId = false, courseId = false}) {
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
                    if (tournamentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tournamentId,
                                referencedTable: $$SavedRoundsTableReferences
                                    ._tournamentIdTable(db),
                                referencedColumn: $$SavedRoundsTableReferences
                                    ._tournamentIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$SavedRoundsTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$SavedRoundsTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SavedRoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedRoundsTable,
      SavedRound,
      $$SavedRoundsTableFilterComposer,
      $$SavedRoundsTableOrderingComposer,
      $$SavedRoundsTableAnnotationComposer,
      $$SavedRoundsTableCreateCompanionBuilder,
      $$SavedRoundsTableUpdateCompanionBuilder,
      (SavedRound, $$SavedRoundsTableReferences),
      SavedRound,
      PrefetchHooks Function({bool tournamentId, bool courseId})
    >;
typedef $$ActiveRoundDraftTableCreateCompanionBuilder =
    ActiveRoundDraftCompanion Function({
      Value<int> id,
      Value<String?> tournamentId,
      required String courseId,
      required String roundPayloadJson,
      required int updatedAt,
    });
typedef $$ActiveRoundDraftTableUpdateCompanionBuilder =
    ActiveRoundDraftCompanion Function({
      Value<int> id,
      Value<String?> tournamentId,
      Value<String> courseId,
      Value<String> roundPayloadJson,
      Value<int> updatedAt,
    });

class $$ActiveRoundDraftTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveRoundDraftTable> {
  $$ActiveRoundDraftTableFilterComposer({
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

  ColumnFilters<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActiveRoundDraftTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveRoundDraftTable> {
  $$ActiveRoundDraftTableOrderingComposer({
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

  ColumnOrderings<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActiveRoundDraftTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveRoundDraftTable> {
  $$ActiveRoundDraftTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get roundPayloadJson => $composableBuilder(
    column: $table.roundPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ActiveRoundDraftTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActiveRoundDraftTable,
          ActiveRoundDraftData,
          $$ActiveRoundDraftTableFilterComposer,
          $$ActiveRoundDraftTableOrderingComposer,
          $$ActiveRoundDraftTableAnnotationComposer,
          $$ActiveRoundDraftTableCreateCompanionBuilder,
          $$ActiveRoundDraftTableUpdateCompanionBuilder,
          (
            ActiveRoundDraftData,
            BaseReferences<
              _$AppDatabase,
              $ActiveRoundDraftTable,
              ActiveRoundDraftData
            >,
          ),
          ActiveRoundDraftData,
          PrefetchHooks Function()
        > {
  $$ActiveRoundDraftTableTableManager(
    _$AppDatabase db,
    $ActiveRoundDraftTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveRoundDraftTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveRoundDraftTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveRoundDraftTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> roundPayloadJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ActiveRoundDraftCompanion(
                id: id,
                tournamentId: tournamentId,
                courseId: courseId,
                roundPayloadJson: roundPayloadJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> tournamentId = const Value.absent(),
                required String courseId,
                required String roundPayloadJson,
                required int updatedAt,
              }) => ActiveRoundDraftCompanion.insert(
                id: id,
                tournamentId: tournamentId,
                courseId: courseId,
                roundPayloadJson: roundPayloadJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActiveRoundDraftTable, ActiveRoundDraftData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ActiveRoundDraftTable,
                    ActiveRoundDraftData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActiveRoundDraftTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActiveRoundDraftTable,
      ActiveRoundDraftData,
      $$ActiveRoundDraftTableFilterComposer,
      $$ActiveRoundDraftTableOrderingComposer,
      $$ActiveRoundDraftTableAnnotationComposer,
      $$ActiveRoundDraftTableCreateCompanionBuilder,
      $$ActiveRoundDraftTableUpdateCompanionBuilder,
      (
        ActiveRoundDraftData,
        BaseReferences<
          _$AppDatabase,
          $ActiveRoundDraftTable,
          ActiveRoundDraftData
        >,
      ),
      ActiveRoundDraftData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String settingsJson,
      required int updatedAt,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> settingsJson,
      Value<int> updatedAt,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                settingsJson: settingsJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String settingsJson,
                required int updatedAt,
              }) => AppSettingsCompanion.insert(
                id: id,
                settingsJson: settingsJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$CourseHolesTableTableManager get courseHoles =>
      $$CourseHolesTableTableManager(_db, _db.courseHoles);
  $$TeeBoxesTableTableManager get teeBoxes =>
      $$TeeBoxesTableTableManager(_db, _db.teeBoxes);
  $$HoleYardagesTableTableManager get holeYardages =>
      $$HoleYardagesTableTableManager(_db, _db.holeYardages);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db, _db.tournaments);
  $$TournamentPlayersTableTableManager get tournamentPlayers =>
      $$TournamentPlayersTableTableManager(_db, _db.tournamentPlayers);
  $$SavedRoundsTableTableManager get savedRounds =>
      $$SavedRoundsTableTableManager(_db, _db.savedRounds);
  $$ActiveRoundDraftTableTableManager get activeRoundDraft =>
      $$ActiveRoundDraftTableTableManager(_db, _db.activeRoundDraft);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
