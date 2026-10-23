// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PortfoliosTable extends Portfolios with TableInfo<$PortfoliosTable, PortfolioRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PortfoliosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF3B82F6),
  );
  static const VerificationMeta _costBasisMethodMeta = const VerificationMeta('costBasisMethod');
  @override
  late final GeneratedColumn<String> costBasisMethod = GeneratedColumn<String>(
    'cost_basis_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('average'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, description, color, costBasisMethod, sortOrder, archived, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portfolios';
  @override
  VerificationContext validateIntegrity(Insertable<PortfolioRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('cost_basis_method')) {
      context.handle(_costBasisMethodMeta, costBasisMethod.isAcceptableOrUnknown(data['cost_basis_method']!, _costBasisMethodMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PortfolioRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description']),
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      costBasisMethod: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cost_basis_method'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PortfoliosTable createAlias(String alias) {
    return $PortfoliosTable(attachedDatabase, alias);
  }
}

class PortfolioRow extends DataClass implements Insertable<PortfolioRow> {
  final int id;
  final String name;
  final String? description;
  final int color;
  final String costBasisMethod;
  final int sortOrder;
  final bool archived;
  final DateTime createdAt;
  const PortfolioRow({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.costBasisMethod,
    required this.sortOrder,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color'] = Variable<int>(color);
    map['cost_basis_method'] = Variable<String>(costBasisMethod);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PortfoliosCompanion toCompanion(bool nullToAbsent) {
    return PortfoliosCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent ? const Value.absent() : Value(description),
      color: Value(color),
      costBasisMethod: Value(costBasisMethod),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory PortfolioRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<int>(json['color']),
      costBasisMethod: serializer.fromJson<String>(json['costBasisMethod']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<int>(color),
      'costBasisMethod': serializer.toJson<String>(costBasisMethod),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PortfolioRow copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? color,
    String? costBasisMethod,
    int? sortOrder,
    bool? archived,
    DateTime? createdAt,
  }) => PortfolioRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    color: color ?? this.color,
    costBasisMethod: costBasisMethod ?? this.costBasisMethod,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  PortfolioRow copyWithCompanion(PortfoliosCompanion data) {
    return PortfolioRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present ? data.description.value : this.description,
      color: data.color.present ? data.color.value : this.color,
      costBasisMethod: data.costBasisMethod.present ? data.costBasisMethod.value : this.costBasisMethod,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('costBasisMethod: $costBasisMethod, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, color, costBasisMethod, sortOrder, archived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.costBasisMethod == this.costBasisMethod &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class PortfoliosCompanion extends UpdateCompanion<PortfolioRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> color;
  final Value<String> costBasisMethod;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  const PortfoliosCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.costBasisMethod = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PortfoliosCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.costBasisMethod = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<PortfolioRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? color,
    Expression<String>? costBasisMethod,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (costBasisMethod != null) 'cost_basis_method': costBasisMethod,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PortfoliosCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? color,
    Value<String>? costBasisMethod,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
  }) {
    return PortfoliosCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      costBasisMethod: costBasisMethod ?? this.costBasisMethod,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (costBasisMethod.present) {
      map['cost_basis_method'] = Variable<String>(costBasisMethod.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfoliosCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('costBasisMethod: $costBasisMethod, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InstrumentsTable extends Instruments with TableInfo<$InstrumentsTable, InstrumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
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
  static const VerificationMeta _quoteTypeMeta = const VerificationMeta('quoteType');
  @override
  late final GeneratedColumn<String> quoteType = GeneratedColumn<String>(
    'quote_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exchangeMeta = const VerificationMeta('exchange');
  @override
  late final GeneratedColumn<String> exchange = GeneratedColumn<String>(
    'exchange',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _sectorMeta = const VerificationMeta('sector');
  @override
  late final GeneratedColumn<String> sector = GeneratedColumn<String>(
    'sector',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _industryMeta = const VerificationMeta('industry');
  @override
  late final GeneratedColumn<String> industry = GeneratedColumn<String>(
    'industry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMetaRefreshMeta = const VerificationMeta('lastMetaRefresh');
  @override
  late final GeneratedColumn<DateTime> lastMetaRefresh = GeneratedColumn<DateTime>(
    'last_meta_refresh',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, name, quoteType, exchange, currency, sector, industry, lastMetaRefresh];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  VerificationContext validateIntegrity(Insertable<InstrumentRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quote_type')) {
      context.handle(_quoteTypeMeta, quoteType.isAcceptableOrUnknown(data['quote_type']!, _quoteTypeMeta));
    }
    if (data.containsKey('exchange')) {
      context.handle(_exchangeMeta, exchange.isAcceptableOrUnknown(data['exchange']!, _exchangeMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('sector')) {
      context.handle(_sectorMeta, sector.isAcceptableOrUnknown(data['sector']!, _sectorMeta));
    }
    if (data.containsKey('industry')) {
      context.handle(_industryMeta, industry.isAcceptableOrUnknown(data['industry']!, _industryMeta));
    }
    if (data.containsKey('last_meta_refresh')) {
      context.handle(_lastMetaRefreshMeta, lastMetaRefresh.isAcceptableOrUnknown(data['last_meta_refresh']!, _lastMetaRefreshMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  InstrumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quoteType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}quote_type']),
      exchange: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exchange']),
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      sector: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sector']),
      industry: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}industry']),
      lastMetaRefresh: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_meta_refresh']),
    );
  }

  @override
  $InstrumentsTable createAlias(String alias) {
    return $InstrumentsTable(attachedDatabase, alias);
  }
}

class InstrumentRow extends DataClass implements Insertable<InstrumentRow> {
  final String symbol;
  final String name;
  final String? quoteType;
  final String? exchange;
  final String currency;
  final String? sector;
  final String? industry;
  final DateTime? lastMetaRefresh;
  const InstrumentRow({
    required this.symbol,
    required this.name,
    this.quoteType,
    this.exchange,
    required this.currency,
    this.sector,
    this.industry,
    this.lastMetaRefresh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quoteType != null) {
      map['quote_type'] = Variable<String>(quoteType);
    }
    if (!nullToAbsent || exchange != null) {
      map['exchange'] = Variable<String>(exchange);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || sector != null) {
      map['sector'] = Variable<String>(sector);
    }
    if (!nullToAbsent || industry != null) {
      map['industry'] = Variable<String>(industry);
    }
    if (!nullToAbsent || lastMetaRefresh != null) {
      map['last_meta_refresh'] = Variable<DateTime>(lastMetaRefresh);
    }
    return map;
  }

  InstrumentsCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsCompanion(
      symbol: Value(symbol),
      name: Value(name),
      quoteType: quoteType == null && nullToAbsent ? const Value.absent() : Value(quoteType),
      exchange: exchange == null && nullToAbsent ? const Value.absent() : Value(exchange),
      currency: Value(currency),
      sector: sector == null && nullToAbsent ? const Value.absent() : Value(sector),
      industry: industry == null && nullToAbsent ? const Value.absent() : Value(industry),
      lastMetaRefresh: lastMetaRefresh == null && nullToAbsent ? const Value.absent() : Value(lastMetaRefresh),
    );
  }

  factory InstrumentRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      quoteType: serializer.fromJson<String?>(json['quoteType']),
      exchange: serializer.fromJson<String?>(json['exchange']),
      currency: serializer.fromJson<String>(json['currency']),
      sector: serializer.fromJson<String?>(json['sector']),
      industry: serializer.fromJson<String?>(json['industry']),
      lastMetaRefresh: serializer.fromJson<DateTime?>(json['lastMetaRefresh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'quoteType': serializer.toJson<String?>(quoteType),
      'exchange': serializer.toJson<String?>(exchange),
      'currency': serializer.toJson<String>(currency),
      'sector': serializer.toJson<String?>(sector),
      'industry': serializer.toJson<String?>(industry),
      'lastMetaRefresh': serializer.toJson<DateTime?>(lastMetaRefresh),
    };
  }

  InstrumentRow copyWith({
    String? symbol,
    String? name,
    Value<String?> quoteType = const Value.absent(),
    Value<String?> exchange = const Value.absent(),
    String? currency,
    Value<String?> sector = const Value.absent(),
    Value<String?> industry = const Value.absent(),
    Value<DateTime?> lastMetaRefresh = const Value.absent(),
  }) => InstrumentRow(
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    quoteType: quoteType.present ? quoteType.value : this.quoteType,
    exchange: exchange.present ? exchange.value : this.exchange,
    currency: currency ?? this.currency,
    sector: sector.present ? sector.value : this.sector,
    industry: industry.present ? industry.value : this.industry,
    lastMetaRefresh: lastMetaRefresh.present ? lastMetaRefresh.value : this.lastMetaRefresh,
  );
  InstrumentRow copyWithCompanion(InstrumentsCompanion data) {
    return InstrumentRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      quoteType: data.quoteType.present ? data.quoteType.value : this.quoteType,
      exchange: data.exchange.present ? data.exchange.value : this.exchange,
      currency: data.currency.present ? data.currency.value : this.currency,
      sector: data.sector.present ? data.sector.value : this.sector,
      industry: data.industry.present ? data.industry.value : this.industry,
      lastMetaRefresh: data.lastMetaRefresh.present ? data.lastMetaRefresh.value : this.lastMetaRefresh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentRow(')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('quoteType: $quoteType, ')
          ..write('exchange: $exchange, ')
          ..write('currency: $currency, ')
          ..write('sector: $sector, ')
          ..write('industry: $industry, ')
          ..write('lastMetaRefresh: $lastMetaRefresh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, name, quoteType, exchange, currency, sector, industry, lastMetaRefresh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentRow &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.quoteType == this.quoteType &&
          other.exchange == this.exchange &&
          other.currency == this.currency &&
          other.sector == this.sector &&
          other.industry == this.industry &&
          other.lastMetaRefresh == this.lastMetaRefresh);
}

class InstrumentsCompanion extends UpdateCompanion<InstrumentRow> {
  final Value<String> symbol;
  final Value<String> name;
  final Value<String?> quoteType;
  final Value<String?> exchange;
  final Value<String> currency;
  final Value<String?> sector;
  final Value<String?> industry;
  final Value<DateTime?> lastMetaRefresh;
  final Value<int> rowid;
  const InstrumentsCompanion({
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.quoteType = const Value.absent(),
    this.exchange = const Value.absent(),
    this.currency = const Value.absent(),
    this.sector = const Value.absent(),
    this.industry = const Value.absent(),
    this.lastMetaRefresh = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentsCompanion.insert({
    required String symbol,
    required String name,
    this.quoteType = const Value.absent(),
    this.exchange = const Value.absent(),
    this.currency = const Value.absent(),
    this.sector = const Value.absent(),
    this.industry = const Value.absent(),
    this.lastMetaRefresh = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       name = Value(name);
  static Insertable<InstrumentRow> custom({
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? quoteType,
    Expression<String>? exchange,
    Expression<String>? currency,
    Expression<String>? sector,
    Expression<String>? industry,
    Expression<DateTime>? lastMetaRefresh,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (quoteType != null) 'quote_type': quoteType,
      if (exchange != null) 'exchange': exchange,
      if (currency != null) 'currency': currency,
      if (sector != null) 'sector': sector,
      if (industry != null) 'industry': industry,
      if (lastMetaRefresh != null) 'last_meta_refresh': lastMetaRefresh,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentsCompanion copyWith({
    Value<String>? symbol,
    Value<String>? name,
    Value<String?>? quoteType,
    Value<String?>? exchange,
    Value<String>? currency,
    Value<String?>? sector,
    Value<String?>? industry,
    Value<DateTime?>? lastMetaRefresh,
    Value<int>? rowid,
  }) {
    return InstrumentsCompanion(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      quoteType: quoteType ?? this.quoteType,
      exchange: exchange ?? this.exchange,
      currency: currency ?? this.currency,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      lastMetaRefresh: lastMetaRefresh ?? this.lastMetaRefresh,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quoteType.present) {
      map['quote_type'] = Variable<String>(quoteType.value);
    }
    if (exchange.present) {
      map['exchange'] = Variable<String>(exchange.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (sector.present) {
      map['sector'] = Variable<String>(sector.value);
    }
    if (industry.present) {
      map['industry'] = Variable<String>(industry.value);
    }
    if (lastMetaRefresh.present) {
      map['last_meta_refresh'] = Variable<DateTime>(lastMetaRefresh.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsCompanion(')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('quoteType: $quoteType, ')
          ..write('exchange: $exchange, ')
          ..write('currency: $currency, ')
          ..write('sector: $sector, ')
          ..write('industry: $industry, ')
          ..write('lastMetaRefresh: $lastMetaRefresh, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LunoConnectionsTable extends LunoConnections with TableInfo<$LunoConnectionsTable, LunoConnectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LunoConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portfolioIdMeta = const VerificationMeta('portfolioId');
  @override
  late final GeneratedColumn<int> portfolioId = GeneratedColumn<int>(
    'portfolio_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES portfolios (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _keyIdHintMeta = const VerificationMeta('keyIdHint');
  @override
  late final GeneratedColumn<String> keyIdHint = GeneratedColumn<String>(
    'key_id_hint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _homeFiatMeta = const VerificationMeta('homeFiat');
  @override
  late final GeneratedColumn<String> homeFiat = GeneratedColumn<String>(
    'home_fiat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('credentials_missing'),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writePermWarningMeta = const VerificationMeta('writePermWarning');
  @override
  late final GeneratedColumn<bool> writePermWarning = GeneratedColumn<bool>(
    'write_perm_warning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("write_perm_warning" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unrecognisedRowsMeta = const VerificationMeta('unrecognisedRows');
  @override
  late final GeneratedColumn<int> unrecognisedRows = GeneratedColumn<int>(
    'unrecognised_rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
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
    label,
    portfolioId,
    keyIdHint,
    homeFiat,
    status,
    lastSyncAt,
    lastError,
    writePermWarning,
    unrecognisedRows,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'luno_connections';
  @override
  VerificationContext validateIntegrity(Insertable<LunoConnectionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('portfolio_id')) {
      context.handle(_portfolioIdMeta, portfolioId.isAcceptableOrUnknown(data['portfolio_id']!, _portfolioIdMeta));
    } else if (isInserting) {
      context.missing(_portfolioIdMeta);
    }
    if (data.containsKey('key_id_hint')) {
      context.handle(_keyIdHintMeta, keyIdHint.isAcceptableOrUnknown(data['key_id_hint']!, _keyIdHintMeta));
    }
    if (data.containsKey('home_fiat')) {
      context.handle(_homeFiatMeta, homeFiat.isAcceptableOrUnknown(data['home_fiat']!, _homeFiatMeta));
    } else if (isInserting) {
      context.missing(_homeFiatMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(_lastSyncAtMeta, lastSyncAt.isAcceptableOrUnknown(data['last_sync_at']!, _lastSyncAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta, lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('write_perm_warning')) {
      context.handle(_writePermWarningMeta, writePermWarning.isAcceptableOrUnknown(data['write_perm_warning']!, _writePermWarningMeta));
    }
    if (data.containsKey('unrecognised_rows')) {
      context.handle(_unrecognisedRowsMeta, unrecognisedRows.isAcceptableOrUnknown(data['unrecognised_rows']!, _unrecognisedRowsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LunoConnectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LunoConnectionRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      portfolioId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}portfolio_id'])!,
      keyIdHint: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key_id_hint'])!,
      homeFiat: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}home_fiat'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastSyncAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
      lastError: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      writePermWarning: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}write_perm_warning'])!,
      unrecognisedRows: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}unrecognised_rows'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LunoConnectionsTable createAlias(String alias) {
    return $LunoConnectionsTable(attachedDatabase, alias);
  }
}

class LunoConnectionRow extends DataClass implements Insertable<LunoConnectionRow> {
  final int id;
  final String label;
  final int portfolioId;

  /// Last 4 characters of the API key id. The key id and secret live only in the secure store.
  final String keyIdHint;
  final String homeFiat;

  /// `ok` | `syncing` | `error` | `revoked` | `credentials_missing` | `needs_review`.
  final String status;
  final DateTime? lastSyncAt;
  final String? lastError;
  final bool writePermWarning;
  final int unrecognisedRows;
  final DateTime createdAt;
  const LunoConnectionRow({
    required this.id,
    required this.label,
    required this.portfolioId,
    required this.keyIdHint,
    required this.homeFiat,
    required this.status,
    this.lastSyncAt,
    this.lastError,
    required this.writePermWarning,
    required this.unrecognisedRows,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['portfolio_id'] = Variable<int>(portfolioId);
    map['key_id_hint'] = Variable<String>(keyIdHint);
    map['home_fiat'] = Variable<String>(homeFiat);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['write_perm_warning'] = Variable<bool>(writePermWarning);
    map['unrecognised_rows'] = Variable<int>(unrecognisedRows);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LunoConnectionsCompanion toCompanion(bool nullToAbsent) {
    return LunoConnectionsCompanion(
      id: Value(id),
      label: Value(label),
      portfolioId: Value(portfolioId),
      keyIdHint: Value(keyIdHint),
      homeFiat: Value(homeFiat),
      status: Value(status),
      lastSyncAt: lastSyncAt == null && nullToAbsent ? const Value.absent() : Value(lastSyncAt),
      lastError: lastError == null && nullToAbsent ? const Value.absent() : Value(lastError),
      writePermWarning: Value(writePermWarning),
      unrecognisedRows: Value(unrecognisedRows),
      createdAt: Value(createdAt),
    );
  }

  factory LunoConnectionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LunoConnectionRow(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      portfolioId: serializer.fromJson<int>(json['portfolioId']),
      keyIdHint: serializer.fromJson<String>(json['keyIdHint']),
      homeFiat: serializer.fromJson<String>(json['homeFiat']),
      status: serializer.fromJson<String>(json['status']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      writePermWarning: serializer.fromJson<bool>(json['writePermWarning']),
      unrecognisedRows: serializer.fromJson<int>(json['unrecognisedRows']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'portfolioId': serializer.toJson<int>(portfolioId),
      'keyIdHint': serializer.toJson<String>(keyIdHint),
      'homeFiat': serializer.toJson<String>(homeFiat),
      'status': serializer.toJson<String>(status),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastError': serializer.toJson<String?>(lastError),
      'writePermWarning': serializer.toJson<bool>(writePermWarning),
      'unrecognisedRows': serializer.toJson<int>(unrecognisedRows),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LunoConnectionRow copyWith({
    int? id,
    String? label,
    int? portfolioId,
    String? keyIdHint,
    String? homeFiat,
    String? status,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    bool? writePermWarning,
    int? unrecognisedRows,
    DateTime? createdAt,
  }) => LunoConnectionRow(
    id: id ?? this.id,
    label: label ?? this.label,
    portfolioId: portfolioId ?? this.portfolioId,
    keyIdHint: keyIdHint ?? this.keyIdHint,
    homeFiat: homeFiat ?? this.homeFiat,
    status: status ?? this.status,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    writePermWarning: writePermWarning ?? this.writePermWarning,
    unrecognisedRows: unrecognisedRows ?? this.unrecognisedRows,
    createdAt: createdAt ?? this.createdAt,
  );
  LunoConnectionRow copyWithCompanion(LunoConnectionsCompanion data) {
    return LunoConnectionRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      portfolioId: data.portfolioId.present ? data.portfolioId.value : this.portfolioId,
      keyIdHint: data.keyIdHint.present ? data.keyIdHint.value : this.keyIdHint,
      homeFiat: data.homeFiat.present ? data.homeFiat.value : this.homeFiat,
      status: data.status.present ? data.status.value : this.status,
      lastSyncAt: data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      writePermWarning: data.writePermWarning.present ? data.writePermWarning.value : this.writePermWarning,
      unrecognisedRows: data.unrecognisedRows.present ? data.unrecognisedRows.value : this.unrecognisedRows,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LunoConnectionRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('portfolioId: $portfolioId, ')
          ..write('keyIdHint: $keyIdHint, ')
          ..write('homeFiat: $homeFiat, ')
          ..write('status: $status, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('writePermWarning: $writePermWarning, ')
          ..write('unrecognisedRows: $unrecognisedRows, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    portfolioId,
    keyIdHint,
    homeFiat,
    status,
    lastSyncAt,
    lastError,
    writePermWarning,
    unrecognisedRows,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LunoConnectionRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.portfolioId == this.portfolioId &&
          other.keyIdHint == this.keyIdHint &&
          other.homeFiat == this.homeFiat &&
          other.status == this.status &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastError == this.lastError &&
          other.writePermWarning == this.writePermWarning &&
          other.unrecognisedRows == this.unrecognisedRows &&
          other.createdAt == this.createdAt);
}

class LunoConnectionsCompanion extends UpdateCompanion<LunoConnectionRow> {
  final Value<int> id;
  final Value<String> label;
  final Value<int> portfolioId;
  final Value<String> keyIdHint;
  final Value<String> homeFiat;
  final Value<String> status;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> lastError;
  final Value<bool> writePermWarning;
  final Value<int> unrecognisedRows;
  final Value<DateTime> createdAt;
  const LunoConnectionsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.portfolioId = const Value.absent(),
    this.keyIdHint = const Value.absent(),
    this.homeFiat = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.writePermWarning = const Value.absent(),
    this.unrecognisedRows = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LunoConnectionsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required int portfolioId,
    this.keyIdHint = const Value.absent(),
    required String homeFiat,
    this.status = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.writePermWarning = const Value.absent(),
    this.unrecognisedRows = const Value.absent(),
    required DateTime createdAt,
  }) : label = Value(label),
       portfolioId = Value(portfolioId),
       homeFiat = Value(homeFiat),
       createdAt = Value(createdAt);
  static Insertable<LunoConnectionRow> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<int>? portfolioId,
    Expression<String>? keyIdHint,
    Expression<String>? homeFiat,
    Expression<String>? status,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? lastError,
    Expression<bool>? writePermWarning,
    Expression<int>? unrecognisedRows,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (portfolioId != null) 'portfolio_id': portfolioId,
      if (keyIdHint != null) 'key_id_hint': keyIdHint,
      if (homeFiat != null) 'home_fiat': homeFiat,
      if (status != null) 'status': status,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastError != null) 'last_error': lastError,
      if (writePermWarning != null) 'write_perm_warning': writePermWarning,
      if (unrecognisedRows != null) 'unrecognised_rows': unrecognisedRows,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LunoConnectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<int>? portfolioId,
    Value<String>? keyIdHint,
    Value<String>? homeFiat,
    Value<String>? status,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? lastError,
    Value<bool>? writePermWarning,
    Value<int>? unrecognisedRows,
    Value<DateTime>? createdAt,
  }) {
    return LunoConnectionsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      portfolioId: portfolioId ?? this.portfolioId,
      keyIdHint: keyIdHint ?? this.keyIdHint,
      homeFiat: homeFiat ?? this.homeFiat,
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      writePermWarning: writePermWarning ?? this.writePermWarning,
      unrecognisedRows: unrecognisedRows ?? this.unrecognisedRows,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (portfolioId.present) {
      map['portfolio_id'] = Variable<int>(portfolioId.value);
    }
    if (keyIdHint.present) {
      map['key_id_hint'] = Variable<String>(keyIdHint.value);
    }
    if (homeFiat.present) {
      map['home_fiat'] = Variable<String>(homeFiat.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (writePermWarning.present) {
      map['write_perm_warning'] = Variable<bool>(writePermWarning.value);
    }
    if (unrecognisedRows.present) {
      map['unrecognised_rows'] = Variable<int>(unrecognisedRows.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LunoConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('portfolioId: $portfolioId, ')
          ..write('keyIdHint: $keyIdHint, ')
          ..write('homeFiat: $homeFiat, ')
          ..write('status: $status, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('writePermWarning: $writePermWarning, ')
          ..write('unrecognisedRows: $unrecognisedRows, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _portfolioIdMeta = const VerificationMeta('portfolioId');
  @override
  late final GeneratedColumn<int> portfolioId = GeneratedColumn<int>(
    'portfolio_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES portfolios (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($TransactionsTable.$convertertradeDate);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Decimal>($TransactionsTable.$converterquantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Decimal>($TransactionsTable.$converterprice);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> fees = GeneratedColumn<String>(
    'fees',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  ).withConverter<Decimal>($TransactionsTable.$converterfees);
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> fxRateToBase = GeneratedColumn<String>(
    'fx_rate_to_base',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1'),
  ).withConverter<Decimal>($TransactionsTable.$converterfxRateToBase);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importBatchIdMeta = const VerificationMeta('importBatchId');
  @override
  late final GeneratedColumn<String> importBatchId = GeneratedColumn<String>(
    'import_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta('connectionId');
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES luno_connections (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta('externalId');
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _executedAtMeta = const VerificationMeta('executedAt');
  @override
  late final GeneratedColumn<int> executedAt = GeneratedColumn<int>(
    'executed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    portfolioId,
    symbol,
    type,
    tradeDate,
    quantity,
    price,
    fees,
    currency,
    fxRateToBase,
    notes,
    importBatchId,
    createdAt,
    source,
    connectionId,
    externalId,
    executedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('portfolio_id')) {
      context.handle(_portfolioIdMeta, portfolioId.isAcceptableOrUnknown(data['portfolio_id']!, _portfolioIdMeta));
    } else if (isInserting) {
      context.missing(_portfolioIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('import_batch_id')) {
      context.handle(_importBatchIdMeta, importBatchId.isAcceptableOrUnknown(data['import_batch_id']!, _importBatchIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('connection_id')) {
      context.handle(_connectionIdMeta, connectionId.isAcceptableOrUnknown(data['connection_id']!, _connectionIdMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(_externalIdMeta, externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta));
    }
    if (data.containsKey('executed_at')) {
      context.handle(_executedAtMeta, executedAt.isAcceptableOrUnknown(data['executed_at']!, _executedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      portfolioId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}portfolio_id'])!,
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol']),
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      tradeDate: $TransactionsTable.$convertertradeDate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}trade_date'])!,
      ),
      quantity: $TransactionsTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}quantity'])!,
      ),
      price: $TransactionsTable.$converterprice.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}price'])!,
      ),
      fees: $TransactionsTable.$converterfees.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}fees'])!,
      ),
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      fxRateToBase: $TransactionsTable.$converterfxRateToBase.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}fx_rate_to_base'])!,
      ),
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes']),
      importBatchId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}import_batch_id']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      connectionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}connection_id']),
      externalId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}external_id']),
      executedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}executed_at']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertertradeDate = const DateOnlyConverter();
  static TypeConverter<Decimal, String> $converterquantity = const DecimalConverter();
  static TypeConverter<Decimal, String> $converterprice = const DecimalConverter();
  static TypeConverter<Decimal, String> $converterfees = const DecimalConverter();
  static TypeConverter<Decimal, String> $converterfxRateToBase = const DecimalConverter();
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int portfolioId;
  final String? symbol;
  final String type;
  final DateTime tradeDate;
  final Decimal quantity;
  final Decimal price;
  final Decimal fees;
  final String currency;
  final Decimal fxRateToBase;
  final String? notes;
  final String? importBatchId;
  final DateTime createdAt;

  /// `manual` | `csv` | `luno`. Luno rows are written only by the sync service.
  final String source;
  final int? connectionId;
  final String? externalId;

  /// Execution time (UTC epoch ms) used for ordering within a day.
  final int? executedAt;
  const TransactionRow({
    required this.id,
    required this.portfolioId,
    this.symbol,
    required this.type,
    required this.tradeDate,
    required this.quantity,
    required this.price,
    required this.fees,
    required this.currency,
    required this.fxRateToBase,
    this.notes,
    this.importBatchId,
    required this.createdAt,
    required this.source,
    this.connectionId,
    this.externalId,
    this.executedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['portfolio_id'] = Variable<int>(portfolioId);
    if (!nullToAbsent || symbol != null) {
      map['symbol'] = Variable<String>(symbol);
    }
    map['type'] = Variable<String>(type);
    {
      map['trade_date'] = Variable<String>($TransactionsTable.$convertertradeDate.toSql(tradeDate));
    }
    {
      map['quantity'] = Variable<String>($TransactionsTable.$converterquantity.toSql(quantity));
    }
    {
      map['price'] = Variable<String>($TransactionsTable.$converterprice.toSql(price));
    }
    {
      map['fees'] = Variable<String>($TransactionsTable.$converterfees.toSql(fees));
    }
    map['currency'] = Variable<String>(currency);
    {
      map['fx_rate_to_base'] = Variable<String>($TransactionsTable.$converterfxRateToBase.toSql(fxRateToBase));
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || importBatchId != null) {
      map['import_batch_id'] = Variable<String>(importBatchId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || connectionId != null) {
      map['connection_id'] = Variable<int>(connectionId);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || executedAt != null) {
      map['executed_at'] = Variable<int>(executedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      portfolioId: Value(portfolioId),
      symbol: symbol == null && nullToAbsent ? const Value.absent() : Value(symbol),
      type: Value(type),
      tradeDate: Value(tradeDate),
      quantity: Value(quantity),
      price: Value(price),
      fees: Value(fees),
      currency: Value(currency),
      fxRateToBase: Value(fxRateToBase),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      importBatchId: importBatchId == null && nullToAbsent ? const Value.absent() : Value(importBatchId),
      createdAt: Value(createdAt),
      source: Value(source),
      connectionId: connectionId == null && nullToAbsent ? const Value.absent() : Value(connectionId),
      externalId: externalId == null && nullToAbsent ? const Value.absent() : Value(externalId),
      executedAt: executedAt == null && nullToAbsent ? const Value.absent() : Value(executedAt),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      portfolioId: serializer.fromJson<int>(json['portfolioId']),
      symbol: serializer.fromJson<String?>(json['symbol']),
      type: serializer.fromJson<String>(json['type']),
      tradeDate: serializer.fromJson<DateTime>(json['tradeDate']),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      price: serializer.fromJson<Decimal>(json['price']),
      fees: serializer.fromJson<Decimal>(json['fees']),
      currency: serializer.fromJson<String>(json['currency']),
      fxRateToBase: serializer.fromJson<Decimal>(json['fxRateToBase']),
      notes: serializer.fromJson<String?>(json['notes']),
      importBatchId: serializer.fromJson<String?>(json['importBatchId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      source: serializer.fromJson<String>(json['source']),
      connectionId: serializer.fromJson<int?>(json['connectionId']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      executedAt: serializer.fromJson<int?>(json['executedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'portfolioId': serializer.toJson<int>(portfolioId),
      'symbol': serializer.toJson<String?>(symbol),
      'type': serializer.toJson<String>(type),
      'tradeDate': serializer.toJson<DateTime>(tradeDate),
      'quantity': serializer.toJson<Decimal>(quantity),
      'price': serializer.toJson<Decimal>(price),
      'fees': serializer.toJson<Decimal>(fees),
      'currency': serializer.toJson<String>(currency),
      'fxRateToBase': serializer.toJson<Decimal>(fxRateToBase),
      'notes': serializer.toJson<String?>(notes),
      'importBatchId': serializer.toJson<String?>(importBatchId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'source': serializer.toJson<String>(source),
      'connectionId': serializer.toJson<int?>(connectionId),
      'externalId': serializer.toJson<String?>(externalId),
      'executedAt': serializer.toJson<int?>(executedAt),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? portfolioId,
    Value<String?> symbol = const Value.absent(),
    String? type,
    DateTime? tradeDate,
    Decimal? quantity,
    Decimal? price,
    Decimal? fees,
    String? currency,
    Decimal? fxRateToBase,
    Value<String?> notes = const Value.absent(),
    Value<String?> importBatchId = const Value.absent(),
    DateTime? createdAt,
    String? source,
    Value<int?> connectionId = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> executedAt = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    portfolioId: portfolioId ?? this.portfolioId,
    symbol: symbol.present ? symbol.value : this.symbol,
    type: type ?? this.type,
    tradeDate: tradeDate ?? this.tradeDate,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    fees: fees ?? this.fees,
    currency: currency ?? this.currency,
    fxRateToBase: fxRateToBase ?? this.fxRateToBase,
    notes: notes.present ? notes.value : this.notes,
    importBatchId: importBatchId.present ? importBatchId.value : this.importBatchId,
    createdAt: createdAt ?? this.createdAt,
    source: source ?? this.source,
    connectionId: connectionId.present ? connectionId.value : this.connectionId,
    externalId: externalId.present ? externalId.value : this.externalId,
    executedAt: executedAt.present ? executedAt.value : this.executedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      portfolioId: data.portfolioId.present ? data.portfolioId.value : this.portfolioId,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      type: data.type.present ? data.type.value : this.type,
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      fees: data.fees.present ? data.fees.value : this.fees,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxRateToBase: data.fxRateToBase.present ? data.fxRateToBase.value : this.fxRateToBase,
      notes: data.notes.present ? data.notes.value : this.notes,
      importBatchId: data.importBatchId.present ? data.importBatchId.value : this.importBatchId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      source: data.source.present ? data.source.value : this.source,
      connectionId: data.connectionId.present ? data.connectionId.value : this.connectionId,
      externalId: data.externalId.present ? data.externalId.value : this.externalId,
      executedAt: data.executedAt.present ? data.executedAt.value : this.executedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('portfolioId: $portfolioId, ')
          ..write('symbol: $symbol, ')
          ..write('type: $type, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('fees: $fees, ')
          ..write('currency: $currency, ')
          ..write('fxRateToBase: $fxRateToBase, ')
          ..write('notes: $notes, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('connectionId: $connectionId, ')
          ..write('externalId: $externalId, ')
          ..write('executedAt: $executedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    portfolioId,
    symbol,
    type,
    tradeDate,
    quantity,
    price,
    fees,
    currency,
    fxRateToBase,
    notes,
    importBatchId,
    createdAt,
    source,
    connectionId,
    externalId,
    executedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.portfolioId == this.portfolioId &&
          other.symbol == this.symbol &&
          other.type == this.type &&
          other.tradeDate == this.tradeDate &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.fees == this.fees &&
          other.currency == this.currency &&
          other.fxRateToBase == this.fxRateToBase &&
          other.notes == this.notes &&
          other.importBatchId == this.importBatchId &&
          other.createdAt == this.createdAt &&
          other.source == this.source &&
          other.connectionId == this.connectionId &&
          other.externalId == this.externalId &&
          other.executedAt == this.executedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> portfolioId;
  final Value<String?> symbol;
  final Value<String> type;
  final Value<DateTime> tradeDate;
  final Value<Decimal> quantity;
  final Value<Decimal> price;
  final Value<Decimal> fees;
  final Value<String> currency;
  final Value<Decimal> fxRateToBase;
  final Value<String?> notes;
  final Value<String?> importBatchId;
  final Value<DateTime> createdAt;
  final Value<String> source;
  final Value<int?> connectionId;
  final Value<String?> externalId;
  final Value<int?> executedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.portfolioId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.type = const Value.absent(),
    this.tradeDate = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.fees = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRateToBase = const Value.absent(),
    this.notes = const Value.absent(),
    this.importBatchId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.executedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int portfolioId,
    this.symbol = const Value.absent(),
    required String type,
    required DateTime tradeDate,
    required Decimal quantity,
    required Decimal price,
    this.fees = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRateToBase = const Value.absent(),
    this.notes = const Value.absent(),
    this.importBatchId = const Value.absent(),
    required DateTime createdAt,
    this.source = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.executedAt = const Value.absent(),
  }) : portfolioId = Value(portfolioId),
       type = Value(type),
       tradeDate = Value(tradeDate),
       quantity = Value(quantity),
       price = Value(price),
       createdAt = Value(createdAt);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? portfolioId,
    Expression<String>? symbol,
    Expression<String>? type,
    Expression<String>? tradeDate,
    Expression<String>? quantity,
    Expression<String>? price,
    Expression<String>? fees,
    Expression<String>? currency,
    Expression<String>? fxRateToBase,
    Expression<String>? notes,
    Expression<String>? importBatchId,
    Expression<DateTime>? createdAt,
    Expression<String>? source,
    Expression<int>? connectionId,
    Expression<String>? externalId,
    Expression<int>? executedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (portfolioId != null) 'portfolio_id': portfolioId,
      if (symbol != null) 'symbol': symbol,
      if (type != null) 'type': type,
      if (tradeDate != null) 'trade_date': tradeDate,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (fees != null) 'fees': fees,
      if (currency != null) 'currency': currency,
      if (fxRateToBase != null) 'fx_rate_to_base': fxRateToBase,
      if (notes != null) 'notes': notes,
      if (importBatchId != null) 'import_batch_id': importBatchId,
      if (createdAt != null) 'created_at': createdAt,
      if (source != null) 'source': source,
      if (connectionId != null) 'connection_id': connectionId,
      if (externalId != null) 'external_id': externalId,
      if (executedAt != null) 'executed_at': executedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? portfolioId,
    Value<String?>? symbol,
    Value<String>? type,
    Value<DateTime>? tradeDate,
    Value<Decimal>? quantity,
    Value<Decimal>? price,
    Value<Decimal>? fees,
    Value<String>? currency,
    Value<Decimal>? fxRateToBase,
    Value<String?>? notes,
    Value<String?>? importBatchId,
    Value<DateTime>? createdAt,
    Value<String>? source,
    Value<int?>? connectionId,
    Value<String?>? externalId,
    Value<int?>? executedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      portfolioId: portfolioId ?? this.portfolioId,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      tradeDate: tradeDate ?? this.tradeDate,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      fees: fees ?? this.fees,
      currency: currency ?? this.currency,
      fxRateToBase: fxRateToBase ?? this.fxRateToBase,
      notes: notes ?? this.notes,
      importBatchId: importBatchId ?? this.importBatchId,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      connectionId: connectionId ?? this.connectionId,
      externalId: externalId ?? this.externalId,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (portfolioId.present) {
      map['portfolio_id'] = Variable<int>(portfolioId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>($TransactionsTable.$convertertradeDate.toSql(tradeDate.value));
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>($TransactionsTable.$converterquantity.toSql(quantity.value));
    }
    if (price.present) {
      map['price'] = Variable<String>($TransactionsTable.$converterprice.toSql(price.value));
    }
    if (fees.present) {
      map['fees'] = Variable<String>($TransactionsTable.$converterfees.toSql(fees.value));
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxRateToBase.present) {
      map['fx_rate_to_base'] = Variable<String>($TransactionsTable.$converterfxRateToBase.toSql(fxRateToBase.value));
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (importBatchId.present) {
      map['import_batch_id'] = Variable<String>(importBatchId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (executedAt.present) {
      map['executed_at'] = Variable<int>(executedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('portfolioId: $portfolioId, ')
          ..write('symbol: $symbol, ')
          ..write('type: $type, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('fees: $fees, ')
          ..write('currency: $currency, ')
          ..write('fxRateToBase: $fxRateToBase, ')
          ..write('notes: $notes, ')
          ..write('importBatchId: $importBatchId, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('connectionId: $connectionId, ')
          ..write('externalId: $externalId, ')
          ..write('executedAt: $executedAt')
          ..write(')'))
        .toString();
  }
}

class $WatchlistsTable extends Watchlists with TableInfo<$WatchlistsTable, WatchlistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
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
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlists';
  @override
  VerificationContext validateIntegrity(Insertable<WatchlistRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchlistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $WatchlistsTable createAlias(String alias) {
    return $WatchlistsTable(attachedDatabase, alias);
  }
}

class WatchlistRow extends DataClass implements Insertable<WatchlistRow> {
  final int id;
  final String name;
  final int sortOrder;
  const WatchlistRow({required this.id, required this.name, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WatchlistsCompanion toCompanion(bool nullToAbsent) {
    return WatchlistsCompanion(id: Value(id), name: Value(name), sortOrder: Value(sortOrder));
  }

  factory WatchlistRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WatchlistRow copyWith({int? id, String? name, int? sortOrder}) =>
      WatchlistRow(id: id ?? this.id, name: name ?? this.name, sortOrder: sortOrder ?? this.sortOrder);
  WatchlistRow copyWithCompanion(WatchlistsCompanion data) {
    return WatchlistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchlistRow && other.id == this.id && other.name == this.name && other.sortOrder == this.sortOrder);
}

class WatchlistsCompanion extends UpdateCompanion<WatchlistRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  const WatchlistsCompanion({this.id = const Value.absent(), this.name = const Value.absent(), this.sortOrder = const Value.absent()});
  WatchlistsCompanion.insert({this.id = const Value.absent(), required String name, this.sortOrder = const Value.absent()})
    : name = Value(name);
  static Insertable<WatchlistRow> custom({Expression<int>? id, Expression<String>? name, Expression<int>? sortOrder}) {
    return RawValuesInsertable({if (id != null) 'id': id, if (name != null) 'name': name, if (sortOrder != null) 'sort_order': sortOrder});
  }

  WatchlistsCompanion copyWith({Value<int>? id, Value<String>? name, Value<int>? sortOrder}) {
    return WatchlistsCompanion(id: id ?? this.id, name: name ?? this.name, sortOrder: sortOrder ?? this.sortOrder);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WatchlistItemsTable extends WatchlistItems with TableInfo<$WatchlistItemsTable, WatchlistItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _watchlistIdMeta = const VerificationMeta('watchlistId');
  @override
  late final GeneratedColumn<int> watchlistId = GeneratedColumn<int>(
    'watchlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES watchlists (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [watchlistId, symbol, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlist_items';
  @override
  VerificationContext validateIntegrity(Insertable<WatchlistItemRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('watchlist_id')) {
      context.handle(_watchlistIdMeta, watchlistId.isAcceptableOrUnknown(data['watchlist_id']!, _watchlistIdMeta));
    } else if (isInserting) {
      context.missing(_watchlistIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {watchlistId, symbol};
  @override
  WatchlistItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistItemRow(
      watchlistId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}watchlist_id'])!,
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $WatchlistItemsTable createAlias(String alias) {
    return $WatchlistItemsTable(attachedDatabase, alias);
  }
}

class WatchlistItemRow extends DataClass implements Insertable<WatchlistItemRow> {
  final int watchlistId;
  final String symbol;
  final int sortOrder;
  const WatchlistItemRow({required this.watchlistId, required this.symbol, required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['watchlist_id'] = Variable<int>(watchlistId);
    map['symbol'] = Variable<String>(symbol);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WatchlistItemsCompanion toCompanion(bool nullToAbsent) {
    return WatchlistItemsCompanion(watchlistId: Value(watchlistId), symbol: Value(symbol), sortOrder: Value(sortOrder));
  }

  factory WatchlistItemRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistItemRow(
      watchlistId: serializer.fromJson<int>(json['watchlistId']),
      symbol: serializer.fromJson<String>(json['symbol']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'watchlistId': serializer.toJson<int>(watchlistId),
      'symbol': serializer.toJson<String>(symbol),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WatchlistItemRow copyWith({int? watchlistId, String? symbol, int? sortOrder}) =>
      WatchlistItemRow(watchlistId: watchlistId ?? this.watchlistId, symbol: symbol ?? this.symbol, sortOrder: sortOrder ?? this.sortOrder);
  WatchlistItemRow copyWithCompanion(WatchlistItemsCompanion data) {
    return WatchlistItemRow(
      watchlistId: data.watchlistId.present ? data.watchlistId.value : this.watchlistId,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistItemRow(')
          ..write('watchlistId: $watchlistId, ')
          ..write('symbol: $symbol, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(watchlistId, symbol, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchlistItemRow &&
          other.watchlistId == this.watchlistId &&
          other.symbol == this.symbol &&
          other.sortOrder == this.sortOrder);
}

class WatchlistItemsCompanion extends UpdateCompanion<WatchlistItemRow> {
  final Value<int> watchlistId;
  final Value<String> symbol;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WatchlistItemsCompanion({
    this.watchlistId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchlistItemsCompanion.insert({
    required int watchlistId,
    required String symbol,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : watchlistId = Value(watchlistId),
       symbol = Value(symbol);
  static Insertable<WatchlistItemRow> custom({
    Expression<int>? watchlistId,
    Expression<String>? symbol,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (watchlistId != null) 'watchlist_id': watchlistId,
      if (symbol != null) 'symbol': symbol,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchlistItemsCompanion copyWith({Value<int>? watchlistId, Value<String>? symbol, Value<int>? sortOrder, Value<int>? rowid}) {
    return WatchlistItemsCompanion(
      watchlistId: watchlistId ?? this.watchlistId,
      symbol: symbol ?? this.symbol,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (watchlistId.present) {
      map['watchlist_id'] = Variable<int>(watchlistId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistItemsCompanion(')
          ..write('watchlistId: $watchlistId, ')
          ..write('symbol: $symbol, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuoteCacheTable extends QuoteCache with TableInfo<$QuoteCacheTable, QuoteCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuoteCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, payloadJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote_cache';
  @override
  VerificationContext validateIntegrity(Insertable<QuoteCacheRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(_payloadJsonMeta, payloadJson.isAcceptableOrUnknown(data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta, fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  QuoteCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteCacheRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      fetchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $QuoteCacheTable createAlias(String alias) {
    return $QuoteCacheTable(attachedDatabase, alias);
  }
}

class QuoteCacheRow extends DataClass implements Insertable<QuoteCacheRow> {
  final String symbol;
  final String payloadJson;
  final DateTime fetchedAt;
  const QuoteCacheRow({required this.symbol, required this.payloadJson, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  QuoteCacheCompanion toCompanion(bool nullToAbsent) {
    return QuoteCacheCompanion(symbol: Value(symbol), payloadJson: Value(payloadJson), fetchedAt: Value(fetchedAt));
  }

  factory QuoteCacheRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteCacheRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  QuoteCacheRow copyWith({String? symbol, String? payloadJson, DateTime? fetchedAt}) =>
      QuoteCacheRow(symbol: symbol ?? this.symbol, payloadJson: payloadJson ?? this.payloadJson, fetchedAt: fetchedAt ?? this.fetchedAt);
  QuoteCacheRow copyWithCompanion(QuoteCacheCompanion data) {
    return QuoteCacheRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteCacheRow(')
          ..write('symbol: $symbol, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteCacheRow && other.symbol == this.symbol && other.payloadJson == this.payloadJson && other.fetchedAt == this.fetchedAt);
}

class QuoteCacheCompanion extends UpdateCompanion<QuoteCacheRow> {
  final Value<String> symbol;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const QuoteCacheCompanion({
    this.symbol = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuoteCacheCompanion.insert({
    required String symbol,
    required String payloadJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<QuoteCacheRow> custom({
    Expression<String>? symbol,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuoteCacheCompanion copyWith({Value<String>? symbol, Value<String>? payloadJson, Value<DateTime>? fetchedAt, Value<int>? rowid}) {
    return QuoteCacheCompanion(
      symbol: symbol ?? this.symbol,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
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
    return (StringBuffer('QuoteCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileCacheTable extends ProfileCache with TableInfo<$ProfileCacheTable, ProfileCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, payloadJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_cache';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileCacheRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(_payloadJsonMeta, payloadJson.isAcceptableOrUnknown(data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta, fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  ProfileCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileCacheRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      fetchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $ProfileCacheTable createAlias(String alias) {
    return $ProfileCacheTable(attachedDatabase, alias);
  }
}

class ProfileCacheRow extends DataClass implements Insertable<ProfileCacheRow> {
  final String symbol;
  final String payloadJson;
  final DateTime fetchedAt;
  const ProfileCacheRow({required this.symbol, required this.payloadJson, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ProfileCacheCompanion toCompanion(bool nullToAbsent) {
    return ProfileCacheCompanion(symbol: Value(symbol), payloadJson: Value(payloadJson), fetchedAt: Value(fetchedAt));
  }

  factory ProfileCacheRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileCacheRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ProfileCacheRow copyWith({String? symbol, String? payloadJson, DateTime? fetchedAt}) =>
      ProfileCacheRow(symbol: symbol ?? this.symbol, payloadJson: payloadJson ?? this.payloadJson, fetchedAt: fetchedAt ?? this.fetchedAt);
  ProfileCacheRow copyWithCompanion(ProfileCacheCompanion data) {
    return ProfileCacheRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCacheRow(')
          ..write('symbol: $symbol, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileCacheRow &&
          other.symbol == this.symbol &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt);
}

class ProfileCacheCompanion extends UpdateCompanion<ProfileCacheRow> {
  final Value<String> symbol;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const ProfileCacheCompanion({
    this.symbol = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileCacheCompanion.insert({
    required String symbol,
    required String payloadJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       payloadJson = Value(payloadJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<ProfileCacheRow> custom({
    Expression<String>? symbol,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileCacheCompanion copyWith({Value<String>? symbol, Value<String>? payloadJson, Value<DateTime>? fetchedAt, Value<int>? rowid}) {
    return ProfileCacheCompanion(
      symbol: symbol ?? this.symbol,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
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
    return (StringBuffer('ProfileCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceHistoryCacheTable extends PriceHistoryCache with TableInfo<$PriceHistoryCacheTable, PriceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceHistoryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta('interval');
  @override
  late final GeneratedColumn<String> interval = GeneratedColumn<String>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>('ts', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _openMeta = const VerificationMeta('open');
  @override
  late final GeneratedColumn<double> open = GeneratedColumn<double>(
    'open',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highMeta = const VerificationMeta('high');
  @override
  late final GeneratedColumn<double> high = GeneratedColumn<double>(
    'high',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowMeta = const VerificationMeta('low');
  @override
  late final GeneratedColumn<double> low = GeneratedColumn<double>(
    'low',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closeMeta = const VerificationMeta('close');
  @override
  late final GeneratedColumn<double> close = GeneratedColumn<double>(
    'close',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjCloseMeta = const VerificationMeta('adjClose');
  @override
  late final GeneratedColumn<double> adjClose = GeneratedColumn<double>(
    'adj_close',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, interval, ts, open, high, low, close, adjClose, volume];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_history_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PriceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta, interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    } else if (isInserting) {
      context.missing(_intervalMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('open')) {
      context.handle(_openMeta, open.isAcceptableOrUnknown(data['open']!, _openMeta));
    } else if (isInserting) {
      context.missing(_openMeta);
    }
    if (data.containsKey('high')) {
      context.handle(_highMeta, high.isAcceptableOrUnknown(data['high']!, _highMeta));
    } else if (isInserting) {
      context.missing(_highMeta);
    }
    if (data.containsKey('low')) {
      context.handle(_lowMeta, low.isAcceptableOrUnknown(data['low']!, _lowMeta));
    } else if (isInserting) {
      context.missing(_lowMeta);
    }
    if (data.containsKey('close')) {
      context.handle(_closeMeta, close.isAcceptableOrUnknown(data['close']!, _closeMeta));
    } else if (isInserting) {
      context.missing(_closeMeta);
    }
    if (data.containsKey('adj_close')) {
      context.handle(_adjCloseMeta, adjClose.isAcceptableOrUnknown(data['adj_close']!, _adjCloseMeta));
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta, volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol, interval, ts};
  @override
  PriceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      interval: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}interval'])!,
      ts: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ts'])!,
      open: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}open'])!,
      high: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}high'])!,
      low: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}low'])!,
      close: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}close'])!,
      adjClose: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}adj_close']),
      volume: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
    );
  }

  @override
  $PriceHistoryCacheTable createAlias(String alias) {
    return $PriceHistoryCacheTable(attachedDatabase, alias);
  }
}

class PriceRow extends DataClass implements Insertable<PriceRow> {
  final String symbol;
  final String interval;
  final int ts;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? adjClose;
  final double volume;
  const PriceRow({
    required this.symbol,
    required this.interval,
    required this.ts,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.adjClose,
    required this.volume,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['interval'] = Variable<String>(interval);
    map['ts'] = Variable<int>(ts);
    map['open'] = Variable<double>(open);
    map['high'] = Variable<double>(high);
    map['low'] = Variable<double>(low);
    map['close'] = Variable<double>(close);
    if (!nullToAbsent || adjClose != null) {
      map['adj_close'] = Variable<double>(adjClose);
    }
    map['volume'] = Variable<double>(volume);
    return map;
  }

  PriceHistoryCacheCompanion toCompanion(bool nullToAbsent) {
    return PriceHistoryCacheCompanion(
      symbol: Value(symbol),
      interval: Value(interval),
      ts: Value(ts),
      open: Value(open),
      high: Value(high),
      low: Value(low),
      close: Value(close),
      adjClose: adjClose == null && nullToAbsent ? const Value.absent() : Value(adjClose),
      volume: Value(volume),
    );
  }

  factory PriceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      interval: serializer.fromJson<String>(json['interval']),
      ts: serializer.fromJson<int>(json['ts']),
      open: serializer.fromJson<double>(json['open']),
      high: serializer.fromJson<double>(json['high']),
      low: serializer.fromJson<double>(json['low']),
      close: serializer.fromJson<double>(json['close']),
      adjClose: serializer.fromJson<double?>(json['adjClose']),
      volume: serializer.fromJson<double>(json['volume']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'interval': serializer.toJson<String>(interval),
      'ts': serializer.toJson<int>(ts),
      'open': serializer.toJson<double>(open),
      'high': serializer.toJson<double>(high),
      'low': serializer.toJson<double>(low),
      'close': serializer.toJson<double>(close),
      'adjClose': serializer.toJson<double?>(adjClose),
      'volume': serializer.toJson<double>(volume),
    };
  }

  PriceRow copyWith({
    String? symbol,
    String? interval,
    int? ts,
    double? open,
    double? high,
    double? low,
    double? close,
    Value<double?> adjClose = const Value.absent(),
    double? volume,
  }) => PriceRow(
    symbol: symbol ?? this.symbol,
    interval: interval ?? this.interval,
    ts: ts ?? this.ts,
    open: open ?? this.open,
    high: high ?? this.high,
    low: low ?? this.low,
    close: close ?? this.close,
    adjClose: adjClose.present ? adjClose.value : this.adjClose,
    volume: volume ?? this.volume,
  );
  PriceRow copyWithCompanion(PriceHistoryCacheCompanion data) {
    return PriceRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      interval: data.interval.present ? data.interval.value : this.interval,
      ts: data.ts.present ? data.ts.value : this.ts,
      open: data.open.present ? data.open.value : this.open,
      high: data.high.present ? data.high.value : this.high,
      low: data.low.present ? data.low.value : this.low,
      close: data.close.present ? data.close.value : this.close,
      adjClose: data.adjClose.present ? data.adjClose.value : this.adjClose,
      volume: data.volume.present ? data.volume.value : this.volume,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceRow(')
          ..write('symbol: $symbol, ')
          ..write('interval: $interval, ')
          ..write('ts: $ts, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('close: $close, ')
          ..write('adjClose: $adjClose, ')
          ..write('volume: $volume')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, interval, ts, open, high, low, close, adjClose, volume);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceRow &&
          other.symbol == this.symbol &&
          other.interval == this.interval &&
          other.ts == this.ts &&
          other.open == this.open &&
          other.high == this.high &&
          other.low == this.low &&
          other.close == this.close &&
          other.adjClose == this.adjClose &&
          other.volume == this.volume);
}

class PriceHistoryCacheCompanion extends UpdateCompanion<PriceRow> {
  final Value<String> symbol;
  final Value<String> interval;
  final Value<int> ts;
  final Value<double> open;
  final Value<double> high;
  final Value<double> low;
  final Value<double> close;
  final Value<double?> adjClose;
  final Value<double> volume;
  final Value<int> rowid;
  const PriceHistoryCacheCompanion({
    this.symbol = const Value.absent(),
    this.interval = const Value.absent(),
    this.ts = const Value.absent(),
    this.open = const Value.absent(),
    this.high = const Value.absent(),
    this.low = const Value.absent(),
    this.close = const Value.absent(),
    this.adjClose = const Value.absent(),
    this.volume = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceHistoryCacheCompanion.insert({
    required String symbol,
    required String interval,
    required int ts,
    required double open,
    required double high,
    required double low,
    required double close,
    this.adjClose = const Value.absent(),
    this.volume = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       interval = Value(interval),
       ts = Value(ts),
       open = Value(open),
       high = Value(high),
       low = Value(low),
       close = Value(close);
  static Insertable<PriceRow> custom({
    Expression<String>? symbol,
    Expression<String>? interval,
    Expression<int>? ts,
    Expression<double>? open,
    Expression<double>? high,
    Expression<double>? low,
    Expression<double>? close,
    Expression<double>? adjClose,
    Expression<double>? volume,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (interval != null) 'interval': interval,
      if (ts != null) 'ts': ts,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (close != null) 'close': close,
      if (adjClose != null) 'adj_close': adjClose,
      if (volume != null) 'volume': volume,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceHistoryCacheCompanion copyWith({
    Value<String>? symbol,
    Value<String>? interval,
    Value<int>? ts,
    Value<double>? open,
    Value<double>? high,
    Value<double>? low,
    Value<double>? close,
    Value<double?>? adjClose,
    Value<double>? volume,
    Value<int>? rowid,
  }) {
    return PriceHistoryCacheCompanion(
      symbol: symbol ?? this.symbol,
      interval: interval ?? this.interval,
      ts: ts ?? this.ts,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      adjClose: adjClose ?? this.adjClose,
      volume: volume ?? this.volume,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (interval.present) {
      map['interval'] = Variable<String>(interval.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (open.present) {
      map['open'] = Variable<double>(open.value);
    }
    if (high.present) {
      map['high'] = Variable<double>(high.value);
    }
    if (low.present) {
      map['low'] = Variable<double>(low.value);
    }
    if (close.present) {
      map['close'] = Variable<double>(close.value);
    }
    if (adjClose.present) {
      map['adj_close'] = Variable<double>(adjClose.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('interval: $interval, ')
          ..write('ts: $ts, ')
          ..write('open: $open, ')
          ..write('high: $high, ')
          ..write('low: $low, ')
          ..write('close: $close, ')
          ..write('adjClose: $adjClose, ')
          ..write('volume: $volume, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryMetaTable extends HistoryMeta with TableInfo<$HistoryMetaTable, HistoryMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta('interval');
  @override
  late final GeneratedColumn<String> interval = GeneratedColumn<String>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldestTsMeta = const VerificationMeta('oldestTs');
  @override
  late final GeneratedColumn<int> oldestTs = GeneratedColumn<int>(
    'oldest_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newestTsMeta = const VerificationMeta('newestTs');
  @override
  late final GeneratedColumn<int> newestTs = GeneratedColumn<int>(
    'newest_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, interval, oldestTs, newestTs, currency, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_meta';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryMetaRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta, interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    } else if (isInserting) {
      context.missing(_intervalMeta);
    }
    if (data.containsKey('oldest_ts')) {
      context.handle(_oldestTsMeta, oldestTs.isAcceptableOrUnknown(data['oldest_ts']!, _oldestTsMeta));
    } else if (isInserting) {
      context.missing(_oldestTsMeta);
    }
    if (data.containsKey('newest_ts')) {
      context.handle(_newestTsMeta, newestTs.isAcceptableOrUnknown(data['newest_ts']!, _newestTsMeta));
    } else if (isInserting) {
      context.missing(_newestTsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta, currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta, fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol, interval};
  @override
  HistoryMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryMetaRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      interval: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}interval'])!,
      oldestTs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}oldest_ts'])!,
      newestTs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}newest_ts'])!,
      currency: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}currency']),
      fetchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $HistoryMetaTable createAlias(String alias) {
    return $HistoryMetaTable(attachedDatabase, alias);
  }
}

class HistoryMetaRow extends DataClass implements Insertable<HistoryMetaRow> {
  final String symbol;
  final String interval;
  final int oldestTs;
  final int newestTs;
  final String? currency;
  final DateTime fetchedAt;
  const HistoryMetaRow({
    required this.symbol,
    required this.interval,
    required this.oldestTs,
    required this.newestTs,
    this.currency,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['interval'] = Variable<String>(interval);
    map['oldest_ts'] = Variable<int>(oldestTs);
    map['newest_ts'] = Variable<int>(newestTs);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  HistoryMetaCompanion toCompanion(bool nullToAbsent) {
    return HistoryMetaCompanion(
      symbol: Value(symbol),
      interval: Value(interval),
      oldestTs: Value(oldestTs),
      newestTs: Value(newestTs),
      currency: currency == null && nullToAbsent ? const Value.absent() : Value(currency),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory HistoryMetaRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryMetaRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      interval: serializer.fromJson<String>(json['interval']),
      oldestTs: serializer.fromJson<int>(json['oldestTs']),
      newestTs: serializer.fromJson<int>(json['newestTs']),
      currency: serializer.fromJson<String?>(json['currency']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'interval': serializer.toJson<String>(interval),
      'oldestTs': serializer.toJson<int>(oldestTs),
      'newestTs': serializer.toJson<int>(newestTs),
      'currency': serializer.toJson<String?>(currency),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  HistoryMetaRow copyWith({
    String? symbol,
    String? interval,
    int? oldestTs,
    int? newestTs,
    Value<String?> currency = const Value.absent(),
    DateTime? fetchedAt,
  }) => HistoryMetaRow(
    symbol: symbol ?? this.symbol,
    interval: interval ?? this.interval,
    oldestTs: oldestTs ?? this.oldestTs,
    newestTs: newestTs ?? this.newestTs,
    currency: currency.present ? currency.value : this.currency,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  HistoryMetaRow copyWithCompanion(HistoryMetaCompanion data) {
    return HistoryMetaRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      interval: data.interval.present ? data.interval.value : this.interval,
      oldestTs: data.oldestTs.present ? data.oldestTs.value : this.oldestTs,
      newestTs: data.newestTs.present ? data.newestTs.value : this.newestTs,
      currency: data.currency.present ? data.currency.value : this.currency,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryMetaRow(')
          ..write('symbol: $symbol, ')
          ..write('interval: $interval, ')
          ..write('oldestTs: $oldestTs, ')
          ..write('newestTs: $newestTs, ')
          ..write('currency: $currency, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, interval, oldestTs, newestTs, currency, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryMetaRow &&
          other.symbol == this.symbol &&
          other.interval == this.interval &&
          other.oldestTs == this.oldestTs &&
          other.newestTs == this.newestTs &&
          other.currency == this.currency &&
          other.fetchedAt == this.fetchedAt);
}

class HistoryMetaCompanion extends UpdateCompanion<HistoryMetaRow> {
  final Value<String> symbol;
  final Value<String> interval;
  final Value<int> oldestTs;
  final Value<int> newestTs;
  final Value<String?> currency;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const HistoryMetaCompanion({
    this.symbol = const Value.absent(),
    this.interval = const Value.absent(),
    this.oldestTs = const Value.absent(),
    this.newestTs = const Value.absent(),
    this.currency = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryMetaCompanion.insert({
    required String symbol,
    required String interval,
    required int oldestTs,
    required int newestTs,
    this.currency = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       interval = Value(interval),
       oldestTs = Value(oldestTs),
       newestTs = Value(newestTs),
       fetchedAt = Value(fetchedAt);
  static Insertable<HistoryMetaRow> custom({
    Expression<String>? symbol,
    Expression<String>? interval,
    Expression<int>? oldestTs,
    Expression<int>? newestTs,
    Expression<String>? currency,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (interval != null) 'interval': interval,
      if (oldestTs != null) 'oldest_ts': oldestTs,
      if (newestTs != null) 'newest_ts': newestTs,
      if (currency != null) 'currency': currency,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryMetaCompanion copyWith({
    Value<String>? symbol,
    Value<String>? interval,
    Value<int>? oldestTs,
    Value<int>? newestTs,
    Value<String?>? currency,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return HistoryMetaCompanion(
      symbol: symbol ?? this.symbol,
      interval: interval ?? this.interval,
      oldestTs: oldestTs ?? this.oldestTs,
      newestTs: newestTs ?? this.newestTs,
      currency: currency ?? this.currency,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (interval.present) {
      map['interval'] = Variable<String>(interval.value);
    }
    if (oldestTs.present) {
      map['oldest_ts'] = Variable<int>(oldestTs.value);
    }
    if (newestTs.present) {
      map['newest_ts'] = Variable<int>(newestTs.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
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
    return (StringBuffer('HistoryMetaCompanion(')
          ..write('symbol: $symbol, ')
          ..write('interval: $interval, ')
          ..write('oldestTs: $oldestTs, ')
          ..write('newestTs: $newestTs, ')
          ..write('currency: $currency, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DividendEventsCacheTable extends DividendEventsCache with TableInfo<$DividendEventsCacheTable, DividendRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DividendEventsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> exDate = GeneratedColumn<String>(
    'ex_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($DividendEventsCacheTable.$converterexDate);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> payDate = GeneratedColumn<String>(
    'pay_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($DividendEventsCacheTable.$converterpayDaten);
  @override
  List<GeneratedColumn> get $columns => [symbol, exDate, amount, payDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dividend_events_cache';
  @override
  VerificationContext validateIntegrity(Insertable<DividendRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol, exDate};
  @override
  DividendRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DividendRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      exDate: $DividendEventsCacheTable.$converterexDate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ex_date'])!,
      ),
      amount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      payDate: $DividendEventsCacheTable.$converterpayDaten.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pay_date']),
      ),
    );
  }

  @override
  $DividendEventsCacheTable createAlias(String alias) {
    return $DividendEventsCacheTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterexDate = const DateOnlyConverter();
  static TypeConverter<DateTime, String> $converterpayDate = const DateOnlyConverter();
  static TypeConverter<DateTime?, String?> $converterpayDaten = NullAwareTypeConverter.wrap($converterpayDate);
}

class DividendRow extends DataClass implements Insertable<DividendRow> {
  final String symbol;
  final DateTime exDate;
  final double amount;
  final DateTime? payDate;
  const DividendRow({required this.symbol, required this.exDate, required this.amount, this.payDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    {
      map['ex_date'] = Variable<String>($DividendEventsCacheTable.$converterexDate.toSql(exDate));
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || payDate != null) {
      map['pay_date'] = Variable<String>($DividendEventsCacheTable.$converterpayDaten.toSql(payDate));
    }
    return map;
  }

  DividendEventsCacheCompanion toCompanion(bool nullToAbsent) {
    return DividendEventsCacheCompanion(
      symbol: Value(symbol),
      exDate: Value(exDate),
      amount: Value(amount),
      payDate: payDate == null && nullToAbsent ? const Value.absent() : Value(payDate),
    );
  }

  factory DividendRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DividendRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      exDate: serializer.fromJson<DateTime>(json['exDate']),
      amount: serializer.fromJson<double>(json['amount']),
      payDate: serializer.fromJson<DateTime?>(json['payDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'exDate': serializer.toJson<DateTime>(exDate),
      'amount': serializer.toJson<double>(amount),
      'payDate': serializer.toJson<DateTime?>(payDate),
    };
  }

  DividendRow copyWith({String? symbol, DateTime? exDate, double? amount, Value<DateTime?> payDate = const Value.absent()}) => DividendRow(
    symbol: symbol ?? this.symbol,
    exDate: exDate ?? this.exDate,
    amount: amount ?? this.amount,
    payDate: payDate.present ? payDate.value : this.payDate,
  );
  DividendRow copyWithCompanion(DividendEventsCacheCompanion data) {
    return DividendRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      exDate: data.exDate.present ? data.exDate.value : this.exDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      payDate: data.payDate.present ? data.payDate.value : this.payDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DividendRow(')
          ..write('symbol: $symbol, ')
          ..write('exDate: $exDate, ')
          ..write('amount: $amount, ')
          ..write('payDate: $payDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, exDate, amount, payDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DividendRow &&
          other.symbol == this.symbol &&
          other.exDate == this.exDate &&
          other.amount == this.amount &&
          other.payDate == this.payDate);
}

class DividendEventsCacheCompanion extends UpdateCompanion<DividendRow> {
  final Value<String> symbol;
  final Value<DateTime> exDate;
  final Value<double> amount;
  final Value<DateTime?> payDate;
  final Value<int> rowid;
  const DividendEventsCacheCompanion({
    this.symbol = const Value.absent(),
    this.exDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.payDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DividendEventsCacheCompanion.insert({
    required String symbol,
    required DateTime exDate,
    required double amount,
    this.payDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       exDate = Value(exDate),
       amount = Value(amount);
  static Insertable<DividendRow> custom({
    Expression<String>? symbol,
    Expression<String>? exDate,
    Expression<double>? amount,
    Expression<String>? payDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (exDate != null) 'ex_date': exDate,
      if (amount != null) 'amount': amount,
      if (payDate != null) 'pay_date': payDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DividendEventsCacheCompanion copyWith({
    Value<String>? symbol,
    Value<DateTime>? exDate,
    Value<double>? amount,
    Value<DateTime?>? payDate,
    Value<int>? rowid,
  }) {
    return DividendEventsCacheCompanion(
      symbol: symbol ?? this.symbol,
      exDate: exDate ?? this.exDate,
      amount: amount ?? this.amount,
      payDate: payDate ?? this.payDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (exDate.present) {
      map['ex_date'] = Variable<String>($DividendEventsCacheTable.$converterexDate.toSql(exDate.value));
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (payDate.present) {
      map['pay_date'] = Variable<String>($DividendEventsCacheTable.$converterpayDaten.toSql(payDate.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DividendEventsCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('exDate: $exDate, ')
          ..write('amount: $amount, ')
          ..write('payDate: $payDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitEventsCacheTable extends SplitEventsCache with TableInfo<$SplitEventsCacheTable, SplitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitEventsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<DateTime>($SplitEventsCacheTable.$converterdate);
  static const VerificationMeta _numeratorMeta = const VerificationMeta('numerator');
  @override
  late final GeneratedColumn<int> numerator = GeneratedColumn<int>(
    'numerator',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _denominatorMeta = const VerificationMeta('denominator');
  @override
  late final GeneratedColumn<int> denominator = GeneratedColumn<int>(
    'denominator',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, date, numerator, denominator];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_events_cache';
  @override
  VerificationContext validateIntegrity(Insertable<SplitRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta, symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('numerator')) {
      context.handle(_numeratorMeta, numerator.isAcceptableOrUnknown(data['numerator']!, _numeratorMeta));
    } else if (isInserting) {
      context.missing(_numeratorMeta);
    }
    if (data.containsKey('denominator')) {
      context.handle(_denominatorMeta, denominator.isAcceptableOrUnknown(data['denominator']!, _denominatorMeta));
    } else if (isInserting) {
      context.missing(_denominatorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol, date};
  @override
  SplitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitRow(
      symbol: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      date: $SplitEventsCacheTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      ),
      numerator: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}numerator'])!,
      denominator: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}denominator'])!,
    );
  }

  @override
  $SplitEventsCacheTable createAlias(String alias) {
    return $SplitEventsCacheTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterdate = const DateOnlyConverter();
}

class SplitRow extends DataClass implements Insertable<SplitRow> {
  final String symbol;
  final DateTime date;
  final int numerator;
  final int denominator;
  const SplitRow({required this.symbol, required this.date, required this.numerator, required this.denominator});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    {
      map['date'] = Variable<String>($SplitEventsCacheTable.$converterdate.toSql(date));
    }
    map['numerator'] = Variable<int>(numerator);
    map['denominator'] = Variable<int>(denominator);
    return map;
  }

  SplitEventsCacheCompanion toCompanion(bool nullToAbsent) {
    return SplitEventsCacheCompanion(
      symbol: Value(symbol),
      date: Value(date),
      numerator: Value(numerator),
      denominator: Value(denominator),
    );
  }

  factory SplitRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      date: serializer.fromJson<DateTime>(json['date']),
      numerator: serializer.fromJson<int>(json['numerator']),
      denominator: serializer.fromJson<int>(json['denominator']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'date': serializer.toJson<DateTime>(date),
      'numerator': serializer.toJson<int>(numerator),
      'denominator': serializer.toJson<int>(denominator),
    };
  }

  SplitRow copyWith({String? symbol, DateTime? date, int? numerator, int? denominator}) => SplitRow(
    symbol: symbol ?? this.symbol,
    date: date ?? this.date,
    numerator: numerator ?? this.numerator,
    denominator: denominator ?? this.denominator,
  );
  SplitRow copyWithCompanion(SplitEventsCacheCompanion data) {
    return SplitRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      date: data.date.present ? data.date.value : this.date,
      numerator: data.numerator.present ? data.numerator.value : this.numerator,
      denominator: data.denominator.present ? data.denominator.value : this.denominator,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitRow(')
          ..write('symbol: $symbol, ')
          ..write('date: $date, ')
          ..write('numerator: $numerator, ')
          ..write('denominator: $denominator')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, date, numerator, denominator);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitRow &&
          other.symbol == this.symbol &&
          other.date == this.date &&
          other.numerator == this.numerator &&
          other.denominator == this.denominator);
}

class SplitEventsCacheCompanion extends UpdateCompanion<SplitRow> {
  final Value<String> symbol;
  final Value<DateTime> date;
  final Value<int> numerator;
  final Value<int> denominator;
  final Value<int> rowid;
  const SplitEventsCacheCompanion({
    this.symbol = const Value.absent(),
    this.date = const Value.absent(),
    this.numerator = const Value.absent(),
    this.denominator = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitEventsCacheCompanion.insert({
    required String symbol,
    required DateTime date,
    required int numerator,
    required int denominator,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       date = Value(date),
       numerator = Value(numerator),
       denominator = Value(denominator);
  static Insertable<SplitRow> custom({
    Expression<String>? symbol,
    Expression<String>? date,
    Expression<int>? numerator,
    Expression<int>? denominator,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (date != null) 'date': date,
      if (numerator != null) 'numerator': numerator,
      if (denominator != null) 'denominator': denominator,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitEventsCacheCompanion copyWith({
    Value<String>? symbol,
    Value<DateTime>? date,
    Value<int>? numerator,
    Value<int>? denominator,
    Value<int>? rowid,
  }) {
    return SplitEventsCacheCompanion(
      symbol: symbol ?? this.symbol,
      date: date ?? this.date,
      numerator: numerator ?? this.numerator,
      denominator: denominator ?? this.denominator,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (date.present) {
      map['date'] = Variable<String>($SplitEventsCacheTable.$converterdate.toSql(date.value));
    }
    if (numerator.present) {
      map['numerator'] = Variable<int>(numerator.value);
    }
    if (denominator.present) {
      map['denominator'] = Variable<int>(denominator.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitEventsCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('date: $date, ')
          ..write('numerator: $numerator, ')
          ..write('denominator: $denominator, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportMappingsTable extends ImportMappings with TableInfo<$ImportMappingsTable, ImportMappingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
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
  static const VerificationMeta _mappingJsonMeta = const VerificationMeta('mappingJson');
  @override
  late final GeneratedColumn<String> mappingJson = GeneratedColumn<String>(
    'mapping_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, mappingJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_mappings';
  @override
  VerificationContext validateIntegrity(Insertable<ImportMappingRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mapping_json')) {
      context.handle(_mappingJsonMeta, mappingJson.isAcceptableOrUnknown(data['mapping_json']!, _mappingJsonMeta));
    } else if (isInserting) {
      context.missing(_mappingJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportMappingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportMappingRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      mappingJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mapping_json'])!,
    );
  }

  @override
  $ImportMappingsTable createAlias(String alias) {
    return $ImportMappingsTable(attachedDatabase, alias);
  }
}

class ImportMappingRow extends DataClass implements Insertable<ImportMappingRow> {
  final int id;
  final String name;
  final String mappingJson;
  const ImportMappingRow({required this.id, required this.name, required this.mappingJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['mapping_json'] = Variable<String>(mappingJson);
    return map;
  }

  ImportMappingsCompanion toCompanion(bool nullToAbsent) {
    return ImportMappingsCompanion(id: Value(id), name: Value(name), mappingJson: Value(mappingJson));
  }

  factory ImportMappingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportMappingRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mappingJson: serializer.fromJson<String>(json['mappingJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'mappingJson': serializer.toJson<String>(mappingJson),
    };
  }

  ImportMappingRow copyWith({int? id, String? name, String? mappingJson}) =>
      ImportMappingRow(id: id ?? this.id, name: name ?? this.name, mappingJson: mappingJson ?? this.mappingJson);
  ImportMappingRow copyWithCompanion(ImportMappingsCompanion data) {
    return ImportMappingRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mappingJson: data.mappingJson.present ? data.mappingJson.value : this.mappingJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportMappingRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mappingJson: $mappingJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, mappingJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportMappingRow && other.id == this.id && other.name == this.name && other.mappingJson == this.mappingJson);
}

class ImportMappingsCompanion extends UpdateCompanion<ImportMappingRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> mappingJson;
  const ImportMappingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mappingJson = const Value.absent(),
  });
  ImportMappingsCompanion.insert({this.id = const Value.absent(), required String name, required String mappingJson})
    : name = Value(name),
      mappingJson = Value(mappingJson);
  static Insertable<ImportMappingRow> custom({Expression<int>? id, Expression<String>? name, Expression<String>? mappingJson}) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mappingJson != null) 'mapping_json': mappingJson,
    });
  }

  ImportMappingsCompanion copyWith({Value<int>? id, Value<String>? name, Value<String>? mappingJson}) {
    return ImportMappingsCompanion(id: id ?? this.id, name: name ?? this.name, mappingJson: mappingJson ?? this.mappingJson);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mappingJson.present) {
      map['mapping_json'] = Variable<String>(mappingJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportMappingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mappingJson: $mappingJson')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(key: data.key.present ? data.key.value : this.key, value: data.value.present ? data.value.value : this.value);
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) => identical(this, other) || (other is SettingRow && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({this.key = const Value.absent(), this.value = const Value.absent(), this.rowid = const Value.absent()});
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<SettingRow> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({if (key != null) 'key': key, if (value != null) 'value': value, if (rowid != null) 'rowid': rowid});
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LunoAccountCursorsTable extends LunoAccountCursors with TableInfo<$LunoAccountCursorsTable, LunoCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LunoAccountCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta('connectionId');
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES luno_connections (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetMeta = const VerificationMeta('asset');
  @override
  late final GeneratedColumn<String> asset = GeneratedColumn<String>(
    'asset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastRowIndexMeta = const VerificationMeta('lastRowIndex');
  @override
  late final GeneratedColumn<int> lastRowIndex = GeneratedColumn<int>(
    'last_row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> balanceSnapshot = GeneratedColumn<String>(
    'balance_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  ).withConverter<Decimal>($LunoAccountCursorsTable.$converterbalanceSnapshot);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> reservedSnapshot = GeneratedColumn<String>(
    'reserved_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  ).withConverter<Decimal>($LunoAccountCursorsTable.$converterreservedSnapshot);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> unconfirmedSnapshot = GeneratedColumn<String>(
    'unconfirmed_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  ).withConverter<Decimal>($LunoAccountCursorsTable.$converterunconfirmedSnapshot);
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    accountId,
    asset,
    accountType,
    lastRowIndex,
    balanceSnapshot,
    reservedSnapshot,
    unconfirmedSnapshot,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'luno_account_cursors';
  @override
  VerificationContext validateIntegrity(Insertable<LunoCursorRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(_connectionIdMeta, connectionId.isAcceptableOrUnknown(data['connection_id']!, _connectionIdMeta));
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('asset')) {
      context.handle(_assetMeta, asset.isAcceptableOrUnknown(data['asset']!, _assetMeta));
    } else if (isInserting) {
      context.missing(_assetMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(_accountTypeMeta, accountType.isAcceptableOrUnknown(data['account_type']!, _accountTypeMeta));
    }
    if (data.containsKey('last_row_index')) {
      context.handle(_lastRowIndexMeta, lastRowIndex.isAcceptableOrUnknown(data['last_row_index']!, _lastRowIndexMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta, syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, accountId};
  @override
  LunoCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LunoCursorRow(
      connectionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}connection_id'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      asset: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}asset'])!,
      accountType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      lastRowIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_row_index'])!,
      balanceSnapshot: $LunoAccountCursorsTable.$converterbalanceSnapshot.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}balance_snapshot'])!,
      ),
      reservedSnapshot: $LunoAccountCursorsTable.$converterreservedSnapshot.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reserved_snapshot'])!,
      ),
      unconfirmedSnapshot: $LunoAccountCursorsTable.$converterunconfirmedSnapshot.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unconfirmed_snapshot'])!,
      ),
      syncedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LunoAccountCursorsTable createAlias(String alias) {
    return $LunoAccountCursorsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterbalanceSnapshot = const DecimalConverter();
  static TypeConverter<Decimal, String> $converterreservedSnapshot = const DecimalConverter();
  static TypeConverter<Decimal, String> $converterunconfirmedSnapshot = const DecimalConverter();
}

class LunoCursorRow extends DataClass implements Insertable<LunoCursorRow> {
  final int connectionId;
  final String accountId;
  final String asset;
  final String accountType;
  final int lastRowIndex;
  final Decimal balanceSnapshot;
  final Decimal reservedSnapshot;
  final Decimal unconfirmedSnapshot;
  final DateTime? syncedAt;
  const LunoCursorRow({
    required this.connectionId,
    required this.accountId,
    required this.asset,
    required this.accountType,
    required this.lastRowIndex,
    required this.balanceSnapshot,
    required this.reservedSnapshot,
    required this.unconfirmedSnapshot,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['account_id'] = Variable<String>(accountId);
    map['asset'] = Variable<String>(asset);
    map['account_type'] = Variable<String>(accountType);
    map['last_row_index'] = Variable<int>(lastRowIndex);
    {
      map['balance_snapshot'] = Variable<String>($LunoAccountCursorsTable.$converterbalanceSnapshot.toSql(balanceSnapshot));
    }
    {
      map['reserved_snapshot'] = Variable<String>($LunoAccountCursorsTable.$converterreservedSnapshot.toSql(reservedSnapshot));
    }
    {
      map['unconfirmed_snapshot'] = Variable<String>($LunoAccountCursorsTable.$converterunconfirmedSnapshot.toSql(unconfirmedSnapshot));
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LunoAccountCursorsCompanion toCompanion(bool nullToAbsent) {
    return LunoAccountCursorsCompanion(
      connectionId: Value(connectionId),
      accountId: Value(accountId),
      asset: Value(asset),
      accountType: Value(accountType),
      lastRowIndex: Value(lastRowIndex),
      balanceSnapshot: Value(balanceSnapshot),
      reservedSnapshot: Value(reservedSnapshot),
      unconfirmedSnapshot: Value(unconfirmedSnapshot),
      syncedAt: syncedAt == null && nullToAbsent ? const Value.absent() : Value(syncedAt),
    );
  }

  factory LunoCursorRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LunoCursorRow(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      asset: serializer.fromJson<String>(json['asset']),
      accountType: serializer.fromJson<String>(json['accountType']),
      lastRowIndex: serializer.fromJson<int>(json['lastRowIndex']),
      balanceSnapshot: serializer.fromJson<Decimal>(json['balanceSnapshot']),
      reservedSnapshot: serializer.fromJson<Decimal>(json['reservedSnapshot']),
      unconfirmedSnapshot: serializer.fromJson<Decimal>(json['unconfirmedSnapshot']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'accountId': serializer.toJson<String>(accountId),
      'asset': serializer.toJson<String>(asset),
      'accountType': serializer.toJson<String>(accountType),
      'lastRowIndex': serializer.toJson<int>(lastRowIndex),
      'balanceSnapshot': serializer.toJson<Decimal>(balanceSnapshot),
      'reservedSnapshot': serializer.toJson<Decimal>(reservedSnapshot),
      'unconfirmedSnapshot': serializer.toJson<Decimal>(unconfirmedSnapshot),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LunoCursorRow copyWith({
    int? connectionId,
    String? accountId,
    String? asset,
    String? accountType,
    int? lastRowIndex,
    Decimal? balanceSnapshot,
    Decimal? reservedSnapshot,
    Decimal? unconfirmedSnapshot,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LunoCursorRow(
    connectionId: connectionId ?? this.connectionId,
    accountId: accountId ?? this.accountId,
    asset: asset ?? this.asset,
    accountType: accountType ?? this.accountType,
    lastRowIndex: lastRowIndex ?? this.lastRowIndex,
    balanceSnapshot: balanceSnapshot ?? this.balanceSnapshot,
    reservedSnapshot: reservedSnapshot ?? this.reservedSnapshot,
    unconfirmedSnapshot: unconfirmedSnapshot ?? this.unconfirmedSnapshot,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LunoCursorRow copyWithCompanion(LunoAccountCursorsCompanion data) {
    return LunoCursorRow(
      connectionId: data.connectionId.present ? data.connectionId.value : this.connectionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      asset: data.asset.present ? data.asset.value : this.asset,
      accountType: data.accountType.present ? data.accountType.value : this.accountType,
      lastRowIndex: data.lastRowIndex.present ? data.lastRowIndex.value : this.lastRowIndex,
      balanceSnapshot: data.balanceSnapshot.present ? data.balanceSnapshot.value : this.balanceSnapshot,
      reservedSnapshot: data.reservedSnapshot.present ? data.reservedSnapshot.value : this.reservedSnapshot,
      unconfirmedSnapshot: data.unconfirmedSnapshot.present ? data.unconfirmedSnapshot.value : this.unconfirmedSnapshot,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LunoCursorRow(')
          ..write('connectionId: $connectionId, ')
          ..write('accountId: $accountId, ')
          ..write('asset: $asset, ')
          ..write('accountType: $accountType, ')
          ..write('lastRowIndex: $lastRowIndex, ')
          ..write('balanceSnapshot: $balanceSnapshot, ')
          ..write('reservedSnapshot: $reservedSnapshot, ')
          ..write('unconfirmedSnapshot: $unconfirmedSnapshot, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    connectionId,
    accountId,
    asset,
    accountType,
    lastRowIndex,
    balanceSnapshot,
    reservedSnapshot,
    unconfirmedSnapshot,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LunoCursorRow &&
          other.connectionId == this.connectionId &&
          other.accountId == this.accountId &&
          other.asset == this.asset &&
          other.accountType == this.accountType &&
          other.lastRowIndex == this.lastRowIndex &&
          other.balanceSnapshot == this.balanceSnapshot &&
          other.reservedSnapshot == this.reservedSnapshot &&
          other.unconfirmedSnapshot == this.unconfirmedSnapshot &&
          other.syncedAt == this.syncedAt);
}

class LunoAccountCursorsCompanion extends UpdateCompanion<LunoCursorRow> {
  final Value<int> connectionId;
  final Value<String> accountId;
  final Value<String> asset;
  final Value<String> accountType;
  final Value<int> lastRowIndex;
  final Value<Decimal> balanceSnapshot;
  final Value<Decimal> reservedSnapshot;
  final Value<Decimal> unconfirmedSnapshot;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LunoAccountCursorsCompanion({
    this.connectionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.asset = const Value.absent(),
    this.accountType = const Value.absent(),
    this.lastRowIndex = const Value.absent(),
    this.balanceSnapshot = const Value.absent(),
    this.reservedSnapshot = const Value.absent(),
    this.unconfirmedSnapshot = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LunoAccountCursorsCompanion.insert({
    required int connectionId,
    required String accountId,
    required String asset,
    this.accountType = const Value.absent(),
    this.lastRowIndex = const Value.absent(),
    this.balanceSnapshot = const Value.absent(),
    this.reservedSnapshot = const Value.absent(),
    this.unconfirmedSnapshot = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       accountId = Value(accountId),
       asset = Value(asset);
  static Insertable<LunoCursorRow> custom({
    Expression<int>? connectionId,
    Expression<String>? accountId,
    Expression<String>? asset,
    Expression<String>? accountType,
    Expression<int>? lastRowIndex,
    Expression<String>? balanceSnapshot,
    Expression<String>? reservedSnapshot,
    Expression<String>? unconfirmedSnapshot,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (accountId != null) 'account_id': accountId,
      if (asset != null) 'asset': asset,
      if (accountType != null) 'account_type': accountType,
      if (lastRowIndex != null) 'last_row_index': lastRowIndex,
      if (balanceSnapshot != null) 'balance_snapshot': balanceSnapshot,
      if (reservedSnapshot != null) 'reserved_snapshot': reservedSnapshot,
      if (unconfirmedSnapshot != null) 'unconfirmed_snapshot': unconfirmedSnapshot,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LunoAccountCursorsCompanion copyWith({
    Value<int>? connectionId,
    Value<String>? accountId,
    Value<String>? asset,
    Value<String>? accountType,
    Value<int>? lastRowIndex,
    Value<Decimal>? balanceSnapshot,
    Value<Decimal>? reservedSnapshot,
    Value<Decimal>? unconfirmedSnapshot,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LunoAccountCursorsCompanion(
      connectionId: connectionId ?? this.connectionId,
      accountId: accountId ?? this.accountId,
      asset: asset ?? this.asset,
      accountType: accountType ?? this.accountType,
      lastRowIndex: lastRowIndex ?? this.lastRowIndex,
      balanceSnapshot: balanceSnapshot ?? this.balanceSnapshot,
      reservedSnapshot: reservedSnapshot ?? this.reservedSnapshot,
      unconfirmedSnapshot: unconfirmedSnapshot ?? this.unconfirmedSnapshot,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (asset.present) {
      map['asset'] = Variable<String>(asset.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (lastRowIndex.present) {
      map['last_row_index'] = Variable<int>(lastRowIndex.value);
    }
    if (balanceSnapshot.present) {
      map['balance_snapshot'] = Variable<String>($LunoAccountCursorsTable.$converterbalanceSnapshot.toSql(balanceSnapshot.value));
    }
    if (reservedSnapshot.present) {
      map['reserved_snapshot'] = Variable<String>($LunoAccountCursorsTable.$converterreservedSnapshot.toSql(reservedSnapshot.value));
    }
    if (unconfirmedSnapshot.present) {
      map['unconfirmed_snapshot'] = Variable<String>(
        $LunoAccountCursorsTable.$converterunconfirmedSnapshot.toSql(unconfirmedSnapshot.value),
      );
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LunoAccountCursorsCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('accountId: $accountId, ')
          ..write('asset: $asset, ')
          ..write('accountType: $accountType, ')
          ..write('lastRowIndex: $lastRowIndex, ')
          ..write('balanceSnapshot: $balanceSnapshot, ')
          ..write('reservedSnapshot: $reservedSnapshot, ')
          ..write('unconfirmedSnapshot: $unconfirmedSnapshot, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LunoMarketsCacheTable extends LunoMarketsCache with TableInfo<$LunoMarketsCacheTable, LunoMarketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LunoMarketsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairMeta = const VerificationMeta('pair');
  @override
  late final GeneratedColumn<String> pair = GeneratedColumn<String>(
    'pair',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
    'base',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterMeta = const VerificationMeta('counter');
  @override
  late final GeneratedColumn<String> counter = GeneratedColumn<String>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceScaleMeta = const VerificationMeta('priceScale');
  @override
  late final GeneratedColumn<int> priceScale = GeneratedColumn<int>(
    'price_scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _volumeScaleMeta = const VerificationMeta('volumeScale');
  @override
  late final GeneratedColumn<int> volumeScale = GeneratedColumn<int>(
    'volume_scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tradingStatusMeta = const VerificationMeta('tradingStatus');
  @override
  late final GeneratedColumn<String> tradingStatus = GeneratedColumn<String>(
    'trading_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNKNOWN'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pair, base, counter, priceScale, volumeScale, tradingStatus, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'luno_markets_cache';
  @override
  VerificationContext validateIntegrity(Insertable<LunoMarketRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair')) {
      context.handle(_pairMeta, pair.isAcceptableOrUnknown(data['pair']!, _pairMeta));
    } else if (isInserting) {
      context.missing(_pairMeta);
    }
    if (data.containsKey('base')) {
      context.handle(_baseMeta, base.isAcceptableOrUnknown(data['base']!, _baseMeta));
    } else if (isInserting) {
      context.missing(_baseMeta);
    }
    if (data.containsKey('counter')) {
      context.handle(_counterMeta, counter.isAcceptableOrUnknown(data['counter']!, _counterMeta));
    } else if (isInserting) {
      context.missing(_counterMeta);
    }
    if (data.containsKey('price_scale')) {
      context.handle(_priceScaleMeta, priceScale.isAcceptableOrUnknown(data['price_scale']!, _priceScaleMeta));
    }
    if (data.containsKey('volume_scale')) {
      context.handle(_volumeScaleMeta, volumeScale.isAcceptableOrUnknown(data['volume_scale']!, _volumeScaleMeta));
    }
    if (data.containsKey('trading_status')) {
      context.handle(_tradingStatusMeta, tradingStatus.isAcceptableOrUnknown(data['trading_status']!, _tradingStatusMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta, fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pair};
  @override
  LunoMarketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LunoMarketRow(
      pair: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}pair'])!,
      base: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}base'])!,
      counter: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}counter'])!,
      priceScale: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}price_scale'])!,
      volumeScale: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}volume_scale'])!,
      tradingStatus: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}trading_status'])!,
      fetchedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $LunoMarketsCacheTable createAlias(String alias) {
    return $LunoMarketsCacheTable(attachedDatabase, alias);
  }
}

class LunoMarketRow extends DataClass implements Insertable<LunoMarketRow> {
  final String pair;
  final String base;
  final String counter;
  final int priceScale;
  final int volumeScale;
  final String tradingStatus;
  final DateTime fetchedAt;
  const LunoMarketRow({
    required this.pair,
    required this.base,
    required this.counter,
    required this.priceScale,
    required this.volumeScale,
    required this.tradingStatus,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair'] = Variable<String>(pair);
    map['base'] = Variable<String>(base);
    map['counter'] = Variable<String>(counter);
    map['price_scale'] = Variable<int>(priceScale);
    map['volume_scale'] = Variable<int>(volumeScale);
    map['trading_status'] = Variable<String>(tradingStatus);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  LunoMarketsCacheCompanion toCompanion(bool nullToAbsent) {
    return LunoMarketsCacheCompanion(
      pair: Value(pair),
      base: Value(base),
      counter: Value(counter),
      priceScale: Value(priceScale),
      volumeScale: Value(volumeScale),
      tradingStatus: Value(tradingStatus),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory LunoMarketRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LunoMarketRow(
      pair: serializer.fromJson<String>(json['pair']),
      base: serializer.fromJson<String>(json['base']),
      counter: serializer.fromJson<String>(json['counter']),
      priceScale: serializer.fromJson<int>(json['priceScale']),
      volumeScale: serializer.fromJson<int>(json['volumeScale']),
      tradingStatus: serializer.fromJson<String>(json['tradingStatus']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pair': serializer.toJson<String>(pair),
      'base': serializer.toJson<String>(base),
      'counter': serializer.toJson<String>(counter),
      'priceScale': serializer.toJson<int>(priceScale),
      'volumeScale': serializer.toJson<int>(volumeScale),
      'tradingStatus': serializer.toJson<String>(tradingStatus),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  LunoMarketRow copyWith({
    String? pair,
    String? base,
    String? counter,
    int? priceScale,
    int? volumeScale,
    String? tradingStatus,
    DateTime? fetchedAt,
  }) => LunoMarketRow(
    pair: pair ?? this.pair,
    base: base ?? this.base,
    counter: counter ?? this.counter,
    priceScale: priceScale ?? this.priceScale,
    volumeScale: volumeScale ?? this.volumeScale,
    tradingStatus: tradingStatus ?? this.tradingStatus,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  LunoMarketRow copyWithCompanion(LunoMarketsCacheCompanion data) {
    return LunoMarketRow(
      pair: data.pair.present ? data.pair.value : this.pair,
      base: data.base.present ? data.base.value : this.base,
      counter: data.counter.present ? data.counter.value : this.counter,
      priceScale: data.priceScale.present ? data.priceScale.value : this.priceScale,
      volumeScale: data.volumeScale.present ? data.volumeScale.value : this.volumeScale,
      tradingStatus: data.tradingStatus.present ? data.tradingStatus.value : this.tradingStatus,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LunoMarketRow(')
          ..write('pair: $pair, ')
          ..write('base: $base, ')
          ..write('counter: $counter, ')
          ..write('priceScale: $priceScale, ')
          ..write('volumeScale: $volumeScale, ')
          ..write('tradingStatus: $tradingStatus, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pair, base, counter, priceScale, volumeScale, tradingStatus, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LunoMarketRow &&
          other.pair == this.pair &&
          other.base == this.base &&
          other.counter == this.counter &&
          other.priceScale == this.priceScale &&
          other.volumeScale == this.volumeScale &&
          other.tradingStatus == this.tradingStatus &&
          other.fetchedAt == this.fetchedAt);
}

class LunoMarketsCacheCompanion extends UpdateCompanion<LunoMarketRow> {
  final Value<String> pair;
  final Value<String> base;
  final Value<String> counter;
  final Value<int> priceScale;
  final Value<int> volumeScale;
  final Value<String> tradingStatus;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const LunoMarketsCacheCompanion({
    this.pair = const Value.absent(),
    this.base = const Value.absent(),
    this.counter = const Value.absent(),
    this.priceScale = const Value.absent(),
    this.volumeScale = const Value.absent(),
    this.tradingStatus = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LunoMarketsCacheCompanion.insert({
    required String pair,
    required String base,
    required String counter,
    this.priceScale = const Value.absent(),
    this.volumeScale = const Value.absent(),
    this.tradingStatus = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : pair = Value(pair),
       base = Value(base),
       counter = Value(counter),
       fetchedAt = Value(fetchedAt);
  static Insertable<LunoMarketRow> custom({
    Expression<String>? pair,
    Expression<String>? base,
    Expression<String>? counter,
    Expression<int>? priceScale,
    Expression<int>? volumeScale,
    Expression<String>? tradingStatus,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pair != null) 'pair': pair,
      if (base != null) 'base': base,
      if (counter != null) 'counter': counter,
      if (priceScale != null) 'price_scale': priceScale,
      if (volumeScale != null) 'volume_scale': volumeScale,
      if (tradingStatus != null) 'trading_status': tradingStatus,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LunoMarketsCacheCompanion copyWith({
    Value<String>? pair,
    Value<String>? base,
    Value<String>? counter,
    Value<int>? priceScale,
    Value<int>? volumeScale,
    Value<String>? tradingStatus,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return LunoMarketsCacheCompanion(
      pair: pair ?? this.pair,
      base: base ?? this.base,
      counter: counter ?? this.counter,
      priceScale: priceScale ?? this.priceScale,
      volumeScale: volumeScale ?? this.volumeScale,
      tradingStatus: tradingStatus ?? this.tradingStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pair.present) {
      map['pair'] = Variable<String>(pair.value);
    }
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (counter.present) {
      map['counter'] = Variable<String>(counter.value);
    }
    if (priceScale.present) {
      map['price_scale'] = Variable<int>(priceScale.value);
    }
    if (volumeScale.present) {
      map['volume_scale'] = Variable<int>(volumeScale.value);
    }
    if (tradingStatus.present) {
      map['trading_status'] = Variable<String>(tradingStatus.value);
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
    return (StringBuffer('LunoMarketsCacheCompanion(')
          ..write('pair: $pair, ')
          ..write('base: $base, ')
          ..write('counter: $counter, ')
          ..write('priceScale: $priceScale, ')
          ..write('volumeScale: $volumeScale, ')
          ..write('tradingStatus: $tradingStatus, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LunoLedgerRowsTable extends LunoLedgerRows with TableInfo<$LunoLedgerRowsTable, LunoLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LunoLedgerRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta('connectionId');
  @override
  late final GeneratedColumn<int> connectionId = GeneratedColumn<int>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES luno_connections (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta('rowIndex');
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta('timestampMs');
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [connectionId, accountId, rowIndex, timestampMs, payloadJson, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'luno_ledger_rows';
  @override
  VerificationContext validateIntegrity(Insertable<LunoLedgerRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(_connectionIdMeta, connectionId.isAcceptableOrUnknown(data['connection_id']!, _connectionIdMeta));
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta, accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('row_index')) {
      context.handle(_rowIndexMeta, rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta));
    } else if (isInserting) {
      context.missing(_rowIndexMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(_timestampMsMeta, timestampMs.isAcceptableOrUnknown(data['timestamp_ms']!, _timestampMsMeta));
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(_payloadJsonMeta, payloadJson.isAcceptableOrUnknown(data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('state')) {
      context.handle(_stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, accountId, rowIndex};
  @override
  LunoLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LunoLedgerRow(
      connectionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}connection_id'])!,
      accountId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      rowIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}row_index'])!,
      timestampMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}timestamp_ms'])!,
      payloadJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      state: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}state'])!,
    );
  }

  @override
  $LunoLedgerRowsTable createAlias(String alias) {
    return $LunoLedgerRowsTable(attachedDatabase, alias);
  }
}

class LunoLedgerRow extends DataClass implements Insertable<LunoLedgerRow> {
  final int connectionId;
  final String accountId;
  final int rowIndex;
  final int timestampMs;

  /// The row as returned by the API (JSON), with ledger numbers quoted so decimals survive.
  final String payloadJson;

  /// `pending` (not yet mapped, or waiting for its counterpart) | `mapped` | `unrecognised`.
  final String state;
  const LunoLedgerRow({
    required this.connectionId,
    required this.accountId,
    required this.rowIndex,
    required this.timestampMs,
    required this.payloadJson,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<int>(connectionId);
    map['account_id'] = Variable<String>(accountId);
    map['row_index'] = Variable<int>(rowIndex);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['payload_json'] = Variable<String>(payloadJson);
    map['state'] = Variable<String>(state);
    return map;
  }

  LunoLedgerRowsCompanion toCompanion(bool nullToAbsent) {
    return LunoLedgerRowsCompanion(
      connectionId: Value(connectionId),
      accountId: Value(accountId),
      rowIndex: Value(rowIndex),
      timestampMs: Value(timestampMs),
      payloadJson: Value(payloadJson),
      state: Value(state),
    );
  }

  factory LunoLedgerRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LunoLedgerRow(
      connectionId: serializer.fromJson<int>(json['connectionId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<int>(connectionId),
      'accountId': serializer.toJson<String>(accountId),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'state': serializer.toJson<String>(state),
    };
  }

  LunoLedgerRow copyWith({int? connectionId, String? accountId, int? rowIndex, int? timestampMs, String? payloadJson, String? state}) =>
      LunoLedgerRow(
        connectionId: connectionId ?? this.connectionId,
        accountId: accountId ?? this.accountId,
        rowIndex: rowIndex ?? this.rowIndex,
        timestampMs: timestampMs ?? this.timestampMs,
        payloadJson: payloadJson ?? this.payloadJson,
        state: state ?? this.state,
      );
  LunoLedgerRow copyWithCompanion(LunoLedgerRowsCompanion data) {
    return LunoLedgerRow(
      connectionId: data.connectionId.present ? data.connectionId.value : this.connectionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      timestampMs: data.timestampMs.present ? data.timestampMs.value : this.timestampMs,
      payloadJson: data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LunoLedgerRow(')
          ..write('connectionId: $connectionId, ')
          ..write('accountId: $accountId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(connectionId, accountId, rowIndex, timestampMs, payloadJson, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LunoLedgerRow &&
          other.connectionId == this.connectionId &&
          other.accountId == this.accountId &&
          other.rowIndex == this.rowIndex &&
          other.timestampMs == this.timestampMs &&
          other.payloadJson == this.payloadJson &&
          other.state == this.state);
}

class LunoLedgerRowsCompanion extends UpdateCompanion<LunoLedgerRow> {
  final Value<int> connectionId;
  final Value<String> accountId;
  final Value<int> rowIndex;
  final Value<int> timestampMs;
  final Value<String> payloadJson;
  final Value<String> state;
  final Value<int> rowid;
  const LunoLedgerRowsCompanion({
    this.connectionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LunoLedgerRowsCompanion.insert({
    required int connectionId,
    required String accountId,
    required int rowIndex,
    required int timestampMs,
    required String payloadJson,
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       accountId = Value(accountId),
       rowIndex = Value(rowIndex),
       timestampMs = Value(timestampMs),
       payloadJson = Value(payloadJson);
  static Insertable<LunoLedgerRow> custom({
    Expression<int>? connectionId,
    Expression<String>? accountId,
    Expression<int>? rowIndex,
    Expression<int>? timestampMs,
    Expression<String>? payloadJson,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (accountId != null) 'account_id': accountId,
      if (rowIndex != null) 'row_index': rowIndex,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LunoLedgerRowsCompanion copyWith({
    Value<int>? connectionId,
    Value<String>? accountId,
    Value<int>? rowIndex,
    Value<int>? timestampMs,
    Value<String>? payloadJson,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return LunoLedgerRowsCompanion(
      connectionId: connectionId ?? this.connectionId,
      accountId: accountId ?? this.accountId,
      rowIndex: rowIndex ?? this.rowIndex,
      timestampMs: timestampMs ?? this.timestampMs,
      payloadJson: payloadJson ?? this.payloadJson,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<int>(connectionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LunoLedgerRowsCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('accountId: $accountId, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PortfoliosTable portfolios = $PortfoliosTable(this);
  late final $InstrumentsTable instruments = $InstrumentsTable(this);
  late final $LunoConnectionsTable lunoConnections = $LunoConnectionsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $WatchlistsTable watchlists = $WatchlistsTable(this);
  late final $WatchlistItemsTable watchlistItems = $WatchlistItemsTable(this);
  late final $QuoteCacheTable quoteCache = $QuoteCacheTable(this);
  late final $ProfileCacheTable profileCache = $ProfileCacheTable(this);
  late final $PriceHistoryCacheTable priceHistoryCache = $PriceHistoryCacheTable(this);
  late final $HistoryMetaTable historyMeta = $HistoryMetaTable(this);
  late final $DividendEventsCacheTable dividendEventsCache = $DividendEventsCacheTable(this);
  late final $SplitEventsCacheTable splitEventsCache = $SplitEventsCacheTable(this);
  late final $ImportMappingsTable importMappings = $ImportMappingsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $LunoAccountCursorsTable lunoAccountCursors = $LunoAccountCursorsTable(this);
  late final $LunoMarketsCacheTable lunoMarketsCache = $LunoMarketsCacheTable(this);
  late final $LunoLedgerRowsTable lunoLedgerRows = $LunoLedgerRowsTable(this);
  late final Index transactionsConnectionExternal = Index(
    'transactions_connection_external',
    'CREATE UNIQUE INDEX transactions_connection_external ON transactions (connection_id, external_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    portfolios,
    instruments,
    lunoConnections,
    transactions,
    watchlists,
    watchlistItems,
    quoteCache,
    profileCache,
    priceHistoryCache,
    historyMeta,
    dividendEventsCache,
    splitEventsCache,
    importMappings,
    settings,
    lunoAccountCursors,
    lunoMarketsCache,
    lunoLedgerRows,
    transactionsConnectionExternal,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('portfolios', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('luno_connections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('portfolios', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('luno_connections', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('watchlists', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('watchlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('luno_connections', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('luno_account_cursors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('luno_connections', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('luno_ledger_rows', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PortfoliosTableCreateCompanionBuilder = PortfoliosCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  Value<int> color,
  Value<String> costBasisMethod,
  Value<int> sortOrder,
  Value<bool> archived,
  required DateTime createdAt,
});
typedef $$PortfoliosTableUpdateCompanionBuilder = PortfoliosCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<int> color,
  Value<String> costBasisMethod,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<DateTime> createdAt,
});

final class $$PortfoliosTableReferences extends BaseReferences<_$AppDatabase, $PortfoliosTable, PortfolioRow> {
  $$PortfoliosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LunoConnectionsTable, List<LunoConnectionRow>> _lunoConnectionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lunoConnections, aliasName: 'portfolios__id__luno_connections__portfolio_id');

  $$LunoConnectionsTableProcessedTableManager get lunoConnectionsRefs {
    final manager = $$LunoConnectionsTableTableManager(
      $_db,
      $_db.lunoConnections,
    ).filter((f) => f.portfolioId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lunoConnectionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>> _transactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'portfolios__id__transactions__portfolio_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.portfolioId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PortfoliosTableFilterComposer extends Composer<_$AppDatabase, $PortfoliosTable> {
  $$PortfoliosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get costBasisMethod =>
      $composableBuilder(column: $table.costBasisMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> lunoConnectionsRefs(Expression<bool> Function($$LunoConnectionsTableFilterComposer f) f) {
    final $$LunoConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.portfolioId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableFilterComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.portfolioId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableFilterComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$PortfoliosTableOrderingComposer extends Composer<_$AppDatabase, $PortfoliosTable> {
  $$PortfoliosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get costBasisMethod =>
      $composableBuilder(column: $table.costBasisMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PortfoliosTableAnnotationComposer extends Composer<_$AppDatabase, $PortfoliosTable> {
  $$PortfoliosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get costBasisMethod => $composableBuilder(column: $table.costBasisMethod, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> lunoConnectionsRefs<T extends Object>(Expression<T> Function($$LunoConnectionsTableAnnotationComposer a) f) {
    final $$LunoConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.portfolioId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.portfolioId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableAnnotationComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$PortfoliosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PortfoliosTable,
          PortfolioRow,
          $$PortfoliosTableFilterComposer,
          $$PortfoliosTableOrderingComposer,
          $$PortfoliosTableAnnotationComposer,
          $$PortfoliosTableCreateCompanionBuilder,
          $$PortfoliosTableUpdateCompanionBuilder,
          (PortfolioRow, $$PortfoliosTableReferences),
          PortfolioRow,
          PrefetchHooks Function({bool lunoConnectionsRefs, bool transactionsRefs})
        > {
  $$PortfoliosTableTableManager(_$AppDatabase db, $PortfoliosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PortfoliosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PortfoliosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PortfoliosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> costBasisMethod = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PortfoliosCompanion(
                id: id,
                name: name,
                description: description,
                color: color,
                costBasisMethod: costBasisMethod,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String> costBasisMethod = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
              }) => PortfoliosCompanion.insert(
                id: id,
                name: name,
                description: description,
                color: color,
                costBasisMethod: costBasisMethod,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$PortfoliosTable, PortfolioRow>(table), $$PortfoliosTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({lunoConnectionsRefs = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lunoConnectionsRefs) db.lunoConnections, if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lunoConnectionsRefs)
                    await $_getPrefetchedData<PortfolioRow, $PortfoliosTable, LunoConnectionRow>(
                      currentTable: table,
                      referencedTable: $$PortfoliosTableReferences._lunoConnectionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PortfoliosTableReferences(db, table, p0).lunoConnectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.portfolioId == item.id),
                      typedResults: items,
                    ),
                  if (transactionsRefs)
                    await $_getPrefetchedData<PortfolioRow, $PortfoliosTable, TransactionRow>(
                      currentTable: table,
                      referencedTable: $$PortfoliosTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PortfoliosTableReferences(db, table, p0).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.portfolioId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PortfoliosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PortfoliosTable,
      PortfolioRow,
      $$PortfoliosTableFilterComposer,
      $$PortfoliosTableOrderingComposer,
      $$PortfoliosTableAnnotationComposer,
      $$PortfoliosTableCreateCompanionBuilder,
      $$PortfoliosTableUpdateCompanionBuilder,
      (PortfolioRow, $$PortfoliosTableReferences),
      PortfolioRow,
      PrefetchHooks Function({bool lunoConnectionsRefs, bool transactionsRefs})
    >;
typedef $$InstrumentsTableCreateCompanionBuilder = InstrumentsCompanion Function({
  required String symbol,
  required String name,
  Value<String?> quoteType,
  Value<String?> exchange,
  Value<String> currency,
  Value<String?> sector,
  Value<String?> industry,
  Value<DateTime?> lastMetaRefresh,
  Value<int> rowid,
});
typedef $$InstrumentsTableUpdateCompanionBuilder = InstrumentsCompanion Function({
  Value<String> symbol,
  Value<String> name,
  Value<String?> quoteType,
  Value<String?> exchange,
  Value<String> currency,
  Value<String?> sector,
  Value<String?> industry,
  Value<DateTime?> lastMetaRefresh,
  Value<int> rowid,
});

class $$InstrumentsTableFilterComposer extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quoteType => $composableBuilder(column: $table.quoteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exchange => $composableBuilder(column: $table.exchange, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sector => $composableBuilder(column: $table.sector, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get industry => $composableBuilder(column: $table.industry, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMetaRefresh =>
      $composableBuilder(column: $table.lastMetaRefresh, builder: (column) => ColumnFilters(column));
}

class $$InstrumentsTableOrderingComposer extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quoteType => $composableBuilder(column: $table.quoteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exchange => $composableBuilder(column: $table.exchange, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sector => $composableBuilder(column: $table.sector, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get industry => $composableBuilder(column: $table.industry, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMetaRefresh =>
      $composableBuilder(column: $table.lastMetaRefresh, builder: (column) => ColumnOrderings(column));
}

class $$InstrumentsTableAnnotationComposer extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quoteType => $composableBuilder(column: $table.quoteType, builder: (column) => column);

  GeneratedColumn<String> get exchange => $composableBuilder(column: $table.exchange, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get sector => $composableBuilder(column: $table.sector, builder: (column) => column);

  GeneratedColumn<String> get industry => $composableBuilder(column: $table.industry, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMetaRefresh => $composableBuilder(column: $table.lastMetaRefresh, builder: (column) => column);
}

class $$InstrumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstrumentsTable,
          InstrumentRow,
          $$InstrumentsTableFilterComposer,
          $$InstrumentsTableOrderingComposer,
          $$InstrumentsTableAnnotationComposer,
          $$InstrumentsTableCreateCompanionBuilder,
          $$InstrumentsTableUpdateCompanionBuilder,
          (InstrumentRow, BaseReferences<_$AppDatabase, $InstrumentsTable, InstrumentRow>),
          InstrumentRow,
          PrefetchHooks Function()
        > {
  $$InstrumentsTableTableManager(_$AppDatabase db, $InstrumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$InstrumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$InstrumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$InstrumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quoteType = const Value.absent(),
                Value<String?> exchange = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> sector = const Value.absent(),
                Value<String?> industry = const Value.absent(),
                Value<DateTime?> lastMetaRefresh = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentsCompanion(
                symbol: symbol,
                name: name,
                quoteType: quoteType,
                exchange: exchange,
                currency: currency,
                sector: sector,
                industry: industry,
                lastMetaRefresh: lastMetaRefresh,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String name,
                Value<String?> quoteType = const Value.absent(),
                Value<String?> exchange = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> sector = const Value.absent(),
                Value<String?> industry = const Value.absent(),
                Value<DateTime?> lastMetaRefresh = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentsCompanion.insert(
                symbol: symbol,
                name: name,
                quoteType: quoteType,
                exchange: exchange,
                currency: currency,
                sector: sector,
                industry: industry,
                lastMetaRefresh: lastMetaRefresh,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstrumentsTable, InstrumentRow>(table),
                  BaseReferences<_$AppDatabase, $InstrumentsTable, InstrumentRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstrumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstrumentsTable,
      InstrumentRow,
      $$InstrumentsTableFilterComposer,
      $$InstrumentsTableOrderingComposer,
      $$InstrumentsTableAnnotationComposer,
      $$InstrumentsTableCreateCompanionBuilder,
      $$InstrumentsTableUpdateCompanionBuilder,
      (InstrumentRow, BaseReferences<_$AppDatabase, $InstrumentsTable, InstrumentRow>),
      InstrumentRow,
      PrefetchHooks Function()
    >;
typedef $$LunoConnectionsTableCreateCompanionBuilder = LunoConnectionsCompanion Function({
  Value<int> id,
  required String label,
  required int portfolioId,
  Value<String> keyIdHint,
  required String homeFiat,
  Value<String> status,
  Value<DateTime?> lastSyncAt,
  Value<String?> lastError,
  Value<bool> writePermWarning,
  Value<int> unrecognisedRows,
  required DateTime createdAt,
});
typedef $$LunoConnectionsTableUpdateCompanionBuilder = LunoConnectionsCompanion Function({
  Value<int> id,
  Value<String> label,
  Value<int> portfolioId,
  Value<String> keyIdHint,
  Value<String> homeFiat,
  Value<String> status,
  Value<DateTime?> lastSyncAt,
  Value<String?> lastError,
  Value<bool> writePermWarning,
  Value<int> unrecognisedRows,
  Value<DateTime> createdAt,
});

final class $$LunoConnectionsTableReferences extends BaseReferences<_$AppDatabase, $LunoConnectionsTable, LunoConnectionRow> {
  $$LunoConnectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PortfoliosTable _portfolioIdTable(_$AppDatabase db) =>
      db.portfolios.createAlias('luno_connections__portfolio_id__portfolios__id');

  $$PortfoliosTableProcessedTableManager get portfolioId {
    final $_column = $_itemColumn<int>('portfolio_id')!;

    final manager = $$PortfoliosTableTableManager($_db, $_db.portfolios).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_portfolioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>> _transactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'luno_connections__id__transactions__connection_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LunoAccountCursorsTable, List<LunoCursorRow>> _lunoAccountCursorsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lunoAccountCursors, aliasName: 'luno_connections__id__luno_account_cursors__connection_id');

  $$LunoAccountCursorsTableProcessedTableManager get lunoAccountCursorsRefs {
    final manager = $$LunoAccountCursorsTableTableManager(
      $_db,
      $_db.lunoAccountCursors,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lunoAccountCursorsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LunoLedgerRowsTable, List<LunoLedgerRow>> _lunoLedgerRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lunoLedgerRows, aliasName: 'luno_connections__id__luno_ledger_rows__connection_id');

  $$LunoLedgerRowsTableProcessedTableManager get lunoLedgerRowsRefs {
    final manager = $$LunoLedgerRowsTableTableManager(
      $_db,
      $_db.lunoLedgerRows,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lunoLedgerRowsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LunoConnectionsTableFilterComposer extends Composer<_$AppDatabase, $LunoConnectionsTable> {
  $$LunoConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyIdHint => $composableBuilder(column: $table.keyIdHint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get homeFiat => $composableBuilder(column: $table.homeFiat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get writePermWarning =>
      $composableBuilder(column: $table.writePermWarning, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unrecognisedRows =>
      $composableBuilder(column: $table.unrecognisedRows, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$PortfoliosTableFilterComposer get portfolioId {
    final $$PortfoliosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableFilterComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableFilterComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> lunoAccountCursorsRefs(Expression<bool> Function($$LunoAccountCursorsTableFilterComposer f) f) {
    final $$LunoAccountCursorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoAccountCursors,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoAccountCursorsTableFilterComposer(
            $db: $db,
            $table: $db.lunoAccountCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lunoLedgerRowsRefs(Expression<bool> Function($$LunoLedgerRowsTableFilterComposer f) f) {
    final $$LunoLedgerRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoLedgerRows,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoLedgerRowsTableFilterComposer(
        $db: $db,
        $table: $db.lunoLedgerRows,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$LunoConnectionsTableOrderingComposer extends Composer<_$AppDatabase, $LunoConnectionsTable> {
  $$LunoConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyIdHint => $composableBuilder(column: $table.keyIdHint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get homeFiat => $composableBuilder(column: $table.homeFiat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get writePermWarning =>
      $composableBuilder(column: $table.writePermWarning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unrecognisedRows =>
      $composableBuilder(column: $table.unrecognisedRows, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$PortfoliosTableOrderingComposer get portfolioId {
    final $$PortfoliosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableOrderingComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$LunoConnectionsTableAnnotationComposer extends Composer<_$AppDatabase, $LunoConnectionsTable> {
  $$LunoConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label => $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get keyIdHint => $composableBuilder(column: $table.keyIdHint, builder: (column) => column);

  GeneratedColumn<String> get homeFiat => $composableBuilder(column: $table.homeFiat, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(column: $table.lastSyncAt, builder: (column) => column);

  GeneratedColumn<String> get lastError => $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get writePermWarning => $composableBuilder(column: $table.writePermWarning, builder: (column) => column);

  GeneratedColumn<int> get unrecognisedRows => $composableBuilder(column: $table.unrecognisedRows, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PortfoliosTableAnnotationComposer get portfolioId {
    final $$PortfoliosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableAnnotationComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableAnnotationComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> lunoAccountCursorsRefs<T extends Object>(Expression<T> Function($$LunoAccountCursorsTableAnnotationComposer a) f) {
    final $$LunoAccountCursorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoAccountCursors,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoAccountCursorsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoAccountCursors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lunoLedgerRowsRefs<T extends Object>(Expression<T> Function($$LunoLedgerRowsTableAnnotationComposer a) f) {
    final $$LunoLedgerRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lunoLedgerRows,
      getReferencedColumn: (t) => t.connectionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoLedgerRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoLedgerRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LunoConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LunoConnectionsTable,
          LunoConnectionRow,
          $$LunoConnectionsTableFilterComposer,
          $$LunoConnectionsTableOrderingComposer,
          $$LunoConnectionsTableAnnotationComposer,
          $$LunoConnectionsTableCreateCompanionBuilder,
          $$LunoConnectionsTableUpdateCompanionBuilder,
          (LunoConnectionRow, $$LunoConnectionsTableReferences),
          LunoConnectionRow,
          PrefetchHooks Function({bool portfolioId, bool transactionsRefs, bool lunoAccountCursorsRefs, bool lunoLedgerRowsRefs})
        > {
  $$LunoConnectionsTableTableManager(_$AppDatabase db, $LunoConnectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LunoConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LunoConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LunoConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> portfolioId = const Value.absent(),
                Value<String> keyIdHint = const Value.absent(),
                Value<String> homeFiat = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> writePermWarning = const Value.absent(),
                Value<int> unrecognisedRows = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LunoConnectionsCompanion(
                id: id,
                label: label,
                portfolioId: portfolioId,
                keyIdHint: keyIdHint,
                homeFiat: homeFiat,
                status: status,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                writePermWarning: writePermWarning,
                unrecognisedRows: unrecognisedRows,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required int portfolioId,
                Value<String> keyIdHint = const Value.absent(),
                required String homeFiat,
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> writePermWarning = const Value.absent(),
                Value<int> unrecognisedRows = const Value.absent(),
                required DateTime createdAt,
              }) => LunoConnectionsCompanion.insert(
                id: id,
                label: label,
                portfolioId: portfolioId,
                keyIdHint: keyIdHint,
                homeFiat: homeFiat,
                status: status,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                writePermWarning: writePermWarning,
                unrecognisedRows: unrecognisedRows,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$LunoConnectionsTable, LunoConnectionRow>(table), $$LunoConnectionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({portfolioId = false, transactionsRefs = false, lunoAccountCursorsRefs = false, lunoLedgerRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (lunoAccountCursorsRefs) db.lunoAccountCursors,
                    if (lunoLedgerRowsRefs) db.lunoLedgerRows,
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
                        if (portfolioId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.portfolioId,
                            referencedTable: $$LunoConnectionsTableReferences._portfolioIdTable(db),
                            referencedColumn: $$LunoConnectionsTableReferences._portfolioIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<LunoConnectionRow, $LunoConnectionsTable, TransactionRow>(
                          currentTable: table,
                          referencedTable: $$LunoConnectionsTableReferences._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) => $$LunoConnectionsTableReferences(db, table, p0).transactionsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.connectionId == item.id),
                          typedResults: items,
                        ),
                      if (lunoAccountCursorsRefs)
                        await $_getPrefetchedData<LunoConnectionRow, $LunoConnectionsTable, LunoCursorRow>(
                          currentTable: table,
                          referencedTable: $$LunoConnectionsTableReferences._lunoAccountCursorsRefsTable(db),
                          managerFromTypedResult: (p0) => $$LunoConnectionsTableReferences(db, table, p0).lunoAccountCursorsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.connectionId == item.id),
                          typedResults: items,
                        ),
                      if (lunoLedgerRowsRefs)
                        await $_getPrefetchedData<LunoConnectionRow, $LunoConnectionsTable, LunoLedgerRow>(
                          currentTable: table,
                          referencedTable: $$LunoConnectionsTableReferences._lunoLedgerRowsRefsTable(db),
                          managerFromTypedResult: (p0) => $$LunoConnectionsTableReferences(db, table, p0).lunoLedgerRowsRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.connectionId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LunoConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LunoConnectionsTable,
      LunoConnectionRow,
      $$LunoConnectionsTableFilterComposer,
      $$LunoConnectionsTableOrderingComposer,
      $$LunoConnectionsTableAnnotationComposer,
      $$LunoConnectionsTableCreateCompanionBuilder,
      $$LunoConnectionsTableUpdateCompanionBuilder,
      (LunoConnectionRow, $$LunoConnectionsTableReferences),
      LunoConnectionRow,
      PrefetchHooks Function({bool portfolioId, bool transactionsRefs, bool lunoAccountCursorsRefs, bool lunoLedgerRowsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  required int portfolioId,
  Value<String?> symbol,
  required String type,
  required DateTime tradeDate,
  required Decimal quantity,
  required Decimal price,
  Value<Decimal> fees,
  Value<String> currency,
  Value<Decimal> fxRateToBase,
  Value<String?> notes,
  Value<String?> importBatchId,
  required DateTime createdAt,
  Value<String> source,
  Value<int?> connectionId,
  Value<String?> externalId,
  Value<int?> executedAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  Value<int> portfolioId,
  Value<String?> symbol,
  Value<String> type,
  Value<DateTime> tradeDate,
  Value<Decimal> quantity,
  Value<Decimal> price,
  Value<Decimal> fees,
  Value<String> currency,
  Value<Decimal> fxRateToBase,
  Value<String?> notes,
  Value<String?> importBatchId,
  Value<DateTime> createdAt,
  Value<String> source,
  Value<int?> connectionId,
  Value<String?> externalId,
  Value<int?> executedAt,
});

final class $$TransactionsTableReferences extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PortfoliosTable _portfolioIdTable(_$AppDatabase db) => db.portfolios.createAlias('transactions__portfolio_id__portfolios__id');

  $$PortfoliosTableProcessedTableManager get portfolioId {
    final $_column = $_itemColumn<int>('portfolio_id')!;

    final manager = $$PortfoliosTableTableManager($_db, $_db.portfolios).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_portfolioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $LunoConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.lunoConnections.createAlias('transactions__connection_id__luno_connections__id');

  $$LunoConnectionsTableProcessedTableManager? get connectionId {
    final $_column = $_itemColumn<int>('connection_id');
    if ($_column == null) return null;
    final manager = $$LunoConnectionsTableTableManager($_db, $_db.lunoConnections).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get fees =>
      $composableBuilder(column: $table.fees, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get fxRateToBase =>
      $composableBuilder(column: $table.fxRateToBase, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importBatchId => $composableBuilder(column: $table.importBatchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalId => $composableBuilder(column: $table.externalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get executedAt => $composableBuilder(column: $table.executedAt, builder: (column) => ColumnFilters(column));

  $$PortfoliosTableFilterComposer get portfolioId {
    final $$PortfoliosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableFilterComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$LunoConnectionsTableFilterComposer get connectionId {
    final $$LunoConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableFilterComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tradeDate => $composableBuilder(column: $table.tradeDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantity => $composableBuilder(column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get price => $composableBuilder(column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fees => $composableBuilder(column: $table.fees, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fxRateToBase => $composableBuilder(column: $table.fxRateToBase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importBatchId =>
      $composableBuilder(column: $table.importBatchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalId => $composableBuilder(column: $table.externalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get executedAt => $composableBuilder(column: $table.executedAt, builder: (column) => ColumnOrderings(column));

  $$PortfoliosTableOrderingComposer get portfolioId {
    final $$PortfoliosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableOrderingComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$LunoConnectionsTableOrderingComposer get connectionId {
    final $$LunoConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableOrderingComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get price => $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get fees => $composableBuilder(column: $table.fees, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get fxRateToBase =>
      $composableBuilder(column: $table.fxRateToBase, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get importBatchId => $composableBuilder(column: $table.importBatchId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(column: $table.externalId, builder: (column) => column);

  GeneratedColumn<int> get executedAt => $composableBuilder(column: $table.executedAt, builder: (column) => column);

  $$PortfoliosTableAnnotationComposer get portfolioId {
    final $$PortfoliosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.portfolioId,
      referencedTable: $db.portfolios,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$PortfoliosTableAnnotationComposer(
        $db: $db,
        $table: $db.portfolios,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$LunoConnectionsTableAnnotationComposer get connectionId {
    final $$LunoConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool portfolioId, bool connectionId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> portfolioId = const Value.absent(),
                Value<String?> symbol = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> tradeDate = const Value.absent(),
                Value<Decimal> quantity = const Value.absent(),
                Value<Decimal> price = const Value.absent(),
                Value<Decimal> fees = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<Decimal> fxRateToBase = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> connectionId = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> executedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                portfolioId: portfolioId,
                symbol: symbol,
                type: type,
                tradeDate: tradeDate,
                quantity: quantity,
                price: price,
                fees: fees,
                currency: currency,
                fxRateToBase: fxRateToBase,
                notes: notes,
                importBatchId: importBatchId,
                createdAt: createdAt,
                source: source,
                connectionId: connectionId,
                externalId: externalId,
                executedAt: executedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int portfolioId,
                Value<String?> symbol = const Value.absent(),
                required String type,
                required DateTime tradeDate,
                required Decimal quantity,
                required Decimal price,
                Value<Decimal> fees = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<Decimal> fxRateToBase = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> importBatchId = const Value.absent(),
                required DateTime createdAt,
                Value<String> source = const Value.absent(),
                Value<int?> connectionId = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> executedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                portfolioId: portfolioId,
                symbol: symbol,
                type: type,
                tradeDate: tradeDate,
                quantity: quantity,
                price: price,
                fees: fees,
                currency: currency,
                fxRateToBase: fxRateToBase,
                notes: notes,
                importBatchId: importBatchId,
                createdAt: createdAt,
                source: source,
                connectionId: connectionId,
                externalId: externalId,
                executedAt: executedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$TransactionsTable, TransactionRow>(table), $$TransactionsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({portfolioId = false, connectionId = false}) {
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
                    if (portfolioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.portfolioId,
                        referencedTable: $$TransactionsTableReferences._portfolioIdTable(db),
                        referencedColumn: $$TransactionsTableReferences._portfolioIdTable(db).id,
                      ) as T;
                    }
                    if (connectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.connectionId,
                        referencedTable: $$TransactionsTableReferences._connectionIdTable(db),
                        referencedColumn: $$TransactionsTableReferences._connectionIdTable(db).id,
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

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool portfolioId, bool connectionId})
    >;
typedef $$WatchlistsTableCreateCompanionBuilder = WatchlistsCompanion Function({Value<int> id, required String name, Value<int> sortOrder});
typedef $$WatchlistsTableUpdateCompanionBuilder = WatchlistsCompanion Function({Value<int> id, Value<String> name, Value<int> sortOrder});

final class $$WatchlistsTableReferences extends BaseReferences<_$AppDatabase, $WatchlistsTable, WatchlistRow> {
  $$WatchlistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WatchlistItemsTable, List<WatchlistItemRow>> _watchlistItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.watchlistItems, aliasName: 'watchlists__id__watchlist_items__watchlist_id');

  $$WatchlistItemsTableProcessedTableManager get watchlistItemsRefs {
    final manager = $$WatchlistItemsTableTableManager(
      $_db,
      $_db.watchlistItems,
    ).filter((f) => f.watchlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_watchlistItemsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WatchlistsTableFilterComposer extends Composer<_$AppDatabase, $WatchlistsTable> {
  $$WatchlistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> watchlistItemsRefs(Expression<bool> Function($$WatchlistItemsTableFilterComposer f) f) {
    final $$WatchlistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchlistItems,
      getReferencedColumn: (t) => t.watchlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WatchlistItemsTableFilterComposer(
        $db: $db,
        $table: $db.watchlistItems,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$WatchlistsTableOrderingComposer extends Composer<_$AppDatabase, $WatchlistsTable> {
  $$WatchlistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$WatchlistsTableAnnotationComposer extends Composer<_$AppDatabase, $WatchlistsTable> {
  $$WatchlistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> watchlistItemsRefs<T extends Object>(Expression<T> Function($$WatchlistItemsTableAnnotationComposer a) f) {
    final $$WatchlistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchlistItems,
      getReferencedColumn: (t) => t.watchlistId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WatchlistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.watchlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WatchlistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchlistsTable,
          WatchlistRow,
          $$WatchlistsTableFilterComposer,
          $$WatchlistsTableOrderingComposer,
          $$WatchlistsTableAnnotationComposer,
          $$WatchlistsTableCreateCompanionBuilder,
          $$WatchlistsTableUpdateCompanionBuilder,
          (WatchlistRow, $$WatchlistsTableReferences),
          WatchlistRow,
          PrefetchHooks Function({bool watchlistItemsRefs})
        > {
  $$WatchlistsTableTableManager(_$AppDatabase db, $WatchlistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WatchlistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WatchlistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WatchlistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) => WatchlistsCompanion(id: id, name: name, sortOrder: sortOrder),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> sortOrder = const Value.absent(),
          }) => WatchlistsCompanion.insert(id: id, name: name, sortOrder: sortOrder),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$WatchlistsTable, WatchlistRow>(table), $$WatchlistsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({watchlistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (watchlistItemsRefs) db.watchlistItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (watchlistItemsRefs)
                    await $_getPrefetchedData<WatchlistRow, $WatchlistsTable, WatchlistItemRow>(
                      currentTable: table,
                      referencedTable: $$WatchlistsTableReferences._watchlistItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WatchlistsTableReferences(db, table, p0).watchlistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) => referencedItems.where((e) => e.watchlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WatchlistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchlistsTable,
      WatchlistRow,
      $$WatchlistsTableFilterComposer,
      $$WatchlistsTableOrderingComposer,
      $$WatchlistsTableAnnotationComposer,
      $$WatchlistsTableCreateCompanionBuilder,
      $$WatchlistsTableUpdateCompanionBuilder,
      (WatchlistRow, $$WatchlistsTableReferences),
      WatchlistRow,
      PrefetchHooks Function({bool watchlistItemsRefs})
    >;
typedef $$WatchlistItemsTableCreateCompanionBuilder = WatchlistItemsCompanion Function({
  required int watchlistId,
  required String symbol,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$WatchlistItemsTableUpdateCompanionBuilder = WatchlistItemsCompanion Function({
  Value<int> watchlistId,
  Value<String> symbol,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$WatchlistItemsTableReferences extends BaseReferences<_$AppDatabase, $WatchlistItemsTable, WatchlistItemRow> {
  $$WatchlistItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WatchlistsTable _watchlistIdTable(_$AppDatabase db) => db.watchlists.createAlias('watchlist_items__watchlist_id__watchlists__id');

  $$WatchlistsTableProcessedTableManager get watchlistId {
    final $_column = $_itemColumn<int>('watchlist_id')!;

    final manager = $$WatchlistsTableTableManager($_db, $_db.watchlists).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_watchlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WatchlistItemsTableFilterComposer extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$WatchlistsTableFilterComposer get watchlistId {
    final $$WatchlistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.watchlistId,
      referencedTable: $db.watchlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WatchlistsTableFilterComposer(
        $db: $db,
        $table: $db.watchlists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$WatchlistItemsTableOrderingComposer extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$WatchlistsTableOrderingComposer get watchlistId {
    final $$WatchlistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.watchlistId,
      referencedTable: $db.watchlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WatchlistsTableOrderingComposer(
        $db: $db,
        $table: $db.watchlists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$WatchlistItemsTableAnnotationComposer extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$WatchlistsTableAnnotationComposer get watchlistId {
    final $$WatchlistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.watchlistId,
      referencedTable: $db.watchlists,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WatchlistsTableAnnotationComposer(
        $db: $db,
        $table: $db.watchlists,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$WatchlistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchlistItemsTable,
          WatchlistItemRow,
          $$WatchlistItemsTableFilterComposer,
          $$WatchlistItemsTableOrderingComposer,
          $$WatchlistItemsTableAnnotationComposer,
          $$WatchlistItemsTableCreateCompanionBuilder,
          $$WatchlistItemsTableUpdateCompanionBuilder,
          (WatchlistItemRow, $$WatchlistItemsTableReferences),
          WatchlistItemRow,
          PrefetchHooks Function({bool watchlistId})
        > {
  $$WatchlistItemsTableTableManager(_$AppDatabase db, $WatchlistItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WatchlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WatchlistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WatchlistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> watchlistId = const Value.absent(),
            Value<String> symbol = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => WatchlistItemsCompanion(watchlistId: watchlistId, symbol: symbol, sortOrder: sortOrder, rowid: rowid),
          createCompanionCallback: ({
            required int watchlistId,
            required String symbol,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => WatchlistItemsCompanion.insert(watchlistId: watchlistId, symbol: symbol, sortOrder: sortOrder, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$WatchlistItemsTable, WatchlistItemRow>(table), $$WatchlistItemsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({watchlistId = false}) {
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
                    if (watchlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.watchlistId,
                        referencedTable: $$WatchlistItemsTableReferences._watchlistIdTable(db),
                        referencedColumn: $$WatchlistItemsTableReferences._watchlistIdTable(db).id,
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

typedef $$WatchlistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchlistItemsTable,
      WatchlistItemRow,
      $$WatchlistItemsTableFilterComposer,
      $$WatchlistItemsTableOrderingComposer,
      $$WatchlistItemsTableAnnotationComposer,
      $$WatchlistItemsTableCreateCompanionBuilder,
      $$WatchlistItemsTableUpdateCompanionBuilder,
      (WatchlistItemRow, $$WatchlistItemsTableReferences),
      WatchlistItemRow,
      PrefetchHooks Function({bool watchlistId})
    >;
typedef $$QuoteCacheTableCreateCompanionBuilder = QuoteCacheCompanion Function({
  required String symbol,
  required String payloadJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$QuoteCacheTableUpdateCompanionBuilder = QuoteCacheCompanion Function({
  Value<String> symbol,
  Value<String> payloadJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$QuoteCacheTableFilterComposer extends Composer<_$AppDatabase, $QuoteCacheTable> {
  $$QuoteCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$QuoteCacheTableOrderingComposer extends Composer<_$AppDatabase, $QuoteCacheTable> {
  $$QuoteCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$QuoteCacheTableAnnotationComposer extends Composer<_$AppDatabase, $QuoteCacheTable> {
  $$QuoteCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$QuoteCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuoteCacheTable,
          QuoteCacheRow,
          $$QuoteCacheTableFilterComposer,
          $$QuoteCacheTableOrderingComposer,
          $$QuoteCacheTableAnnotationComposer,
          $$QuoteCacheTableCreateCompanionBuilder,
          $$QuoteCacheTableUpdateCompanionBuilder,
          (QuoteCacheRow, BaseReferences<_$AppDatabase, $QuoteCacheTable, QuoteCacheRow>),
          QuoteCacheRow,
          PrefetchHooks Function()
        > {
  $$QuoteCacheTableTableManager(_$AppDatabase db, $QuoteCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$QuoteCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$QuoteCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$QuoteCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => QuoteCacheCompanion(symbol: symbol, payloadJson: payloadJson, fetchedAt: fetchedAt, rowid: rowid),
          createCompanionCallback: ({
            required String symbol,
            required String payloadJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) => QuoteCacheCompanion.insert(symbol: symbol, payloadJson: payloadJson, fetchedAt: fetchedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuoteCacheTable, QuoteCacheRow>(table),
                  BaseReferences<_$AppDatabase, $QuoteCacheTable, QuoteCacheRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuoteCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuoteCacheTable,
      QuoteCacheRow,
      $$QuoteCacheTableFilterComposer,
      $$QuoteCacheTableOrderingComposer,
      $$QuoteCacheTableAnnotationComposer,
      $$QuoteCacheTableCreateCompanionBuilder,
      $$QuoteCacheTableUpdateCompanionBuilder,
      (QuoteCacheRow, BaseReferences<_$AppDatabase, $QuoteCacheTable, QuoteCacheRow>),
      QuoteCacheRow,
      PrefetchHooks Function()
    >;
typedef $$ProfileCacheTableCreateCompanionBuilder = ProfileCacheCompanion Function({
  required String symbol,
  required String payloadJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$ProfileCacheTableUpdateCompanionBuilder = ProfileCacheCompanion Function({
  Value<String> symbol,
  Value<String> payloadJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$ProfileCacheTableFilterComposer extends Composer<_$AppDatabase, $ProfileCacheTable> {
  $$ProfileCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$ProfileCacheTableOrderingComposer extends Composer<_$AppDatabase, $ProfileCacheTable> {
  $$ProfileCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProfileCacheTableAnnotationComposer extends Composer<_$AppDatabase, $ProfileCacheTable> {
  $$ProfileCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ProfileCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileCacheTable,
          ProfileCacheRow,
          $$ProfileCacheTableFilterComposer,
          $$ProfileCacheTableOrderingComposer,
          $$ProfileCacheTableAnnotationComposer,
          $$ProfileCacheTableCreateCompanionBuilder,
          $$ProfileCacheTableUpdateCompanionBuilder,
          (ProfileCacheRow, BaseReferences<_$AppDatabase, $ProfileCacheTable, ProfileCacheRow>),
          ProfileCacheRow,
          PrefetchHooks Function()
        > {
  $$ProfileCacheTableTableManager(_$AppDatabase db, $ProfileCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfileCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfileCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfileCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfileCacheCompanion(symbol: symbol, payloadJson: payloadJson, fetchedAt: fetchedAt, rowid: rowid),
          createCompanionCallback: ({
            required String symbol,
            required String payloadJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) => ProfileCacheCompanion.insert(symbol: symbol, payloadJson: payloadJson, fetchedAt: fetchedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileCacheTable, ProfileCacheRow>(table),
                  BaseReferences<_$AppDatabase, $ProfileCacheTable, ProfileCacheRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileCacheTable,
      ProfileCacheRow,
      $$ProfileCacheTableFilterComposer,
      $$ProfileCacheTableOrderingComposer,
      $$ProfileCacheTableAnnotationComposer,
      $$ProfileCacheTableCreateCompanionBuilder,
      $$ProfileCacheTableUpdateCompanionBuilder,
      (ProfileCacheRow, BaseReferences<_$AppDatabase, $ProfileCacheTable, ProfileCacheRow>),
      ProfileCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PriceHistoryCacheTableCreateCompanionBuilder = PriceHistoryCacheCompanion Function({
  required String symbol,
  required String interval,
  required int ts,
  required double open,
  required double high,
  required double low,
  required double close,
  Value<double?> adjClose,
  Value<double> volume,
  Value<int> rowid,
});
typedef $$PriceHistoryCacheTableUpdateCompanionBuilder = PriceHistoryCacheCompanion Function({
  Value<String> symbol,
  Value<String> interval,
  Value<int> ts,
  Value<double> open,
  Value<double> high,
  Value<double> low,
  Value<double> close,
  Value<double?> adjClose,
  Value<double> volume,
  Value<int> rowid,
});

class $$PriceHistoryCacheTableFilterComposer extends Composer<_$AppDatabase, $PriceHistoryCacheTable> {
  $$PriceHistoryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ts => $composableBuilder(column: $table.ts, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get open => $composableBuilder(column: $table.open, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get high => $composableBuilder(column: $table.high, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get low => $composableBuilder(column: $table.low, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get close => $composableBuilder(column: $table.close, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get adjClose => $composableBuilder(column: $table.adjClose, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(column: $table.volume, builder: (column) => ColumnFilters(column));
}

class $$PriceHistoryCacheTableOrderingComposer extends Composer<_$AppDatabase, $PriceHistoryCacheTable> {
  $$PriceHistoryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ts => $composableBuilder(column: $table.ts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get open => $composableBuilder(column: $table.open, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get high => $composableBuilder(column: $table.high, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get low => $composableBuilder(column: $table.low, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get close => $composableBuilder(column: $table.close, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get adjClose => $composableBuilder(column: $table.adjClose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(column: $table.volume, builder: (column) => ColumnOrderings(column));
}

class $$PriceHistoryCacheTableAnnotationComposer extends Composer<_$AppDatabase, $PriceHistoryCacheTable> {
  $$PriceHistoryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get ts => $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get open => $composableBuilder(column: $table.open, builder: (column) => column);

  GeneratedColumn<double> get high => $composableBuilder(column: $table.high, builder: (column) => column);

  GeneratedColumn<double> get low => $composableBuilder(column: $table.low, builder: (column) => column);

  GeneratedColumn<double> get close => $composableBuilder(column: $table.close, builder: (column) => column);

  GeneratedColumn<double> get adjClose => $composableBuilder(column: $table.adjClose, builder: (column) => column);

  GeneratedColumn<double> get volume => $composableBuilder(column: $table.volume, builder: (column) => column);
}

class $$PriceHistoryCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceHistoryCacheTable,
          PriceRow,
          $$PriceHistoryCacheTableFilterComposer,
          $$PriceHistoryCacheTableOrderingComposer,
          $$PriceHistoryCacheTableAnnotationComposer,
          $$PriceHistoryCacheTableCreateCompanionBuilder,
          $$PriceHistoryCacheTableUpdateCompanionBuilder,
          (PriceRow, BaseReferences<_$AppDatabase, $PriceHistoryCacheTable, PriceRow>),
          PriceRow,
          PrefetchHooks Function()
        > {
  $$PriceHistoryCacheTableTableManager(_$AppDatabase db, $PriceHistoryCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PriceHistoryCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PriceHistoryCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PriceHistoryCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> interval = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<double> open = const Value.absent(),
                Value<double> high = const Value.absent(),
                Value<double> low = const Value.absent(),
                Value<double> close = const Value.absent(),
                Value<double?> adjClose = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryCacheCompanion(
                symbol: symbol,
                interval: interval,
                ts: ts,
                open: open,
                high: high,
                low: low,
                close: close,
                adjClose: adjClose,
                volume: volume,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String interval,
                required int ts,
                required double open,
                required double high,
                required double low,
                required double close,
                Value<double?> adjClose = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryCacheCompanion.insert(
                symbol: symbol,
                interval: interval,
                ts: ts,
                open: open,
                high: high,
                low: low,
                close: close,
                adjClose: adjClose,
                volume: volume,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceHistoryCacheTable, PriceRow>(table),
                  BaseReferences<_$AppDatabase, $PriceHistoryCacheTable, PriceRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceHistoryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceHistoryCacheTable,
      PriceRow,
      $$PriceHistoryCacheTableFilterComposer,
      $$PriceHistoryCacheTableOrderingComposer,
      $$PriceHistoryCacheTableAnnotationComposer,
      $$PriceHistoryCacheTableCreateCompanionBuilder,
      $$PriceHistoryCacheTableUpdateCompanionBuilder,
      (PriceRow, BaseReferences<_$AppDatabase, $PriceHistoryCacheTable, PriceRow>),
      PriceRow,
      PrefetchHooks Function()
    >;
typedef $$HistoryMetaTableCreateCompanionBuilder = HistoryMetaCompanion Function({
  required String symbol,
  required String interval,
  required int oldestTs,
  required int newestTs,
  Value<String?> currency,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$HistoryMetaTableUpdateCompanionBuilder = HistoryMetaCompanion Function({
  Value<String> symbol,
  Value<String> interval,
  Value<int> oldestTs,
  Value<int> newestTs,
  Value<String?> currency,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$HistoryMetaTableFilterComposer extends Composer<_$AppDatabase, $HistoryMetaTable> {
  $$HistoryMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get oldestTs => $composableBuilder(column: $table.oldestTs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newestTs => $composableBuilder(column: $table.newestTs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$HistoryMetaTableOrderingComposer extends Composer<_$AppDatabase, $HistoryMetaTable> {
  $$HistoryMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get oldestTs => $composableBuilder(column: $table.oldestTs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newestTs => $composableBuilder(column: $table.newestTs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$HistoryMetaTableAnnotationComposer extends Composer<_$AppDatabase, $HistoryMetaTable> {
  $$HistoryMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get interval => $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get oldestTs => $composableBuilder(column: $table.oldestTs, builder: (column) => column);

  GeneratedColumn<int> get newestTs => $composableBuilder(column: $table.newestTs, builder: (column) => column);

  GeneratedColumn<String> get currency => $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$HistoryMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryMetaTable,
          HistoryMetaRow,
          $$HistoryMetaTableFilterComposer,
          $$HistoryMetaTableOrderingComposer,
          $$HistoryMetaTableAnnotationComposer,
          $$HistoryMetaTableCreateCompanionBuilder,
          $$HistoryMetaTableUpdateCompanionBuilder,
          (HistoryMetaRow, BaseReferences<_$AppDatabase, $HistoryMetaTable, HistoryMetaRow>),
          HistoryMetaRow,
          PrefetchHooks Function()
        > {
  $$HistoryMetaTableTableManager(_$AppDatabase db, $HistoryMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HistoryMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HistoryMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HistoryMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> interval = const Value.absent(),
                Value<int> oldestTs = const Value.absent(),
                Value<int> newestTs = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryMetaCompanion(
                symbol: symbol,
                interval: interval,
                oldestTs: oldestTs,
                newestTs: newestTs,
                currency: currency,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String interval,
                required int oldestTs,
                required int newestTs,
                Value<String?> currency = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => HistoryMetaCompanion.insert(
                symbol: symbol,
                interval: interval,
                oldestTs: oldestTs,
                newestTs: newestTs,
                currency: currency,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryMetaTable, HistoryMetaRow>(table),
                  BaseReferences<_$AppDatabase, $HistoryMetaTable, HistoryMetaRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryMetaTable,
      HistoryMetaRow,
      $$HistoryMetaTableFilterComposer,
      $$HistoryMetaTableOrderingComposer,
      $$HistoryMetaTableAnnotationComposer,
      $$HistoryMetaTableCreateCompanionBuilder,
      $$HistoryMetaTableUpdateCompanionBuilder,
      (HistoryMetaRow, BaseReferences<_$AppDatabase, $HistoryMetaTable, HistoryMetaRow>),
      HistoryMetaRow,
      PrefetchHooks Function()
    >;
typedef $$DividendEventsCacheTableCreateCompanionBuilder = DividendEventsCacheCompanion Function({
  required String symbol,
  required DateTime exDate,
  required double amount,
  Value<DateTime?> payDate,
  Value<int> rowid,
});
typedef $$DividendEventsCacheTableUpdateCompanionBuilder = DividendEventsCacheCompanion Function({
  Value<String> symbol,
  Value<DateTime> exDate,
  Value<double> amount,
  Value<DateTime?> payDate,
  Value<int> rowid,
});

class $$DividendEventsCacheTableFilterComposer extends Composer<_$AppDatabase, $DividendEventsCacheTable> {
  $$DividendEventsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get exDate =>
      $composableBuilder(column: $table.exDate, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get payDate =>
      $composableBuilder(column: $table.payDate, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$DividendEventsCacheTableOrderingComposer extends Composer<_$AppDatabase, $DividendEventsCacheTable> {
  $$DividendEventsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exDate => $composableBuilder(column: $table.exDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payDate => $composableBuilder(column: $table.payDate, builder: (column) => ColumnOrderings(column));
}

class $$DividendEventsCacheTableAnnotationComposer extends Composer<_$AppDatabase, $DividendEventsCacheTable> {
  $$DividendEventsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get exDate => $composableBuilder(column: $table.exDate, builder: (column) => column);

  GeneratedColumn<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get payDate =>
      $composableBuilder(column: $table.payDate, builder: (column) => column);
}

class $$DividendEventsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DividendEventsCacheTable,
          DividendRow,
          $$DividendEventsCacheTableFilterComposer,
          $$DividendEventsCacheTableOrderingComposer,
          $$DividendEventsCacheTableAnnotationComposer,
          $$DividendEventsCacheTableCreateCompanionBuilder,
          $$DividendEventsCacheTableUpdateCompanionBuilder,
          (DividendRow, BaseReferences<_$AppDatabase, $DividendEventsCacheTable, DividendRow>),
          DividendRow,
          PrefetchHooks Function()
        > {
  $$DividendEventsCacheTableTableManager(_$AppDatabase db, $DividendEventsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$DividendEventsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$DividendEventsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$DividendEventsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<DateTime> exDate = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime?> payDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => DividendEventsCacheCompanion(symbol: symbol, exDate: exDate, amount: amount, payDate: payDate, rowid: rowid),
          createCompanionCallback: ({
            required String symbol,
            required DateTime exDate,
            required double amount,
            Value<DateTime?> payDate = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => DividendEventsCacheCompanion.insert(symbol: symbol, exDate: exDate, amount: amount, payDate: payDate, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DividendEventsCacheTable, DividendRow>(table),
                  BaseReferences<_$AppDatabase, $DividendEventsCacheTable, DividendRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DividendEventsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DividendEventsCacheTable,
      DividendRow,
      $$DividendEventsCacheTableFilterComposer,
      $$DividendEventsCacheTableOrderingComposer,
      $$DividendEventsCacheTableAnnotationComposer,
      $$DividendEventsCacheTableCreateCompanionBuilder,
      $$DividendEventsCacheTableUpdateCompanionBuilder,
      (DividendRow, BaseReferences<_$AppDatabase, $DividendEventsCacheTable, DividendRow>),
      DividendRow,
      PrefetchHooks Function()
    >;
typedef $$SplitEventsCacheTableCreateCompanionBuilder = SplitEventsCacheCompanion Function({
  required String symbol,
  required DateTime date,
  required int numerator,
  required int denominator,
  Value<int> rowid,
});
typedef $$SplitEventsCacheTableUpdateCompanionBuilder = SplitEventsCacheCompanion Function({
  Value<String> symbol,
  Value<DateTime> date,
  Value<int> numerator,
  Value<int> denominator,
  Value<int> rowid,
});

class $$SplitEventsCacheTableFilterComposer extends Composer<_$AppDatabase, $SplitEventsCacheTable> {
  $$SplitEventsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get numerator => $composableBuilder(column: $table.numerator, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get denominator => $composableBuilder(column: $table.denominator, builder: (column) => ColumnFilters(column));
}

class $$SplitEventsCacheTableOrderingComposer extends Composer<_$AppDatabase, $SplitEventsCacheTable> {
  $$SplitEventsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numerator => $composableBuilder(column: $table.numerator, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get denominator => $composableBuilder(column: $table.denominator, builder: (column) => ColumnOrderings(column));
}

class $$SplitEventsCacheTableAnnotationComposer extends Composer<_$AppDatabase, $SplitEventsCacheTable> {
  $$SplitEventsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol => $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get numerator => $composableBuilder(column: $table.numerator, builder: (column) => column);

  GeneratedColumn<int> get denominator => $composableBuilder(column: $table.denominator, builder: (column) => column);
}

class $$SplitEventsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitEventsCacheTable,
          SplitRow,
          $$SplitEventsCacheTableFilterComposer,
          $$SplitEventsCacheTableOrderingComposer,
          $$SplitEventsCacheTableAnnotationComposer,
          $$SplitEventsCacheTableCreateCompanionBuilder,
          $$SplitEventsCacheTableUpdateCompanionBuilder,
          (SplitRow, BaseReferences<_$AppDatabase, $SplitEventsCacheTable, SplitRow>),
          SplitRow,
          PrefetchHooks Function()
        > {
  $$SplitEventsCacheTableTableManager(_$AppDatabase db, $SplitEventsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SplitEventsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SplitEventsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SplitEventsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> numerator = const Value.absent(),
            Value<int> denominator = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SplitEventsCacheCompanion(symbol: symbol, date: date, numerator: numerator, denominator: denominator, rowid: rowid),
          createCompanionCallback: ({
            required String symbol,
            required DateTime date,
            required int numerator,
            required int denominator,
            Value<int> rowid = const Value.absent(),
          }) => SplitEventsCacheCompanion.insert(symbol: symbol, date: date, numerator: numerator, denominator: denominator, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SplitEventsCacheTable, SplitRow>(table),
                  BaseReferences<_$AppDatabase, $SplitEventsCacheTable, SplitRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitEventsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitEventsCacheTable,
      SplitRow,
      $$SplitEventsCacheTableFilterComposer,
      $$SplitEventsCacheTableOrderingComposer,
      $$SplitEventsCacheTableAnnotationComposer,
      $$SplitEventsCacheTableCreateCompanionBuilder,
      $$SplitEventsCacheTableUpdateCompanionBuilder,
      (SplitRow, BaseReferences<_$AppDatabase, $SplitEventsCacheTable, SplitRow>),
      SplitRow,
      PrefetchHooks Function()
    >;
typedef $$ImportMappingsTableCreateCompanionBuilder = ImportMappingsCompanion Function({
  Value<int> id,
  required String name,
  required String mappingJson,
});
typedef $$ImportMappingsTableUpdateCompanionBuilder = ImportMappingsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> mappingJson,
});

class $$ImportMappingsTableFilterComposer extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mappingJson => $composableBuilder(column: $table.mappingJson, builder: (column) => ColumnFilters(column));
}

class $$ImportMappingsTableOrderingComposer extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mappingJson => $composableBuilder(column: $table.mappingJson, builder: (column) => ColumnOrderings(column));
}

class $$ImportMappingsTableAnnotationComposer extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get mappingJson => $composableBuilder(column: $table.mappingJson, builder: (column) => column);
}

class $$ImportMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportMappingsTable,
          ImportMappingRow,
          $$ImportMappingsTableFilterComposer,
          $$ImportMappingsTableOrderingComposer,
          $$ImportMappingsTableAnnotationComposer,
          $$ImportMappingsTableCreateCompanionBuilder,
          $$ImportMappingsTableUpdateCompanionBuilder,
          (ImportMappingRow, BaseReferences<_$AppDatabase, $ImportMappingsTable, ImportMappingRow>),
          ImportMappingRow,
          PrefetchHooks Function()
        > {
  $$ImportMappingsTableTableManager(_$AppDatabase db, $ImportMappingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ImportMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ImportMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ImportMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> mappingJson = const Value.absent(),
          }) => ImportMappingsCompanion(id: id, name: name, mappingJson: mappingJson),
          createCompanionCallback: ({Value<int> id = const Value.absent(), required String name, required String mappingJson}) =>
              ImportMappingsCompanion.insert(id: id, name: name, mappingJson: mappingJson),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportMappingsTable, ImportMappingRow>(table),
                  BaseReferences<_$AppDatabase, $ImportMappingsTable, ImportMappingRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportMappingsTable,
      ImportMappingRow,
      $$ImportMappingsTableFilterComposer,
      $$ImportMappingsTableOrderingComposer,
      $$ImportMappingsTableAnnotationComposer,
      $$ImportMappingsTableCreateCompanionBuilder,
      $$ImportMappingsTableUpdateCompanionBuilder,
      (ImportMappingRow, BaseReferences<_$AppDatabase, $ImportMappingsTable, ImportMappingRow>),
      ImportMappingRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({required String key, required String value, Value<int> rowid});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({Value<String> key, Value<String> value, Value<int> rowid});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({required String key, required String value, Value<int> rowid = const Value.absent()}) =>
              SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$LunoAccountCursorsTableCreateCompanionBuilder = LunoAccountCursorsCompanion Function({
  required int connectionId,
  required String accountId,
  required String asset,
  Value<String> accountType,
  Value<int> lastRowIndex,
  Value<Decimal> balanceSnapshot,
  Value<Decimal> reservedSnapshot,
  Value<Decimal> unconfirmedSnapshot,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$LunoAccountCursorsTableUpdateCompanionBuilder = LunoAccountCursorsCompanion Function({
  Value<int> connectionId,
  Value<String> accountId,
  Value<String> asset,
  Value<String> accountType,
  Value<int> lastRowIndex,
  Value<Decimal> balanceSnapshot,
  Value<Decimal> reservedSnapshot,
  Value<Decimal> unconfirmedSnapshot,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$LunoAccountCursorsTableReferences extends BaseReferences<_$AppDatabase, $LunoAccountCursorsTable, LunoCursorRow> {
  $$LunoAccountCursorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LunoConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.lunoConnections.createAlias('luno_account_cursors__connection_id__luno_connections__id');

  $$LunoConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$LunoConnectionsTableTableManager($_db, $_db.lunoConnections).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LunoAccountCursorsTableFilterComposer extends Composer<_$AppDatabase, $LunoAccountCursorsTable> {
  $$LunoAccountCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get asset => $composableBuilder(column: $table.asset, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastRowIndex => $composableBuilder(column: $table.lastRowIndex, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get balanceSnapshot =>
      $composableBuilder(column: $table.balanceSnapshot, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get reservedSnapshot =>
      $composableBuilder(column: $table.reservedSnapshot, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Decimal, Decimal, String> get unconfirmedSnapshot =>
      $composableBuilder(column: $table.unconfirmedSnapshot, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$LunoConnectionsTableFilterComposer get connectionId {
    final $$LunoConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableFilterComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$LunoAccountCursorsTableOrderingComposer extends Composer<_$AppDatabase, $LunoAccountCursorsTable> {
  $$LunoAccountCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get asset => $composableBuilder(column: $table.asset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastRowIndex => $composableBuilder(column: $table.lastRowIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get balanceSnapshot =>
      $composableBuilder(column: $table.balanceSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservedSnapshot =>
      $composableBuilder(column: $table.reservedSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unconfirmedSnapshot =>
      $composableBuilder(column: $table.unconfirmedSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$LunoConnectionsTableOrderingComposer get connectionId {
    final $$LunoConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableOrderingComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$LunoAccountCursorsTableAnnotationComposer extends Composer<_$AppDatabase, $LunoAccountCursorsTable> {
  $$LunoAccountCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get asset => $composableBuilder(column: $table.asset, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(column: $table.accountType, builder: (column) => column);

  GeneratedColumn<int> get lastRowIndex => $composableBuilder(column: $table.lastRowIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get balanceSnapshot =>
      $composableBuilder(column: $table.balanceSnapshot, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get reservedSnapshot =>
      $composableBuilder(column: $table.reservedSnapshot, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Decimal, String> get unconfirmedSnapshot =>
      $composableBuilder(column: $table.unconfirmedSnapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt => $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$LunoConnectionsTableAnnotationComposer get connectionId {
    final $$LunoConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LunoAccountCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LunoAccountCursorsTable,
          LunoCursorRow,
          $$LunoAccountCursorsTableFilterComposer,
          $$LunoAccountCursorsTableOrderingComposer,
          $$LunoAccountCursorsTableAnnotationComposer,
          $$LunoAccountCursorsTableCreateCompanionBuilder,
          $$LunoAccountCursorsTableUpdateCompanionBuilder,
          (LunoCursorRow, $$LunoAccountCursorsTableReferences),
          LunoCursorRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$LunoAccountCursorsTableTableManager(_$AppDatabase db, $LunoAccountCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LunoAccountCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LunoAccountCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LunoAccountCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> asset = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<int> lastRowIndex = const Value.absent(),
                Value<Decimal> balanceSnapshot = const Value.absent(),
                Value<Decimal> reservedSnapshot = const Value.absent(),
                Value<Decimal> unconfirmedSnapshot = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LunoAccountCursorsCompanion(
                connectionId: connectionId,
                accountId: accountId,
                asset: asset,
                accountType: accountType,
                lastRowIndex: lastRowIndex,
                balanceSnapshot: balanceSnapshot,
                reservedSnapshot: reservedSnapshot,
                unconfirmedSnapshot: unconfirmedSnapshot,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int connectionId,
                required String accountId,
                required String asset,
                Value<String> accountType = const Value.absent(),
                Value<int> lastRowIndex = const Value.absent(),
                Value<Decimal> balanceSnapshot = const Value.absent(),
                Value<Decimal> reservedSnapshot = const Value.absent(),
                Value<Decimal> unconfirmedSnapshot = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LunoAccountCursorsCompanion.insert(
                connectionId: connectionId,
                accountId: accountId,
                asset: asset,
                accountType: accountType,
                lastRowIndex: lastRowIndex,
                balanceSnapshot: balanceSnapshot,
                reservedSnapshot: reservedSnapshot,
                unconfirmedSnapshot: unconfirmedSnapshot,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$LunoAccountCursorsTable, LunoCursorRow>(table), $$LunoAccountCursorsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
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
                    if (connectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.connectionId,
                        referencedTable: $$LunoAccountCursorsTableReferences._connectionIdTable(db),
                        referencedColumn: $$LunoAccountCursorsTableReferences._connectionIdTable(db).id,
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

typedef $$LunoAccountCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LunoAccountCursorsTable,
      LunoCursorRow,
      $$LunoAccountCursorsTableFilterComposer,
      $$LunoAccountCursorsTableOrderingComposer,
      $$LunoAccountCursorsTableAnnotationComposer,
      $$LunoAccountCursorsTableCreateCompanionBuilder,
      $$LunoAccountCursorsTableUpdateCompanionBuilder,
      (LunoCursorRow, $$LunoAccountCursorsTableReferences),
      LunoCursorRow,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$LunoMarketsCacheTableCreateCompanionBuilder = LunoMarketsCacheCompanion Function({
  required String pair,
  required String base,
  required String counter,
  Value<int> priceScale,
  Value<int> volumeScale,
  Value<String> tradingStatus,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$LunoMarketsCacheTableUpdateCompanionBuilder = LunoMarketsCacheCompanion Function({
  Value<String> pair,
  Value<String> base,
  Value<String> counter,
  Value<int> priceScale,
  Value<int> volumeScale,
  Value<String> tradingStatus,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$LunoMarketsCacheTableFilterComposer extends Composer<_$AppDatabase, $LunoMarketsCacheTable> {
  $$LunoMarketsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pair => $composableBuilder(column: $table.pair, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get base => $composableBuilder(column: $table.base, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get counter => $composableBuilder(column: $table.counter, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceScale => $composableBuilder(column: $table.priceScale, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get volumeScale => $composableBuilder(column: $table.volumeScale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tradingStatus => $composableBuilder(column: $table.tradingStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$LunoMarketsCacheTableOrderingComposer extends Composer<_$AppDatabase, $LunoMarketsCacheTable> {
  $$LunoMarketsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pair => $composableBuilder(column: $table.pair, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get base => $composableBuilder(column: $table.base, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get counter => $composableBuilder(column: $table.counter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceScale => $composableBuilder(column: $table.priceScale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get volumeScale => $composableBuilder(column: $table.volumeScale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tradingStatus =>
      $composableBuilder(column: $table.tradingStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$LunoMarketsCacheTableAnnotationComposer extends Composer<_$AppDatabase, $LunoMarketsCacheTable> {
  $$LunoMarketsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pair => $composableBuilder(column: $table.pair, builder: (column) => column);

  GeneratedColumn<String> get base => $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<String> get counter => $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<int> get priceScale => $composableBuilder(column: $table.priceScale, builder: (column) => column);

  GeneratedColumn<int> get volumeScale => $composableBuilder(column: $table.volumeScale, builder: (column) => column);

  GeneratedColumn<String> get tradingStatus => $composableBuilder(column: $table.tradingStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt => $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$LunoMarketsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LunoMarketsCacheTable,
          LunoMarketRow,
          $$LunoMarketsCacheTableFilterComposer,
          $$LunoMarketsCacheTableOrderingComposer,
          $$LunoMarketsCacheTableAnnotationComposer,
          $$LunoMarketsCacheTableCreateCompanionBuilder,
          $$LunoMarketsCacheTableUpdateCompanionBuilder,
          (LunoMarketRow, BaseReferences<_$AppDatabase, $LunoMarketsCacheTable, LunoMarketRow>),
          LunoMarketRow,
          PrefetchHooks Function()
        > {
  $$LunoMarketsCacheTableTableManager(_$AppDatabase db, $LunoMarketsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LunoMarketsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LunoMarketsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LunoMarketsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pair = const Value.absent(),
                Value<String> base = const Value.absent(),
                Value<String> counter = const Value.absent(),
                Value<int> priceScale = const Value.absent(),
                Value<int> volumeScale = const Value.absent(),
                Value<String> tradingStatus = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LunoMarketsCacheCompanion(
                pair: pair,
                base: base,
                counter: counter,
                priceScale: priceScale,
                volumeScale: volumeScale,
                tradingStatus: tradingStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pair,
                required String base,
                required String counter,
                Value<int> priceScale = const Value.absent(),
                Value<int> volumeScale = const Value.absent(),
                Value<String> tradingStatus = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => LunoMarketsCacheCompanion.insert(
                pair: pair,
                base: base,
                counter: counter,
                priceScale: priceScale,
                volumeScale: volumeScale,
                tradingStatus: tradingStatus,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LunoMarketsCacheTable, LunoMarketRow>(table),
                  BaseReferences<_$AppDatabase, $LunoMarketsCacheTable, LunoMarketRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LunoMarketsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LunoMarketsCacheTable,
      LunoMarketRow,
      $$LunoMarketsCacheTableFilterComposer,
      $$LunoMarketsCacheTableOrderingComposer,
      $$LunoMarketsCacheTableAnnotationComposer,
      $$LunoMarketsCacheTableCreateCompanionBuilder,
      $$LunoMarketsCacheTableUpdateCompanionBuilder,
      (LunoMarketRow, BaseReferences<_$AppDatabase, $LunoMarketsCacheTable, LunoMarketRow>),
      LunoMarketRow,
      PrefetchHooks Function()
    >;
typedef $$LunoLedgerRowsTableCreateCompanionBuilder = LunoLedgerRowsCompanion Function({
  required int connectionId,
  required String accountId,
  required int rowIndex,
  required int timestampMs,
  required String payloadJson,
  Value<String> state,
  Value<int> rowid,
});
typedef $$LunoLedgerRowsTableUpdateCompanionBuilder = LunoLedgerRowsCompanion Function({
  Value<int> connectionId,
  Value<String> accountId,
  Value<int> rowIndex,
  Value<int> timestampMs,
  Value<String> payloadJson,
  Value<String> state,
  Value<int> rowid,
});

final class $$LunoLedgerRowsTableReferences extends BaseReferences<_$AppDatabase, $LunoLedgerRowsTable, LunoLedgerRow> {
  $$LunoLedgerRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LunoConnectionsTable _connectionIdTable(_$AppDatabase db) =>
      db.lunoConnections.createAlias('luno_ledger_rows__connection_id__luno_connections__id');

  $$LunoConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<int>('connection_id')!;

    final manager = $$LunoConnectionsTableTableManager($_db, $_db.lunoConnections).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LunoLedgerRowsTableFilterComposer extends Composer<_$AppDatabase, $LunoLedgerRowsTable> {
  $$LunoLedgerRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rowIndex => $composableBuilder(column: $table.rowIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestampMs => $composableBuilder(column: $table.timestampMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(column: $table.state, builder: (column) => ColumnFilters(column));

  $$LunoConnectionsTableFilterComposer get connectionId {
    final $$LunoConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableFilterComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$LunoLedgerRowsTableOrderingComposer extends Composer<_$AppDatabase, $LunoLedgerRowsTable> {
  $$LunoLedgerRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rowIndex => $composableBuilder(column: $table.rowIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestampMs => $composableBuilder(column: $table.timestampMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(column: $table.state, builder: (column) => ColumnOrderings(column));

  $$LunoConnectionsTableOrderingComposer get connectionId {
    final $$LunoConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$LunoConnectionsTableOrderingComposer(
        $db: $db,
        $table: $db.lunoConnections,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$LunoLedgerRowsTableAnnotationComposer extends Composer<_$AppDatabase, $LunoLedgerRowsTable> {
  $$LunoLedgerRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId => $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get rowIndex => $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(column: $table.timestampMs, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get state => $composableBuilder(column: $table.state, builder: (column) => column);

  $$LunoConnectionsTableAnnotationComposer get connectionId {
    final $$LunoConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.lunoConnections,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$LunoConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.lunoConnections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LunoLedgerRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LunoLedgerRowsTable,
          LunoLedgerRow,
          $$LunoLedgerRowsTableFilterComposer,
          $$LunoLedgerRowsTableOrderingComposer,
          $$LunoLedgerRowsTableAnnotationComposer,
          $$LunoLedgerRowsTableCreateCompanionBuilder,
          $$LunoLedgerRowsTableUpdateCompanionBuilder,
          (LunoLedgerRow, $$LunoLedgerRowsTableReferences),
          LunoLedgerRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$LunoLedgerRowsTableTableManager(_$AppDatabase db, $LunoLedgerRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LunoLedgerRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LunoLedgerRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LunoLedgerRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> connectionId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LunoLedgerRowsCompanion(
                connectionId: connectionId,
                accountId: accountId,
                rowIndex: rowIndex,
                timestampMs: timestampMs,
                payloadJson: payloadJson,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int connectionId,
                required String accountId,
                required int rowIndex,
                required int timestampMs,
                required String payloadJson,
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LunoLedgerRowsCompanion.insert(
                connectionId: connectionId,
                accountId: accountId,
                rowIndex: rowIndex,
                timestampMs: timestampMs,
                payloadJson: payloadJson,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$LunoLedgerRowsTable, LunoLedgerRow>(table), $$LunoLedgerRowsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
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
                    if (connectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.connectionId,
                        referencedTable: $$LunoLedgerRowsTableReferences._connectionIdTable(db),
                        referencedColumn: $$LunoLedgerRowsTableReferences._connectionIdTable(db).id,
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

typedef $$LunoLedgerRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LunoLedgerRowsTable,
      LunoLedgerRow,
      $$LunoLedgerRowsTableFilterComposer,
      $$LunoLedgerRowsTableOrderingComposer,
      $$LunoLedgerRowsTableAnnotationComposer,
      $$LunoLedgerRowsTableCreateCompanionBuilder,
      $$LunoLedgerRowsTableUpdateCompanionBuilder,
      (LunoLedgerRow, $$LunoLedgerRowsTableReferences),
      LunoLedgerRow,
      PrefetchHooks Function({bool connectionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PortfoliosTableTableManager get portfolios => $$PortfoliosTableTableManager(_db, _db.portfolios);
  $$InstrumentsTableTableManager get instruments => $$InstrumentsTableTableManager(_db, _db.instruments);
  $$LunoConnectionsTableTableManager get lunoConnections => $$LunoConnectionsTableTableManager(_db, _db.lunoConnections);
  $$TransactionsTableTableManager get transactions => $$TransactionsTableTableManager(_db, _db.transactions);
  $$WatchlistsTableTableManager get watchlists => $$WatchlistsTableTableManager(_db, _db.watchlists);
  $$WatchlistItemsTableTableManager get watchlistItems => $$WatchlistItemsTableTableManager(_db, _db.watchlistItems);
  $$QuoteCacheTableTableManager get quoteCache => $$QuoteCacheTableTableManager(_db, _db.quoteCache);
  $$ProfileCacheTableTableManager get profileCache => $$ProfileCacheTableTableManager(_db, _db.profileCache);
  $$PriceHistoryCacheTableTableManager get priceHistoryCache => $$PriceHistoryCacheTableTableManager(_db, _db.priceHistoryCache);
  $$HistoryMetaTableTableManager get historyMeta => $$HistoryMetaTableTableManager(_db, _db.historyMeta);
  $$DividendEventsCacheTableTableManager get dividendEventsCache => $$DividendEventsCacheTableTableManager(_db, _db.dividendEventsCache);
  $$SplitEventsCacheTableTableManager get splitEventsCache => $$SplitEventsCacheTableTableManager(_db, _db.splitEventsCache);
  $$ImportMappingsTableTableManager get importMappings => $$ImportMappingsTableTableManager(_db, _db.importMappings);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$LunoAccountCursorsTableTableManager get lunoAccountCursors => $$LunoAccountCursorsTableTableManager(_db, _db.lunoAccountCursors);
  $$LunoMarketsCacheTableTableManager get lunoMarketsCache => $$LunoMarketsCacheTableTableManager(_db, _db.lunoMarketsCache);
  $$LunoLedgerRowsTableTableManager get lunoLedgerRows => $$LunoLedgerRowsTableTableManager(_db, _db.lunoLedgerRows);
}
