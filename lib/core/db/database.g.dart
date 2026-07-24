// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sourceType,
    addedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
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
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String title;
  final String sourceType;
  final DateTime addedAt;
  final DateTime updatedAt;
  const DocumentRow({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.addedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['source_type'] = Variable<String>(sourceType);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      sourceType: Value(sourceType),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'sourceType': serializer.toJson<String>(sourceType),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? title,
    String? sourceType,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) => DocumentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    sourceType: sourceType ?? this.sourceType,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, sourceType, addedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceType == this.sourceType &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> sourceType;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String title,
    required String sourceType,
    required DateTime addedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sourceType = Value(sourceType),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? sourceType,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceType != null) 'source_type': sourceType,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? sourceType,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters
    with TableInfo<$ChaptersTable, ChapterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id)',
    ),
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blocksJsonMeta = const VerificationMeta(
    'blocksJson',
  );
  @override
  late final GeneratedColumn<String> blocksJson = GeneratedColumn<String>(
    'blocks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    chapterIndex,
    title,
    blocksJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('blocks_json')) {
      context.handle(
        _blocksJsonMeta,
        blocksJson.isAcceptableOrUnknown(data['blocks_json']!, _blocksJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_blocksJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChapterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      blocksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_json'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class ChapterRow extends DataClass implements Insertable<ChapterRow> {
  final String id;
  final String documentId;
  final int chapterIndex;
  final String? title;
  final String blocksJson;
  const ChapterRow({
    required this.id,
    required this.documentId,
    required this.chapterIndex,
    this.title,
    required this.blocksJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['blocks_json'] = Variable<String>(blocksJson);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      documentId: Value(documentId),
      chapterIndex: Value(chapterIndex),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      blocksJson: Value(blocksJson),
    );
  }

  factory ChapterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      title: serializer.fromJson<String?>(json['title']),
      blocksJson: serializer.fromJson<String>(json['blocksJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'title': serializer.toJson<String?>(title),
      'blocksJson': serializer.toJson<String>(blocksJson),
    };
  }

  ChapterRow copyWith({
    String? id,
    String? documentId,
    int? chapterIndex,
    Value<String?> title = const Value.absent(),
    String? blocksJson,
  }) => ChapterRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    title: title.present ? title.value : this.title,
    blocksJson: blocksJson ?? this.blocksJson,
  );
  ChapterRow copyWithCompanion(ChaptersCompanion data) {
    return ChapterRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      title: data.title.present ? data.title.value : this.title,
      blocksJson: data.blocksJson.present
          ? data.blocksJson.value
          : this.blocksJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('title: $title, ')
          ..write('blocksJson: $blocksJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, documentId, chapterIndex, title, blocksJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.chapterIndex == this.chapterIndex &&
          other.title == this.title &&
          other.blocksJson == this.blocksJson);
}

class ChaptersCompanion extends UpdateCompanion<ChapterRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> chapterIndex;
  final Value<String?> title;
  final Value<String> blocksJson;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.title = const Value.absent(),
    this.blocksJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String documentId,
    required int chapterIndex,
    this.title = const Value.absent(),
    required String blocksJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       chapterIndex = Value(chapterIndex),
       blocksJson = Value(blocksJson);
  static Insertable<ChapterRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? chapterIndex,
    Expression<String>? title,
    Expression<String>? blocksJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (title != null) 'title': title,
      if (blocksJson != null) 'blocks_json': blocksJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? chapterIndex,
    Value<String?>? title,
    Value<String>? blocksJson,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      title: title ?? this.title,
      blocksJson: blocksJson ?? this.blocksJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (blocksJson.present) {
      map['blocks_json'] = Variable<String>(blocksJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('title: $title, ')
          ..write('blocksJson: $blocksJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SentencesTable extends Sentences
    with TableInfo<$SentencesTable, SentenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id)',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id)',
    ),
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockIndexMeta = const VerificationMeta(
    'blockIndex',
  );
  @override
  late final GeneratedColumn<int> blockIndex = GeneratedColumn<int>(
    'block_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentenceIndexMeta = const VerificationMeta(
    'sentenceIndex',
  );
  @override
  late final GeneratedColumn<int> sentenceIndex = GeneratedColumn<int>(
    'sentence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    chapterId,
    chapterIndex,
    blockIndex,
    sentenceIndex,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentences';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('block_index')) {
      context.handle(
        _blockIndexMeta,
        blockIndex.isAcceptableOrUnknown(data['block_index']!, _blockIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIndexMeta);
    }
    if (data.containsKey('sentence_index')) {
      context.handle(
        _sentenceIndexMeta,
        sentenceIndex.isAcceptableOrUnknown(
          data['sentence_index']!,
          _sentenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sentenceIndexMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SentenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      blockIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_index'],
      )!,
      sentenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentence_index'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $SentencesTable createAlias(String alias) {
    return $SentencesTable(attachedDatabase, alias);
  }
}

class SentenceRow extends DataClass implements Insertable<SentenceRow> {
  final String id;
  final String documentId;
  final String chapterId;
  final int chapterIndex;
  final int blockIndex;
  final int sentenceIndex;
  final String content;
  const SentenceRow({
    required this.id,
    required this.documentId,
    required this.chapterId,
    required this.chapterIndex,
    required this.blockIndex,
    required this.sentenceIndex,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['block_index'] = Variable<int>(blockIndex);
    map['sentence_index'] = Variable<int>(sentenceIndex);
    map['content'] = Variable<String>(content);
    return map;
  }

  SentencesCompanion toCompanion(bool nullToAbsent) {
    return SentencesCompanion(
      id: Value(id),
      documentId: Value(documentId),
      chapterId: Value(chapterId),
      chapterIndex: Value(chapterIndex),
      blockIndex: Value(blockIndex),
      sentenceIndex: Value(sentenceIndex),
      content: Value(content),
    );
  }

  factory SentenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentenceRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      blockIndex: serializer.fromJson<int>(json['blockIndex']),
      sentenceIndex: serializer.fromJson<int>(json['sentenceIndex']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'chapterId': serializer.toJson<String>(chapterId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'blockIndex': serializer.toJson<int>(blockIndex),
      'sentenceIndex': serializer.toJson<int>(sentenceIndex),
      'content': serializer.toJson<String>(content),
    };
  }

  SentenceRow copyWith({
    String? id,
    String? documentId,
    String? chapterId,
    int? chapterIndex,
    int? blockIndex,
    int? sentenceIndex,
    String? content,
  }) => SentenceRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    chapterId: chapterId ?? this.chapterId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    blockIndex: blockIndex ?? this.blockIndex,
    sentenceIndex: sentenceIndex ?? this.sentenceIndex,
    content: content ?? this.content,
  );
  SentenceRow copyWithCompanion(SentencesCompanion data) {
    return SentenceRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      blockIndex: data.blockIndex.present
          ? data.blockIndex.value
          : this.blockIndex,
      sentenceIndex: data.sentenceIndex.present
          ? data.sentenceIndex.value
          : this.sentenceIndex,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentenceRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('blockIndex: $blockIndex, ')
          ..write('sentenceIndex: $sentenceIndex, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    chapterId,
    chapterIndex,
    blockIndex,
    sentenceIndex,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentenceRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.chapterId == this.chapterId &&
          other.chapterIndex == this.chapterIndex &&
          other.blockIndex == this.blockIndex &&
          other.sentenceIndex == this.sentenceIndex &&
          other.content == this.content);
}

class SentencesCompanion extends UpdateCompanion<SentenceRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<String> chapterId;
  final Value<int> chapterIndex;
  final Value<int> blockIndex;
  final Value<int> sentenceIndex;
  final Value<String> content;
  final Value<int> rowid;
  const SentencesCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.blockIndex = const Value.absent(),
    this.sentenceIndex = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentencesCompanion.insert({
    required String id,
    required String documentId,
    required String chapterId,
    required int chapterIndex,
    required int blockIndex,
    required int sentenceIndex,
    required String content,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       chapterId = Value(chapterId),
       chapterIndex = Value(chapterIndex),
       blockIndex = Value(blockIndex),
       sentenceIndex = Value(sentenceIndex),
       content = Value(content);
  static Insertable<SentenceRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<String>? chapterId,
    Expression<int>? chapterIndex,
    Expression<int>? blockIndex,
    Expression<int>? sentenceIndex,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (blockIndex != null) 'block_index': blockIndex,
      if (sentenceIndex != null) 'sentence_index': sentenceIndex,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentencesCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<String>? chapterId,
    Value<int>? chapterIndex,
    Value<int>? blockIndex,
    Value<int>? sentenceIndex,
    Value<String>? content,
    Value<int>? rowid,
  }) {
    return SentencesCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      chapterId: chapterId ?? this.chapterId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      blockIndex: blockIndex ?? this.blockIndex,
      sentenceIndex: sentenceIndex ?? this.sentenceIndex,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (blockIndex.present) {
      map['block_index'] = Variable<int>(blockIndex.value);
    }
    if (sentenceIndex.present) {
      map['sentence_index'] = Variable<int>(sentenceIndex.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencesCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('blockIndex: $blockIndex, ')
          ..write('sentenceIndex: $sentenceIndex, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionariesTable extends Dictionaries
    with TableInfo<$DictionariesTable, Dictionary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyModeMeta = const VerificationMeta(
    'frequencyMode',
  );
  @override
  late final GeneratedColumn<String> frequencyMode = GeneratedColumn<String>(
    'frequency_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sequencedMeta = const VerificationMeta(
    'sequenced',
  );
  @override
  late final GeneratedColumn<bool> sequenced = GeneratedColumn<bool>(
    'sequenced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sequenced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    revision,
    formatVersion,
    author,
    url,
    description,
    attribution,
    sourceLanguage,
    targetLanguage,
    frequencyMode,
    sequenced,
    priority,
    enabled,
    addedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dictionary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    }
    if (data.containsKey('frequency_mode')) {
      context.handle(
        _frequencyModeMeta,
        frequencyMode.isAcceptableOrUnknown(
          data['frequency_mode']!,
          _frequencyModeMeta,
        ),
      );
    }
    if (data.containsKey('sequenced')) {
      context.handle(
        _sequencedMeta,
        sequenced.isAcceptableOrUnknown(data['sequenced']!, _sequencedMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
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
  Dictionary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dictionary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      ),
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      ),
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      ),
      frequencyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency_mode'],
      ),
      sequenced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sequenced'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DictionariesTable createAlias(String alias) {
    return $DictionariesTable(attachedDatabase, alias);
  }
}

class Dictionary extends DataClass implements Insertable<Dictionary> {
  final String id;
  final String title;
  final String revision;
  final int formatVersion;
  final String? author;
  final String? url;
  final String? description;
  final String? attribution;
  final String? sourceLanguage;
  final String? targetLanguage;

  /// `index.json`'s `frequencyMode`: `occurrence-based` | `rank-based`.
  /// Affects how a frequency-dictionary number should be displayed; not
  /// interpreted by storage/lookup, just carried through for the popup UI.
  final String? frequencyMode;

  /// Whether term entries carry meaningful `sequence` numbers for
  /// `resultOutputMode: merge` display (`index.json`'s `sequenced`).
  final bool sequenced;

  /// User-ordered lookup priority. Lower = higher priority = preferred for
  /// the popup's default definition. Dense (0..N-1) and fully renumbered on
  /// every reorder rather than left sparse -- the dictionary count is small
  /// (tens, not thousands), so a full renumber on drag-reorder is cheap and
  /// keeps queries simple (no gap-management logic).
  final int priority;
  final bool enabled;
  final DateTime addedAt;
  final DateTime updatedAt;
  const Dictionary({
    required this.id,
    required this.title,
    required this.revision,
    required this.formatVersion,
    this.author,
    this.url,
    this.description,
    this.attribution,
    this.sourceLanguage,
    this.targetLanguage,
    this.frequencyMode,
    required this.sequenced,
    required this.priority,
    required this.enabled,
    required this.addedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['revision'] = Variable<String>(revision);
    map['format_version'] = Variable<int>(formatVersion);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || attribution != null) {
      map['attribution'] = Variable<String>(attribution);
    }
    if (!nullToAbsent || sourceLanguage != null) {
      map['source_language'] = Variable<String>(sourceLanguage);
    }
    if (!nullToAbsent || targetLanguage != null) {
      map['target_language'] = Variable<String>(targetLanguage);
    }
    if (!nullToAbsent || frequencyMode != null) {
      map['frequency_mode'] = Variable<String>(frequencyMode);
    }
    map['sequenced'] = Variable<bool>(sequenced);
    map['priority'] = Variable<int>(priority);
    map['enabled'] = Variable<bool>(enabled);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DictionariesCompanion toCompanion(bool nullToAbsent) {
    return DictionariesCompanion(
      id: Value(id),
      title: Value(title),
      revision: Value(revision),
      formatVersion: Value(formatVersion),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      attribution: attribution == null && nullToAbsent
          ? const Value.absent()
          : Value(attribution),
      sourceLanguage: sourceLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLanguage),
      targetLanguage: targetLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(targetLanguage),
      frequencyMode: frequencyMode == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyMode),
      sequenced: Value(sequenced),
      priority: Value(priority),
      enabled: Value(enabled),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Dictionary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dictionary(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      revision: serializer.fromJson<String>(json['revision']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      author: serializer.fromJson<String?>(json['author']),
      url: serializer.fromJson<String?>(json['url']),
      description: serializer.fromJson<String?>(json['description']),
      attribution: serializer.fromJson<String?>(json['attribution']),
      sourceLanguage: serializer.fromJson<String?>(json['sourceLanguage']),
      targetLanguage: serializer.fromJson<String?>(json['targetLanguage']),
      frequencyMode: serializer.fromJson<String?>(json['frequencyMode']),
      sequenced: serializer.fromJson<bool>(json['sequenced']),
      priority: serializer.fromJson<int>(json['priority']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'revision': serializer.toJson<String>(revision),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'author': serializer.toJson<String?>(author),
      'url': serializer.toJson<String?>(url),
      'description': serializer.toJson<String?>(description),
      'attribution': serializer.toJson<String?>(attribution),
      'sourceLanguage': serializer.toJson<String?>(sourceLanguage),
      'targetLanguage': serializer.toJson<String?>(targetLanguage),
      'frequencyMode': serializer.toJson<String?>(frequencyMode),
      'sequenced': serializer.toJson<bool>(sequenced),
      'priority': serializer.toJson<int>(priority),
      'enabled': serializer.toJson<bool>(enabled),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Dictionary copyWith({
    String? id,
    String? title,
    String? revision,
    int? formatVersion,
    Value<String?> author = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> attribution = const Value.absent(),
    Value<String?> sourceLanguage = const Value.absent(),
    Value<String?> targetLanguage = const Value.absent(),
    Value<String?> frequencyMode = const Value.absent(),
    bool? sequenced,
    int? priority,
    bool? enabled,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) => Dictionary(
    id: id ?? this.id,
    title: title ?? this.title,
    revision: revision ?? this.revision,
    formatVersion: formatVersion ?? this.formatVersion,
    author: author.present ? author.value : this.author,
    url: url.present ? url.value : this.url,
    description: description.present ? description.value : this.description,
    attribution: attribution.present ? attribution.value : this.attribution,
    sourceLanguage: sourceLanguage.present
        ? sourceLanguage.value
        : this.sourceLanguage,
    targetLanguage: targetLanguage.present
        ? targetLanguage.value
        : this.targetLanguage,
    frequencyMode: frequencyMode.present
        ? frequencyMode.value
        : this.frequencyMode,
    sequenced: sequenced ?? this.sequenced,
    priority: priority ?? this.priority,
    enabled: enabled ?? this.enabled,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Dictionary copyWithCompanion(DictionariesCompanion data) {
    return Dictionary(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      revision: data.revision.present ? data.revision.value : this.revision,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      author: data.author.present ? data.author.value : this.author,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      frequencyMode: data.frequencyMode.present
          ? data.frequencyMode.value
          : this.frequencyMode,
      sequenced: data.sequenced.present ? data.sequenced.value : this.sequenced,
      priority: data.priority.present ? data.priority.value : this.priority,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dictionary(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('author: $author, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('attribution: $attribution, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('frequencyMode: $frequencyMode, ')
          ..write('sequenced: $sequenced, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    revision,
    formatVersion,
    author,
    url,
    description,
    attribution,
    sourceLanguage,
    targetLanguage,
    frequencyMode,
    sequenced,
    priority,
    enabled,
    addedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dictionary &&
          other.id == this.id &&
          other.title == this.title &&
          other.revision == this.revision &&
          other.formatVersion == this.formatVersion &&
          other.author == this.author &&
          other.url == this.url &&
          other.description == this.description &&
          other.attribution == this.attribution &&
          other.sourceLanguage == this.sourceLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.frequencyMode == this.frequencyMode &&
          other.sequenced == this.sequenced &&
          other.priority == this.priority &&
          other.enabled == this.enabled &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt);
}

class DictionariesCompanion extends UpdateCompanion<Dictionary> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> revision;
  final Value<int> formatVersion;
  final Value<String?> author;
  final Value<String?> url;
  final Value<String?> description;
  final Value<String?> attribution;
  final Value<String?> sourceLanguage;
  final Value<String?> targetLanguage;
  final Value<String?> frequencyMode;
  final Value<bool> sequenced;
  final Value<int> priority;
  final Value<bool> enabled;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DictionariesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.revision = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.author = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.attribution = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.frequencyMode = const Value.absent(),
    this.sequenced = const Value.absent(),
    this.priority = const Value.absent(),
    this.enabled = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionariesCompanion.insert({
    required String id,
    required String title,
    required String revision,
    required int formatVersion,
    this.author = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.attribution = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.frequencyMode = const Value.absent(),
    this.sequenced = const Value.absent(),
    required int priority,
    this.enabled = const Value.absent(),
    required DateTime addedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       revision = Value(revision),
       formatVersion = Value(formatVersion),
       priority = Value(priority),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Dictionary> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? revision,
    Expression<int>? formatVersion,
    Expression<String>? author,
    Expression<String>? url,
    Expression<String>? description,
    Expression<String>? attribution,
    Expression<String>? sourceLanguage,
    Expression<String>? targetLanguage,
    Expression<String>? frequencyMode,
    Expression<bool>? sequenced,
    Expression<int>? priority,
    Expression<bool>? enabled,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (revision != null) 'revision': revision,
      if (formatVersion != null) 'format_version': formatVersion,
      if (author != null) 'author': author,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (attribution != null) 'attribution': attribution,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (frequencyMode != null) 'frequency_mode': frequencyMode,
      if (sequenced != null) 'sequenced': sequenced,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionariesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? revision,
    Value<int>? formatVersion,
    Value<String?>? author,
    Value<String?>? url,
    Value<String?>? description,
    Value<String?>? attribution,
    Value<String?>? sourceLanguage,
    Value<String?>? targetLanguage,
    Value<String?>? frequencyMode,
    Value<bool>? sequenced,
    Value<int>? priority,
    Value<bool>? enabled,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DictionariesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      revision: revision ?? this.revision,
      formatVersion: formatVersion ?? this.formatVersion,
      author: author ?? this.author,
      url: url ?? this.url,
      description: description ?? this.description,
      attribution: attribution ?? this.attribution,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      frequencyMode: frequencyMode ?? this.frequencyMode,
      sequenced: sequenced ?? this.sequenced,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (frequencyMode.present) {
      map['frequency_mode'] = Variable<String>(frequencyMode.value);
    }
    if (sequenced.present) {
      map['sequenced'] = Variable<bool>(sequenced.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionariesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('author: $author, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('attribution: $attribution, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('frequencyMode: $frequencyMode, ')
          ..write('sequenced: $sequenced, ')
          ..write('priority: $priority, ')
          ..write('enabled: $enabled, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionaryTagEntriesTable extends DictionaryTagEntries
    with TableInfo<$DictionaryTagEntriesTable, DictionaryTagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryTagEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<String> dictionaryId = GeneratedColumn<String>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionaries (id)',
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    name,
    category,
    sortOrder,
    notes,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_tag_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryTagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {dictionaryId, name},
  ];
  @override
  DictionaryTagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryTagEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $DictionaryTagEntriesTable createAlias(String alias) {
    return $DictionaryTagEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryTagEntry extends DataClass
    implements Insertable<DictionaryTagEntry> {
  final int id;
  final String dictionaryId;
  final String name;
  final String category;

  /// `tag_bank`'s field name is `order` -- reserved in SQL, so this column
  /// is both Dart- and SQL-renamed.
  final int sortOrder;
  final String notes;
  final double score;
  const DictionaryTagEntry({
    required this.id,
    required this.dictionaryId,
    required this.name,
    required this.category,
    required this.sortOrder,
    required this.notes,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<String>(dictionaryId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['sort_order'] = Variable<int>(sortOrder);
    map['notes'] = Variable<String>(notes);
    map['score'] = Variable<double>(score);
    return map;
  }

  DictionaryTagEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryTagEntriesCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      name: Value(name),
      category: Value(category),
      sortOrder: Value(sortOrder),
      notes: Value(notes),
      score: Value(score),
    );
  }

  factory DictionaryTagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryTagEntry(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<String>(json['dictionaryId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      notes: serializer.fromJson<String>(json['notes']),
      score: serializer.fromJson<double>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<String>(dictionaryId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'notes': serializer.toJson<String>(notes),
      'score': serializer.toJson<double>(score),
    };
  }

  DictionaryTagEntry copyWith({
    int? id,
    String? dictionaryId,
    String? name,
    String? category,
    int? sortOrder,
    String? notes,
    double? score,
  }) => DictionaryTagEntry(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    name: name ?? this.name,
    category: category ?? this.category,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes ?? this.notes,
    score: score ?? this.score,
  );
  DictionaryTagEntry copyWithCompanion(DictionaryTagEntriesCompanion data) {
    return DictionaryTagEntry(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      notes: data.notes.present ? data.notes.value : this.notes,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTagEntry(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dictionaryId, name, category, sortOrder, notes, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryTagEntry &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.name == this.name &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder &&
          other.notes == this.notes &&
          other.score == this.score);
}

class DictionaryTagEntriesCompanion
    extends UpdateCompanion<DictionaryTagEntry> {
  final Value<int> id;
  final Value<String> dictionaryId;
  final Value<String> name;
  final Value<String> category;
  final Value<int> sortOrder;
  final Value<String> notes;
  final Value<double> score;
  const DictionaryTagEntriesCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notes = const Value.absent(),
    this.score = const Value.absent(),
  });
  DictionaryTagEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String dictionaryId,
    required String name,
    required String category,
    required int sortOrder,
    required String notes,
    required double score,
  }) : dictionaryId = Value(dictionaryId),
       name = Value(name),
       category = Value(category),
       sortOrder = Value(sortOrder),
       notes = Value(notes),
       score = Value(score);
  static Insertable<DictionaryTagEntry> custom({
    Expression<int>? id,
    Expression<String>? dictionaryId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? sortOrder,
    Expression<String>? notes,
    Expression<double>? score,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (score != null) 'score': score,
    });
  }

  DictionaryTagEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? dictionaryId,
    Value<String>? name,
    Value<String>? category,
    Value<int>? sortOrder,
    Value<String>? notes,
    Value<double>? score,
  }) {
    return DictionaryTagEntriesCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      name: name ?? this.name,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      score: score ?? this.score,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<String>(dictionaryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTagEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }
}

class $DictionaryTermEntriesTable extends DictionaryTermEntries
    with TableInfo<$DictionaryTermEntriesTable, DictionaryTermEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryTermEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<String> dictionaryId = GeneratedColumn<String>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionaries (id)',
    ),
  );
  static const VerificationMeta _headwordMeta = const VerificationMeta(
    'headword',
  );
  @override
  late final GeneratedColumn<String> headword = GeneratedColumn<String>(
    'headword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingNormalizedMeta = const VerificationMeta(
    'readingNormalized',
  );
  @override
  late final GeneratedColumn<String> readingNormalized =
      GeneratedColumn<String>(
        'reading_normalized',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _definitionTagsMeta = const VerificationMeta(
    'definitionTags',
  );
  @override
  late final GeneratedColumn<String> definitionTags = GeneratedColumn<String>(
    'definition_tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rulesMeta = const VerificationMeta('rules');
  @override
  late final GeneratedColumn<String> rules = GeneratedColumn<String>(
    'rules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionsJsonMeta = const VerificationMeta(
    'definitionsJson',
  );
  @override
  late final GeneratedColumn<String> definitionsJson = GeneratedColumn<String>(
    'definitions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termTagsMeta = const VerificationMeta(
    'termTags',
  );
  @override
  late final GeneratedColumn<String> termTags = GeneratedColumn<String>(
    'term_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importOrderMeta = const VerificationMeta(
    'importOrder',
  );
  @override
  late final GeneratedColumn<int> importOrder = GeneratedColumn<int>(
    'import_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    headword,
    reading,
    readingNormalized,
    definitionTags,
    rules,
    score,
    definitionsJson,
    sequence,
    termTags,
    importOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_term_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryTermEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('headword')) {
      context.handle(
        _headwordMeta,
        headword.isAcceptableOrUnknown(data['headword']!, _headwordMeta),
      );
    } else if (isInserting) {
      context.missing(_headwordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('reading_normalized')) {
      context.handle(
        _readingNormalizedMeta,
        readingNormalized.isAcceptableOrUnknown(
          data['reading_normalized']!,
          _readingNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingNormalizedMeta);
    }
    if (data.containsKey('definition_tags')) {
      context.handle(
        _definitionTagsMeta,
        definitionTags.isAcceptableOrUnknown(
          data['definition_tags']!,
          _definitionTagsMeta,
        ),
      );
    }
    if (data.containsKey('rules')) {
      context.handle(
        _rulesMeta,
        rules.isAcceptableOrUnknown(data['rules']!, _rulesMeta),
      );
    } else if (isInserting) {
      context.missing(_rulesMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('definitions_json')) {
      context.handle(
        _definitionsJsonMeta,
        definitionsJson.isAcceptableOrUnknown(
          data['definitions_json']!,
          _definitionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionsJsonMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('term_tags')) {
      context.handle(
        _termTagsMeta,
        termTags.isAcceptableOrUnknown(data['term_tags']!, _termTagsMeta),
      );
    } else if (isInserting) {
      context.missing(_termTagsMeta);
    }
    if (data.containsKey('import_order')) {
      context.handle(
        _importOrderMeta,
        importOrder.isAcceptableOrUnknown(
          data['import_order']!,
          _importOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryTermEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryTermEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_id'],
      )!,
      headword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headword'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      readingNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_normalized'],
      )!,
      definitionTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_tags'],
      ),
      rules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      definitionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definitions_json'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      termTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_tags'],
      )!,
      importOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_order'],
      )!,
    );
  }

  @override
  $DictionaryTermEntriesTable createAlias(String alias) {
    return $DictionaryTermEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryTermEntry extends DataClass
    implements Insertable<DictionaryTermEntry> {
  final int id;
  final String dictionaryId;
  final String headword;
  final String reading;

  /// Normalized at import time: `reading.isEmpty ? headword : reading`, so
  /// lookup queries never special-case the "empty reading means same as
  /// term" schema rule -- every row has a real, non-empty reading to match
  /// against.
  final String readingNormalized;
  final String? definitionTags;
  final String rules;
  final double score;
  final String definitionsJson;
  final int sequence;
  final String termTags;

  /// Position within the dictionary's term banks, counted across all
  /// `term_bank_N.json` files in filename order (file order first, then
  /// array order within each file). Used as the final tiebreaker when two
  /// entries share a dictionary and a score, so results stay deterministic
  /// and match the order the dictionary author shipped them in.
  final int importOrder;
  const DictionaryTermEntry({
    required this.id,
    required this.dictionaryId,
    required this.headword,
    required this.reading,
    required this.readingNormalized,
    this.definitionTags,
    required this.rules,
    required this.score,
    required this.definitionsJson,
    required this.sequence,
    required this.termTags,
    required this.importOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<String>(dictionaryId);
    map['headword'] = Variable<String>(headword);
    map['reading'] = Variable<String>(reading);
    map['reading_normalized'] = Variable<String>(readingNormalized);
    if (!nullToAbsent || definitionTags != null) {
      map['definition_tags'] = Variable<String>(definitionTags);
    }
    map['rules'] = Variable<String>(rules);
    map['score'] = Variable<double>(score);
    map['definitions_json'] = Variable<String>(definitionsJson);
    map['sequence'] = Variable<int>(sequence);
    map['term_tags'] = Variable<String>(termTags);
    map['import_order'] = Variable<int>(importOrder);
    return map;
  }

  DictionaryTermEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryTermEntriesCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      headword: Value(headword),
      reading: Value(reading),
      readingNormalized: Value(readingNormalized),
      definitionTags: definitionTags == null && nullToAbsent
          ? const Value.absent()
          : Value(definitionTags),
      rules: Value(rules),
      score: Value(score),
      definitionsJson: Value(definitionsJson),
      sequence: Value(sequence),
      termTags: Value(termTags),
      importOrder: Value(importOrder),
    );
  }

  factory DictionaryTermEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryTermEntry(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<String>(json['dictionaryId']),
      headword: serializer.fromJson<String>(json['headword']),
      reading: serializer.fromJson<String>(json['reading']),
      readingNormalized: serializer.fromJson<String>(json['readingNormalized']),
      definitionTags: serializer.fromJson<String?>(json['definitionTags']),
      rules: serializer.fromJson<String>(json['rules']),
      score: serializer.fromJson<double>(json['score']),
      definitionsJson: serializer.fromJson<String>(json['definitionsJson']),
      sequence: serializer.fromJson<int>(json['sequence']),
      termTags: serializer.fromJson<String>(json['termTags']),
      importOrder: serializer.fromJson<int>(json['importOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<String>(dictionaryId),
      'headword': serializer.toJson<String>(headword),
      'reading': serializer.toJson<String>(reading),
      'readingNormalized': serializer.toJson<String>(readingNormalized),
      'definitionTags': serializer.toJson<String?>(definitionTags),
      'rules': serializer.toJson<String>(rules),
      'score': serializer.toJson<double>(score),
      'definitionsJson': serializer.toJson<String>(definitionsJson),
      'sequence': serializer.toJson<int>(sequence),
      'termTags': serializer.toJson<String>(termTags),
      'importOrder': serializer.toJson<int>(importOrder),
    };
  }

  DictionaryTermEntry copyWith({
    int? id,
    String? dictionaryId,
    String? headword,
    String? reading,
    String? readingNormalized,
    Value<String?> definitionTags = const Value.absent(),
    String? rules,
    double? score,
    String? definitionsJson,
    int? sequence,
    String? termTags,
    int? importOrder,
  }) => DictionaryTermEntry(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    headword: headword ?? this.headword,
    reading: reading ?? this.reading,
    readingNormalized: readingNormalized ?? this.readingNormalized,
    definitionTags: definitionTags.present
        ? definitionTags.value
        : this.definitionTags,
    rules: rules ?? this.rules,
    score: score ?? this.score,
    definitionsJson: definitionsJson ?? this.definitionsJson,
    sequence: sequence ?? this.sequence,
    termTags: termTags ?? this.termTags,
    importOrder: importOrder ?? this.importOrder,
  );
  DictionaryTermEntry copyWithCompanion(DictionaryTermEntriesCompanion data) {
    return DictionaryTermEntry(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      headword: data.headword.present ? data.headword.value : this.headword,
      reading: data.reading.present ? data.reading.value : this.reading,
      readingNormalized: data.readingNormalized.present
          ? data.readingNormalized.value
          : this.readingNormalized,
      definitionTags: data.definitionTags.present
          ? data.definitionTags.value
          : this.definitionTags,
      rules: data.rules.present ? data.rules.value : this.rules,
      score: data.score.present ? data.score.value : this.score,
      definitionsJson: data.definitionsJson.present
          ? data.definitionsJson.value
          : this.definitionsJson,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      termTags: data.termTags.present ? data.termTags.value : this.termTags,
      importOrder: data.importOrder.present
          ? data.importOrder.value
          : this.importOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTermEntry(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('reading: $reading, ')
          ..write('readingNormalized: $readingNormalized, ')
          ..write('definitionTags: $definitionTags, ')
          ..write('rules: $rules, ')
          ..write('score: $score, ')
          ..write('definitionsJson: $definitionsJson, ')
          ..write('sequence: $sequence, ')
          ..write('termTags: $termTags, ')
          ..write('importOrder: $importOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictionaryId,
    headword,
    reading,
    readingNormalized,
    definitionTags,
    rules,
    score,
    definitionsJson,
    sequence,
    termTags,
    importOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryTermEntry &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.headword == this.headword &&
          other.reading == this.reading &&
          other.readingNormalized == this.readingNormalized &&
          other.definitionTags == this.definitionTags &&
          other.rules == this.rules &&
          other.score == this.score &&
          other.definitionsJson == this.definitionsJson &&
          other.sequence == this.sequence &&
          other.termTags == this.termTags &&
          other.importOrder == this.importOrder);
}

class DictionaryTermEntriesCompanion
    extends UpdateCompanion<DictionaryTermEntry> {
  final Value<int> id;
  final Value<String> dictionaryId;
  final Value<String> headword;
  final Value<String> reading;
  final Value<String> readingNormalized;
  final Value<String?> definitionTags;
  final Value<String> rules;
  final Value<double> score;
  final Value<String> definitionsJson;
  final Value<int> sequence;
  final Value<String> termTags;
  final Value<int> importOrder;
  const DictionaryTermEntriesCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.headword = const Value.absent(),
    this.reading = const Value.absent(),
    this.readingNormalized = const Value.absent(),
    this.definitionTags = const Value.absent(),
    this.rules = const Value.absent(),
    this.score = const Value.absent(),
    this.definitionsJson = const Value.absent(),
    this.sequence = const Value.absent(),
    this.termTags = const Value.absent(),
    this.importOrder = const Value.absent(),
  });
  DictionaryTermEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String dictionaryId,
    required String headword,
    required String reading,
    required String readingNormalized,
    this.definitionTags = const Value.absent(),
    required String rules,
    required double score,
    required String definitionsJson,
    required int sequence,
    required String termTags,
    required int importOrder,
  }) : dictionaryId = Value(dictionaryId),
       headword = Value(headword),
       reading = Value(reading),
       readingNormalized = Value(readingNormalized),
       rules = Value(rules),
       score = Value(score),
       definitionsJson = Value(definitionsJson),
       sequence = Value(sequence),
       termTags = Value(termTags),
       importOrder = Value(importOrder);
  static Insertable<DictionaryTermEntry> custom({
    Expression<int>? id,
    Expression<String>? dictionaryId,
    Expression<String>? headword,
    Expression<String>? reading,
    Expression<String>? readingNormalized,
    Expression<String>? definitionTags,
    Expression<String>? rules,
    Expression<double>? score,
    Expression<String>? definitionsJson,
    Expression<int>? sequence,
    Expression<String>? termTags,
    Expression<int>? importOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (headword != null) 'headword': headword,
      if (reading != null) 'reading': reading,
      if (readingNormalized != null) 'reading_normalized': readingNormalized,
      if (definitionTags != null) 'definition_tags': definitionTags,
      if (rules != null) 'rules': rules,
      if (score != null) 'score': score,
      if (definitionsJson != null) 'definitions_json': definitionsJson,
      if (sequence != null) 'sequence': sequence,
      if (termTags != null) 'term_tags': termTags,
      if (importOrder != null) 'import_order': importOrder,
    });
  }

  DictionaryTermEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? dictionaryId,
    Value<String>? headword,
    Value<String>? reading,
    Value<String>? readingNormalized,
    Value<String?>? definitionTags,
    Value<String>? rules,
    Value<double>? score,
    Value<String>? definitionsJson,
    Value<int>? sequence,
    Value<String>? termTags,
    Value<int>? importOrder,
  }) {
    return DictionaryTermEntriesCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      headword: headword ?? this.headword,
      reading: reading ?? this.reading,
      readingNormalized: readingNormalized ?? this.readingNormalized,
      definitionTags: definitionTags ?? this.definitionTags,
      rules: rules ?? this.rules,
      score: score ?? this.score,
      definitionsJson: definitionsJson ?? this.definitionsJson,
      sequence: sequence ?? this.sequence,
      termTags: termTags ?? this.termTags,
      importOrder: importOrder ?? this.importOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<String>(dictionaryId.value);
    }
    if (headword.present) {
      map['headword'] = Variable<String>(headword.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (readingNormalized.present) {
      map['reading_normalized'] = Variable<String>(readingNormalized.value);
    }
    if (definitionTags.present) {
      map['definition_tags'] = Variable<String>(definitionTags.value);
    }
    if (rules.present) {
      map['rules'] = Variable<String>(rules.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (definitionsJson.present) {
      map['definitions_json'] = Variable<String>(definitionsJson.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (termTags.present) {
      map['term_tags'] = Variable<String>(termTags.value);
    }
    if (importOrder.present) {
      map['import_order'] = Variable<int>(importOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTermEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('reading: $reading, ')
          ..write('readingNormalized: $readingNormalized, ')
          ..write('definitionTags: $definitionTags, ')
          ..write('rules: $rules, ')
          ..write('score: $score, ')
          ..write('definitionsJson: $definitionsJson, ')
          ..write('sequence: $sequence, ')
          ..write('termTags: $termTags, ')
          ..write('importOrder: $importOrder')
          ..write(')'))
        .toString();
  }
}

class $DictionaryTermMetaEntriesTable extends DictionaryTermMetaEntries
    with TableInfo<$DictionaryTermMetaEntriesTable, DictionaryTermMetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryTermMetaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<String> dictionaryId = GeneratedColumn<String>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dictionaries (id)',
    ),
  );
  static const VerificationMeta _headwordMeta = const VerificationMeta(
    'headword',
  );
  @override
  late final GeneratedColumn<String> headword = GeneratedColumn<String>(
    'headword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    headword,
    mode,
    reading,
    dataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_term_meta_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryTermMetaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('headword')) {
      context.handle(
        _headwordMeta,
        headword.isAcceptableOrUnknown(data['headword']!, _headwordMeta),
      );
    } else if (isInserting) {
      context.missing(_headwordMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryTermMetaEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryTermMetaEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_id'],
      )!,
      headword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headword'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      ),
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
    );
  }

  @override
  $DictionaryTermMetaEntriesTable createAlias(String alias) {
    return $DictionaryTermMetaEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryTermMetaEntry extends DataClass
    implements Insertable<DictionaryTermMetaEntry> {
  final int id;
  final String dictionaryId;
  final String headword;
  final String mode;
  final String? reading;
  final String dataJson;
  const DictionaryTermMetaEntry({
    required this.id,
    required this.dictionaryId,
    required this.headword,
    required this.mode,
    this.reading,
    required this.dataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<String>(dictionaryId);
    map['headword'] = Variable<String>(headword);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || reading != null) {
      map['reading'] = Variable<String>(reading);
    }
    map['data_json'] = Variable<String>(dataJson);
    return map;
  }

  DictionaryTermMetaEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryTermMetaEntriesCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      headword: Value(headword),
      mode: Value(mode),
      reading: reading == null && nullToAbsent
          ? const Value.absent()
          : Value(reading),
      dataJson: Value(dataJson),
    );
  }

  factory DictionaryTermMetaEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryTermMetaEntry(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<String>(json['dictionaryId']),
      headword: serializer.fromJson<String>(json['headword']),
      mode: serializer.fromJson<String>(json['mode']),
      reading: serializer.fromJson<String?>(json['reading']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<String>(dictionaryId),
      'headword': serializer.toJson<String>(headword),
      'mode': serializer.toJson<String>(mode),
      'reading': serializer.toJson<String?>(reading),
      'dataJson': serializer.toJson<String>(dataJson),
    };
  }

  DictionaryTermMetaEntry copyWith({
    int? id,
    String? dictionaryId,
    String? headword,
    String? mode,
    Value<String?> reading = const Value.absent(),
    String? dataJson,
  }) => DictionaryTermMetaEntry(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    headword: headword ?? this.headword,
    mode: mode ?? this.mode,
    reading: reading.present ? reading.value : this.reading,
    dataJson: dataJson ?? this.dataJson,
  );
  DictionaryTermMetaEntry copyWithCompanion(
    DictionaryTermMetaEntriesCompanion data,
  ) {
    return DictionaryTermMetaEntry(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      headword: data.headword.present ? data.headword.value : this.headword,
      mode: data.mode.present ? data.mode.value : this.mode,
      reading: data.reading.present ? data.reading.value : this.reading,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTermMetaEntry(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('mode: $mode, ')
          ..write('reading: $reading, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dictionaryId, headword, mode, reading, dataJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryTermMetaEntry &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.headword == this.headword &&
          other.mode == this.mode &&
          other.reading == this.reading &&
          other.dataJson == this.dataJson);
}

class DictionaryTermMetaEntriesCompanion
    extends UpdateCompanion<DictionaryTermMetaEntry> {
  final Value<int> id;
  final Value<String> dictionaryId;
  final Value<String> headword;
  final Value<String> mode;
  final Value<String?> reading;
  final Value<String> dataJson;
  const DictionaryTermMetaEntriesCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.headword = const Value.absent(),
    this.mode = const Value.absent(),
    this.reading = const Value.absent(),
    this.dataJson = const Value.absent(),
  });
  DictionaryTermMetaEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String dictionaryId,
    required String headword,
    required String mode,
    this.reading = const Value.absent(),
    required String dataJson,
  }) : dictionaryId = Value(dictionaryId),
       headword = Value(headword),
       mode = Value(mode),
       dataJson = Value(dataJson);
  static Insertable<DictionaryTermMetaEntry> custom({
    Expression<int>? id,
    Expression<String>? dictionaryId,
    Expression<String>? headword,
    Expression<String>? mode,
    Expression<String>? reading,
    Expression<String>? dataJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (headword != null) 'headword': headword,
      if (mode != null) 'mode': mode,
      if (reading != null) 'reading': reading,
      if (dataJson != null) 'data_json': dataJson,
    });
  }

  DictionaryTermMetaEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? dictionaryId,
    Value<String>? headword,
    Value<String>? mode,
    Value<String?>? reading,
    Value<String>? dataJson,
  }) {
    return DictionaryTermMetaEntriesCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      headword: headword ?? this.headword,
      mode: mode ?? this.mode,
      reading: reading ?? this.reading,
      dataJson: dataJson ?? this.dataJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<String>(dictionaryId.value);
    }
    if (headword.present) {
      map['headword'] = Variable<String>(headword.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryTermMetaEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('mode: $mode, ')
          ..write('reading: $reading, ')
          ..write('dataJson: $dataJson')
          ..write(')'))
        .toString();
  }
}

class $CollectedWordsTable extends CollectedWords
    with TableInfo<$CollectedWordsTable, CollectedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectedWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dictFormMeta = const VerificationMeta(
    'dictForm',
  );
  @override
  late final GeneratedColumn<String> dictForm = GeneratedColumn<String>(
    'dict_form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senseIdsJsonMeta = const VerificationMeta(
    'senseIdsJson',
  );
  @override
  late final GeneratedColumn<String> senseIdsJson = GeneratedColumn<String>(
    'sense_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fsrsDifficultyMeta = const VerificationMeta(
    'fsrsDifficulty',
  );
  @override
  late final GeneratedColumn<double> fsrsDifficulty = GeneratedColumn<double>(
    'fsrs_difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsStabilityMeta = const VerificationMeta(
    'fsrsStability',
  );
  @override
  late final GeneratedColumn<double> fsrsStability = GeneratedColumn<double>(
    'fsrs_stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _srsDueMeta = const VerificationMeta('srsDue');
  @override
  late final GeneratedColumn<DateTime> srsDue = GeneratedColumn<DateTime>(
    'srs_due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _srsLapsesMeta = const VerificationMeta(
    'srsLapses',
  );
  @override
  late final GeneratedColumn<int> srsLapses = GeneratedColumn<int>(
    'srs_lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _srsStatusMeta = const VerificationMeta(
    'srsStatus',
  );
  @override
  late final GeneratedColumn<String> srsStatus = GeneratedColumn<String>(
    'srs_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictForm,
    reading,
    senseIdsJson,
    addedAt,
    updatedAt,
    fsrsDifficulty,
    fsrsStability,
    srsDue,
    srsLapses,
    srsStatus,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collected_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dict_form')) {
      context.handle(
        _dictFormMeta,
        dictForm.isAcceptableOrUnknown(data['dict_form']!, _dictFormMeta),
      );
    } else if (isInserting) {
      context.missing(_dictFormMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('sense_ids_json')) {
      context.handle(
        _senseIdsJsonMeta,
        senseIdsJson.isAcceptableOrUnknown(
          data['sense_ids_json']!,
          _senseIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senseIdsJsonMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fsrs_difficulty')) {
      context.handle(
        _fsrsDifficultyMeta,
        fsrsDifficulty.isAcceptableOrUnknown(
          data['fsrs_difficulty']!,
          _fsrsDifficultyMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_stability')) {
      context.handle(
        _fsrsStabilityMeta,
        fsrsStability.isAcceptableOrUnknown(
          data['fsrs_stability']!,
          _fsrsStabilityMeta,
        ),
      );
    }
    if (data.containsKey('srs_due')) {
      context.handle(
        _srsDueMeta,
        srsDue.isAcceptableOrUnknown(data['srs_due']!, _srsDueMeta),
      );
    } else if (isInserting) {
      context.missing(_srsDueMeta);
    }
    if (data.containsKey('srs_lapses')) {
      context.handle(
        _srsLapsesMeta,
        srsLapses.isAcceptableOrUnknown(data['srs_lapses']!, _srsLapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_srsLapsesMeta);
    }
    if (data.containsKey('srs_status')) {
      context.handle(
        _srsStatusMeta,
        srsStatus.isAcceptableOrUnknown(data['srs_status']!, _srsStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_srsStatusMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectedWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dictForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dict_form'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      senseIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sense_ids_json'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fsrsDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_difficulty'],
      ),
      fsrsStability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_stability'],
      ),
      srsDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}srs_due'],
      )!,
      srsLapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}srs_lapses'],
      )!,
      srsStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}srs_status'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
    );
  }

  @override
  $CollectedWordsTable createAlias(String alias) {
    return $CollectedWordsTable(attachedDatabase, alias);
  }
}

class CollectedWord extends DataClass implements Insertable<CollectedWord> {
  final String id;
  final String dictForm;
  final String reading;

  /// JSON-encoded `List<int>` of `DictionaryTermEntry.id`s (spec §11) this
  /// collection came from. Not independently queryable the way
  /// `sourceRefs` needs to be, so JSON is fine here. Set on a fresh add;
  /// deliberately left untouched by a reset-tap (spec §6's re-tap only
  /// appends a sighting and resets SRS state).
  final String senseIdsJson;
  final DateTime addedAt;
  final DateTime updatedAt;

  /// Real FSRS memory state (spec §12, `lib/l5_srs/fsrs/fsrs_scheduler.dart`)
  /// -- null together with [stability]/[lastReviewedAt] exactly when
  /// [srsStatus] is `newCard` (never reviewed yet). Replaced the earlier
  /// SM-2-shaped `srsInterval`/`srsEase` placeholder columns in a
  /// schemaVersion 2->3 migration once the real FSRS scheduler existed to
  /// populate them -- see `database.dart`'s `migration` override.
  final double? fsrsDifficulty;
  final double? fsrsStability;
  final DateTime srsDue;
  final int srsLapses;
  final String srsStatus;
  final DateTime? lastReviewedAt;
  const CollectedWord({
    required this.id,
    required this.dictForm,
    required this.reading,
    required this.senseIdsJson,
    required this.addedAt,
    required this.updatedAt,
    this.fsrsDifficulty,
    this.fsrsStability,
    required this.srsDue,
    required this.srsLapses,
    required this.srsStatus,
    this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dict_form'] = Variable<String>(dictForm);
    map['reading'] = Variable<String>(reading);
    map['sense_ids_json'] = Variable<String>(senseIdsJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || fsrsDifficulty != null) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty);
    }
    if (!nullToAbsent || fsrsStability != null) {
      map['fsrs_stability'] = Variable<double>(fsrsStability);
    }
    map['srs_due'] = Variable<DateTime>(srsDue);
    map['srs_lapses'] = Variable<int>(srsLapses);
    map['srs_status'] = Variable<String>(srsStatus);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    return map;
  }

  CollectedWordsCompanion toCompanion(bool nullToAbsent) {
    return CollectedWordsCompanion(
      id: Value(id),
      dictForm: Value(dictForm),
      reading: Value(reading),
      senseIdsJson: Value(senseIdsJson),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      fsrsDifficulty: fsrsDifficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDifficulty),
      fsrsStability: fsrsStability == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStability),
      srsDue: Value(srsDue),
      srsLapses: Value(srsLapses),
      srsStatus: Value(srsStatus),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory CollectedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectedWord(
      id: serializer.fromJson<String>(json['id']),
      dictForm: serializer.fromJson<String>(json['dictForm']),
      reading: serializer.fromJson<String>(json['reading']),
      senseIdsJson: serializer.fromJson<String>(json['senseIdsJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fsrsDifficulty: serializer.fromJson<double?>(json['fsrsDifficulty']),
      fsrsStability: serializer.fromJson<double?>(json['fsrsStability']),
      srsDue: serializer.fromJson<DateTime>(json['srsDue']),
      srsLapses: serializer.fromJson<int>(json['srsLapses']),
      srsStatus: serializer.fromJson<String>(json['srsStatus']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dictForm': serializer.toJson<String>(dictForm),
      'reading': serializer.toJson<String>(reading),
      'senseIdsJson': serializer.toJson<String>(senseIdsJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fsrsDifficulty': serializer.toJson<double?>(fsrsDifficulty),
      'fsrsStability': serializer.toJson<double?>(fsrsStability),
      'srsDue': serializer.toJson<DateTime>(srsDue),
      'srsLapses': serializer.toJson<int>(srsLapses),
      'srsStatus': serializer.toJson<String>(srsStatus),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
    };
  }

  CollectedWord copyWith({
    String? id,
    String? dictForm,
    String? reading,
    String? senseIdsJson,
    DateTime? addedAt,
    DateTime? updatedAt,
    Value<double?> fsrsDifficulty = const Value.absent(),
    Value<double?> fsrsStability = const Value.absent(),
    DateTime? srsDue,
    int? srsLapses,
    String? srsStatus,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
  }) => CollectedWord(
    id: id ?? this.id,
    dictForm: dictForm ?? this.dictForm,
    reading: reading ?? this.reading,
    senseIdsJson: senseIdsJson ?? this.senseIdsJson,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fsrsDifficulty: fsrsDifficulty.present
        ? fsrsDifficulty.value
        : this.fsrsDifficulty,
    fsrsStability: fsrsStability.present
        ? fsrsStability.value
        : this.fsrsStability,
    srsDue: srsDue ?? this.srsDue,
    srsLapses: srsLapses ?? this.srsLapses,
    srsStatus: srsStatus ?? this.srsStatus,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
  );
  CollectedWord copyWithCompanion(CollectedWordsCompanion data) {
    return CollectedWord(
      id: data.id.present ? data.id.value : this.id,
      dictForm: data.dictForm.present ? data.dictForm.value : this.dictForm,
      reading: data.reading.present ? data.reading.value : this.reading,
      senseIdsJson: data.senseIdsJson.present
          ? data.senseIdsJson.value
          : this.senseIdsJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fsrsDifficulty: data.fsrsDifficulty.present
          ? data.fsrsDifficulty.value
          : this.fsrsDifficulty,
      fsrsStability: data.fsrsStability.present
          ? data.fsrsStability.value
          : this.fsrsStability,
      srsDue: data.srsDue.present ? data.srsDue.value : this.srsDue,
      srsLapses: data.srsLapses.present ? data.srsLapses.value : this.srsLapses,
      srsStatus: data.srsStatus.present ? data.srsStatus.value : this.srsStatus,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectedWord(')
          ..write('id: $id, ')
          ..write('dictForm: $dictForm, ')
          ..write('reading: $reading, ')
          ..write('senseIdsJson: $senseIdsJson, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('srsDue: $srsDue, ')
          ..write('srsLapses: $srsLapses, ')
          ..write('srsStatus: $srsStatus, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictForm,
    reading,
    senseIdsJson,
    addedAt,
    updatedAt,
    fsrsDifficulty,
    fsrsStability,
    srsDue,
    srsLapses,
    srsStatus,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectedWord &&
          other.id == this.id &&
          other.dictForm == this.dictForm &&
          other.reading == this.reading &&
          other.senseIdsJson == this.senseIdsJson &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.fsrsDifficulty == this.fsrsDifficulty &&
          other.fsrsStability == this.fsrsStability &&
          other.srsDue == this.srsDue &&
          other.srsLapses == this.srsLapses &&
          other.srsStatus == this.srsStatus &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class CollectedWordsCompanion extends UpdateCompanion<CollectedWord> {
  final Value<String> id;
  final Value<String> dictForm;
  final Value<String> reading;
  final Value<String> senseIdsJson;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<double?> fsrsDifficulty;
  final Value<double?> fsrsStability;
  final Value<DateTime> srsDue;
  final Value<int> srsLapses;
  final Value<String> srsStatus;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> rowid;
  const CollectedWordsCompanion({
    this.id = const Value.absent(),
    this.dictForm = const Value.absent(),
    this.reading = const Value.absent(),
    this.senseIdsJson = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.srsDue = const Value.absent(),
    this.srsLapses = const Value.absent(),
    this.srsStatus = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectedWordsCompanion.insert({
    required String id,
    required String dictForm,
    required String reading,
    required String senseIdsJson,
    required DateTime addedAt,
    required DateTime updatedAt,
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    required DateTime srsDue,
    required int srsLapses,
    required String srsStatus,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dictForm = Value(dictForm),
       reading = Value(reading),
       senseIdsJson = Value(senseIdsJson),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt),
       srsDue = Value(srsDue),
       srsLapses = Value(srsLapses),
       srsStatus = Value(srsStatus);
  static Insertable<CollectedWord> custom({
    Expression<String>? id,
    Expression<String>? dictForm,
    Expression<String>? reading,
    Expression<String>? senseIdsJson,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? fsrsDifficulty,
    Expression<double>? fsrsStability,
    Expression<DateTime>? srsDue,
    Expression<int>? srsLapses,
    Expression<String>? srsStatus,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictForm != null) 'dict_form': dictForm,
      if (reading != null) 'reading': reading,
      if (senseIdsJson != null) 'sense_ids_json': senseIdsJson,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fsrsDifficulty != null) 'fsrs_difficulty': fsrsDifficulty,
      if (fsrsStability != null) 'fsrs_stability': fsrsStability,
      if (srsDue != null) 'srs_due': srsDue,
      if (srsLapses != null) 'srs_lapses': srsLapses,
      if (srsStatus != null) 'srs_status': srsStatus,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectedWordsCompanion copyWith({
    Value<String>? id,
    Value<String>? dictForm,
    Value<String>? reading,
    Value<String>? senseIdsJson,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<double?>? fsrsDifficulty,
    Value<double?>? fsrsStability,
    Value<DateTime>? srsDue,
    Value<int>? srsLapses,
    Value<String>? srsStatus,
    Value<DateTime?>? lastReviewedAt,
    Value<int>? rowid,
  }) {
    return CollectedWordsCompanion(
      id: id ?? this.id,
      dictForm: dictForm ?? this.dictForm,
      reading: reading ?? this.reading,
      senseIdsJson: senseIdsJson ?? this.senseIdsJson,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
      fsrsStability: fsrsStability ?? this.fsrsStability,
      srsDue: srsDue ?? this.srsDue,
      srsLapses: srsLapses ?? this.srsLapses,
      srsStatus: srsStatus ?? this.srsStatus,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dictForm.present) {
      map['dict_form'] = Variable<String>(dictForm.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (senseIdsJson.present) {
      map['sense_ids_json'] = Variable<String>(senseIdsJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fsrsDifficulty.present) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty.value);
    }
    if (fsrsStability.present) {
      map['fsrs_stability'] = Variable<double>(fsrsStability.value);
    }
    if (srsDue.present) {
      map['srs_due'] = Variable<DateTime>(srsDue.value);
    }
    if (srsLapses.present) {
      map['srs_lapses'] = Variable<int>(srsLapses.value);
    }
    if (srsStatus.present) {
      map['srs_status'] = Variable<String>(srsStatus.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectedWordsCompanion(')
          ..write('id: $id, ')
          ..write('dictForm: $dictForm, ')
          ..write('reading: $reading, ')
          ..write('senseIdsJson: $senseIdsJson, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('srsDue: $srsDue, ')
          ..write('srsLapses: $srsLapses, ')
          ..write('srsStatus: $srsStatus, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectedWordSourcesTable extends CollectedWordSources
    with TableInfo<$CollectedWordSourcesTable, CollectedWordSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectedWordSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _collectedWordIdMeta = const VerificationMeta(
    'collectedWordId',
  );
  @override
  late final GeneratedColumn<String> collectedWordId = GeneratedColumn<String>(
    'collected_word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collected_words (id)',
    ),
  );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id)',
    ),
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<String> sentenceId = GeneratedColumn<String>(
    'sentence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sentences (id)',
    ),
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minedAtMeta = const VerificationMeta(
    'minedAt',
  );
  @override
  late final GeneratedColumn<DateTime> minedAt = GeneratedColumn<DateTime>(
    'mined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectedWordId,
    workId,
    sentenceId,
    mediaType,
    minedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collected_word_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectedWordSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collected_word_id')) {
      context.handle(
        _collectedWordIdMeta,
        collectedWordId.isAcceptableOrUnknown(
          data['collected_word_id']!,
          _collectedWordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedWordIdMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('mined_at')) {
      context.handle(
        _minedAtMeta,
        minedAt.isAcceptableOrUnknown(data['mined_at']!, _minedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_minedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectedWordSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectedWordSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectedWordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collected_word_id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      minedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mined_at'],
      )!,
    );
  }

  @override
  $CollectedWordSourcesTable createAlias(String alias) {
    return $CollectedWordSourcesTable(attachedDatabase, alias);
  }
}

class CollectedWordSource extends DataClass
    implements Insertable<CollectedWordSource> {
  final int id;
  final String collectedWordId;
  final String workId;
  final String sentenceId;

  /// `CollectionMediaType.name` (lib/l4_mining/collection/source_ref.dart) --
  /// deliberately not `DocumentSourceType`; see that enum's doc comment.
  final String mediaType;
  final DateTime minedAt;
  const CollectedWordSource({
    required this.id,
    required this.collectedWordId,
    required this.workId,
    required this.sentenceId,
    required this.mediaType,
    required this.minedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collected_word_id'] = Variable<String>(collectedWordId);
    map['work_id'] = Variable<String>(workId);
    map['sentence_id'] = Variable<String>(sentenceId);
    map['media_type'] = Variable<String>(mediaType);
    map['mined_at'] = Variable<DateTime>(minedAt);
    return map;
  }

  CollectedWordSourcesCompanion toCompanion(bool nullToAbsent) {
    return CollectedWordSourcesCompanion(
      id: Value(id),
      collectedWordId: Value(collectedWordId),
      workId: Value(workId),
      sentenceId: Value(sentenceId),
      mediaType: Value(mediaType),
      minedAt: Value(minedAt),
    );
  }

  factory CollectedWordSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectedWordSource(
      id: serializer.fromJson<int>(json['id']),
      collectedWordId: serializer.fromJson<String>(json['collectedWordId']),
      workId: serializer.fromJson<String>(json['workId']),
      sentenceId: serializer.fromJson<String>(json['sentenceId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      minedAt: serializer.fromJson<DateTime>(json['minedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectedWordId': serializer.toJson<String>(collectedWordId),
      'workId': serializer.toJson<String>(workId),
      'sentenceId': serializer.toJson<String>(sentenceId),
      'mediaType': serializer.toJson<String>(mediaType),
      'minedAt': serializer.toJson<DateTime>(minedAt),
    };
  }

  CollectedWordSource copyWith({
    int? id,
    String? collectedWordId,
    String? workId,
    String? sentenceId,
    String? mediaType,
    DateTime? minedAt,
  }) => CollectedWordSource(
    id: id ?? this.id,
    collectedWordId: collectedWordId ?? this.collectedWordId,
    workId: workId ?? this.workId,
    sentenceId: sentenceId ?? this.sentenceId,
    mediaType: mediaType ?? this.mediaType,
    minedAt: minedAt ?? this.minedAt,
  );
  CollectedWordSource copyWithCompanion(CollectedWordSourcesCompanion data) {
    return CollectedWordSource(
      id: data.id.present ? data.id.value : this.id,
      collectedWordId: data.collectedWordId.present
          ? data.collectedWordId.value
          : this.collectedWordId,
      workId: data.workId.present ? data.workId.value : this.workId,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      minedAt: data.minedAt.present ? data.minedAt.value : this.minedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectedWordSource(')
          ..write('id: $id, ')
          ..write('collectedWordId: $collectedWordId, ')
          ..write('workId: $workId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('minedAt: $minedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, collectedWordId, workId, sentenceId, mediaType, minedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectedWordSource &&
          other.id == this.id &&
          other.collectedWordId == this.collectedWordId &&
          other.workId == this.workId &&
          other.sentenceId == this.sentenceId &&
          other.mediaType == this.mediaType &&
          other.minedAt == this.minedAt);
}

class CollectedWordSourcesCompanion
    extends UpdateCompanion<CollectedWordSource> {
  final Value<int> id;
  final Value<String> collectedWordId;
  final Value<String> workId;
  final Value<String> sentenceId;
  final Value<String> mediaType;
  final Value<DateTime> minedAt;
  const CollectedWordSourcesCompanion({
    this.id = const Value.absent(),
    this.collectedWordId = const Value.absent(),
    this.workId = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.minedAt = const Value.absent(),
  });
  CollectedWordSourcesCompanion.insert({
    this.id = const Value.absent(),
    required String collectedWordId,
    required String workId,
    required String sentenceId,
    required String mediaType,
    required DateTime minedAt,
  }) : collectedWordId = Value(collectedWordId),
       workId = Value(workId),
       sentenceId = Value(sentenceId),
       mediaType = Value(mediaType),
       minedAt = Value(minedAt);
  static Insertable<CollectedWordSource> custom({
    Expression<int>? id,
    Expression<String>? collectedWordId,
    Expression<String>? workId,
    Expression<String>? sentenceId,
    Expression<String>? mediaType,
    Expression<DateTime>? minedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectedWordId != null) 'collected_word_id': collectedWordId,
      if (workId != null) 'work_id': workId,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (mediaType != null) 'media_type': mediaType,
      if (minedAt != null) 'mined_at': minedAt,
    });
  }

  CollectedWordSourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? collectedWordId,
    Value<String>? workId,
    Value<String>? sentenceId,
    Value<String>? mediaType,
    Value<DateTime>? minedAt,
  }) {
    return CollectedWordSourcesCompanion(
      id: id ?? this.id,
      collectedWordId: collectedWordId ?? this.collectedWordId,
      workId: workId ?? this.workId,
      sentenceId: sentenceId ?? this.sentenceId,
      mediaType: mediaType ?? this.mediaType,
      minedAt: minedAt ?? this.minedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectedWordId.present) {
      map['collected_word_id'] = Variable<String>(collectedWordId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<String>(sentenceId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (minedAt.present) {
      map['mined_at'] = Variable<DateTime>(minedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectedWordSourcesCompanion(')
          ..write('id: $id, ')
          ..write('collectedWordId: $collectedWordId, ')
          ..write('workId: $workId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('minedAt: $minedAt')
          ..write(')'))
        .toString();
  }
}

class $CollectedGrammarsTable extends CollectedGrammars
    with TableInfo<$CollectedGrammarsTable, CollectedGrammar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectedGrammarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grammarPointIdMeta = const VerificationMeta(
    'grammarPointId',
  );
  @override
  late final GeneratedColumn<String> grammarPointId = GeneratedColumn<String>(
    'grammar_point_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fsrsDifficultyMeta = const VerificationMeta(
    'fsrsDifficulty',
  );
  @override
  late final GeneratedColumn<double> fsrsDifficulty = GeneratedColumn<double>(
    'fsrs_difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsStabilityMeta = const VerificationMeta(
    'fsrsStability',
  );
  @override
  late final GeneratedColumn<double> fsrsStability = GeneratedColumn<double>(
    'fsrs_stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _srsDueMeta = const VerificationMeta('srsDue');
  @override
  late final GeneratedColumn<DateTime> srsDue = GeneratedColumn<DateTime>(
    'srs_due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _srsLapsesMeta = const VerificationMeta(
    'srsLapses',
  );
  @override
  late final GeneratedColumn<int> srsLapses = GeneratedColumn<int>(
    'srs_lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _srsStatusMeta = const VerificationMeta(
    'srsStatus',
  );
  @override
  late final GeneratedColumn<String> srsStatus = GeneratedColumn<String>(
    'srs_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    grammarPointId,
    addedAt,
    updatedAt,
    fsrsDifficulty,
    fsrsStability,
    srsDue,
    srsLapses,
    lastReviewedAt,
    srsStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collected_grammars';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectedGrammar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('grammar_point_id')) {
      context.handle(
        _grammarPointIdMeta,
        grammarPointId.isAcceptableOrUnknown(
          data['grammar_point_id']!,
          _grammarPointIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grammarPointIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fsrs_difficulty')) {
      context.handle(
        _fsrsDifficultyMeta,
        fsrsDifficulty.isAcceptableOrUnknown(
          data['fsrs_difficulty']!,
          _fsrsDifficultyMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_stability')) {
      context.handle(
        _fsrsStabilityMeta,
        fsrsStability.isAcceptableOrUnknown(
          data['fsrs_stability']!,
          _fsrsStabilityMeta,
        ),
      );
    }
    if (data.containsKey('srs_due')) {
      context.handle(
        _srsDueMeta,
        srsDue.isAcceptableOrUnknown(data['srs_due']!, _srsDueMeta),
      );
    } else if (isInserting) {
      context.missing(_srsDueMeta);
    }
    if (data.containsKey('srs_lapses')) {
      context.handle(
        _srsLapsesMeta,
        srsLapses.isAcceptableOrUnknown(data['srs_lapses']!, _srsLapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_srsLapsesMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('srs_status')) {
      context.handle(
        _srsStatusMeta,
        srsStatus.isAcceptableOrUnknown(data['srs_status']!, _srsStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_srsStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectedGrammar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectedGrammar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      grammarPointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grammar_point_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fsrsDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_difficulty'],
      ),
      fsrsStability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_stability'],
      ),
      srsDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}srs_due'],
      )!,
      srsLapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}srs_lapses'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      srsStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}srs_status'],
      )!,
    );
  }

  @override
  $CollectedGrammarsTable createAlias(String alias) {
    return $CollectedGrammarsTable(attachedDatabase, alias);
  }
}

class CollectedGrammar extends DataClass
    implements Insertable<CollectedGrammar> {
  final String id;
  final String grammarPointId;
  final DateTime addedAt;
  final DateTime updatedAt;

  /// See `CollectedWords.fsrsDifficulty`'s doc comment -- identical
  /// reasoning, grammar-side mirror.
  final double? fsrsDifficulty;
  final double? fsrsStability;
  final DateTime srsDue;
  final int srsLapses;
  final DateTime? lastReviewedAt;
  final String srsStatus;
  const CollectedGrammar({
    required this.id,
    required this.grammarPointId,
    required this.addedAt,
    required this.updatedAt,
    this.fsrsDifficulty,
    this.fsrsStability,
    required this.srsDue,
    required this.srsLapses,
    this.lastReviewedAt,
    required this.srsStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['grammar_point_id'] = Variable<String>(grammarPointId);
    map['added_at'] = Variable<DateTime>(addedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || fsrsDifficulty != null) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty);
    }
    if (!nullToAbsent || fsrsStability != null) {
      map['fsrs_stability'] = Variable<double>(fsrsStability);
    }
    map['srs_due'] = Variable<DateTime>(srsDue);
    map['srs_lapses'] = Variable<int>(srsLapses);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['srs_status'] = Variable<String>(srsStatus);
    return map;
  }

  CollectedGrammarsCompanion toCompanion(bool nullToAbsent) {
    return CollectedGrammarsCompanion(
      id: Value(id),
      grammarPointId: Value(grammarPointId),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      fsrsDifficulty: fsrsDifficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDifficulty),
      fsrsStability: fsrsStability == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStability),
      srsDue: Value(srsDue),
      srsLapses: Value(srsLapses),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      srsStatus: Value(srsStatus),
    );
  }

  factory CollectedGrammar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectedGrammar(
      id: serializer.fromJson<String>(json['id']),
      grammarPointId: serializer.fromJson<String>(json['grammarPointId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fsrsDifficulty: serializer.fromJson<double?>(json['fsrsDifficulty']),
      fsrsStability: serializer.fromJson<double?>(json['fsrsStability']),
      srsDue: serializer.fromJson<DateTime>(json['srsDue']),
      srsLapses: serializer.fromJson<int>(json['srsLapses']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      srsStatus: serializer.fromJson<String>(json['srsStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'grammarPointId': serializer.toJson<String>(grammarPointId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fsrsDifficulty': serializer.toJson<double?>(fsrsDifficulty),
      'fsrsStability': serializer.toJson<double?>(fsrsStability),
      'srsDue': serializer.toJson<DateTime>(srsDue),
      'srsLapses': serializer.toJson<int>(srsLapses),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'srsStatus': serializer.toJson<String>(srsStatus),
    };
  }

  CollectedGrammar copyWith({
    String? id,
    String? grammarPointId,
    DateTime? addedAt,
    DateTime? updatedAt,
    Value<double?> fsrsDifficulty = const Value.absent(),
    Value<double?> fsrsStability = const Value.absent(),
    DateTime? srsDue,
    int? srsLapses,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    String? srsStatus,
  }) => CollectedGrammar(
    id: id ?? this.id,
    grammarPointId: grammarPointId ?? this.grammarPointId,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fsrsDifficulty: fsrsDifficulty.present
        ? fsrsDifficulty.value
        : this.fsrsDifficulty,
    fsrsStability: fsrsStability.present
        ? fsrsStability.value
        : this.fsrsStability,
    srsDue: srsDue ?? this.srsDue,
    srsLapses: srsLapses ?? this.srsLapses,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    srsStatus: srsStatus ?? this.srsStatus,
  );
  CollectedGrammar copyWithCompanion(CollectedGrammarsCompanion data) {
    return CollectedGrammar(
      id: data.id.present ? data.id.value : this.id,
      grammarPointId: data.grammarPointId.present
          ? data.grammarPointId.value
          : this.grammarPointId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fsrsDifficulty: data.fsrsDifficulty.present
          ? data.fsrsDifficulty.value
          : this.fsrsDifficulty,
      fsrsStability: data.fsrsStability.present
          ? data.fsrsStability.value
          : this.fsrsStability,
      srsDue: data.srsDue.present ? data.srsDue.value : this.srsDue,
      srsLapses: data.srsLapses.present ? data.srsLapses.value : this.srsLapses,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      srsStatus: data.srsStatus.present ? data.srsStatus.value : this.srsStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectedGrammar(')
          ..write('id: $id, ')
          ..write('grammarPointId: $grammarPointId, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('srsDue: $srsDue, ')
          ..write('srsLapses: $srsLapses, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('srsStatus: $srsStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    grammarPointId,
    addedAt,
    updatedAt,
    fsrsDifficulty,
    fsrsStability,
    srsDue,
    srsLapses,
    lastReviewedAt,
    srsStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectedGrammar &&
          other.id == this.id &&
          other.grammarPointId == this.grammarPointId &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.fsrsDifficulty == this.fsrsDifficulty &&
          other.fsrsStability == this.fsrsStability &&
          other.srsDue == this.srsDue &&
          other.srsLapses == this.srsLapses &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.srsStatus == this.srsStatus);
}

class CollectedGrammarsCompanion extends UpdateCompanion<CollectedGrammar> {
  final Value<String> id;
  final Value<String> grammarPointId;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<double?> fsrsDifficulty;
  final Value<double?> fsrsStability;
  final Value<DateTime> srsDue;
  final Value<int> srsLapses;
  final Value<DateTime?> lastReviewedAt;
  final Value<String> srsStatus;
  final Value<int> rowid;
  const CollectedGrammarsCompanion({
    this.id = const Value.absent(),
    this.grammarPointId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.srsDue = const Value.absent(),
    this.srsLapses = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.srsStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectedGrammarsCompanion.insert({
    required String id,
    required String grammarPointId,
    required DateTime addedAt,
    required DateTime updatedAt,
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    required DateTime srsDue,
    required int srsLapses,
    this.lastReviewedAt = const Value.absent(),
    required String srsStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       grammarPointId = Value(grammarPointId),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt),
       srsDue = Value(srsDue),
       srsLapses = Value(srsLapses),
       srsStatus = Value(srsStatus);
  static Insertable<CollectedGrammar> custom({
    Expression<String>? id,
    Expression<String>? grammarPointId,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? fsrsDifficulty,
    Expression<double>? fsrsStability,
    Expression<DateTime>? srsDue,
    Expression<int>? srsLapses,
    Expression<DateTime>? lastReviewedAt,
    Expression<String>? srsStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (grammarPointId != null) 'grammar_point_id': grammarPointId,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fsrsDifficulty != null) 'fsrs_difficulty': fsrsDifficulty,
      if (fsrsStability != null) 'fsrs_stability': fsrsStability,
      if (srsDue != null) 'srs_due': srsDue,
      if (srsLapses != null) 'srs_lapses': srsLapses,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (srsStatus != null) 'srs_status': srsStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectedGrammarsCompanion copyWith({
    Value<String>? id,
    Value<String>? grammarPointId,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<double?>? fsrsDifficulty,
    Value<double?>? fsrsStability,
    Value<DateTime>? srsDue,
    Value<int>? srsLapses,
    Value<DateTime?>? lastReviewedAt,
    Value<String>? srsStatus,
    Value<int>? rowid,
  }) {
    return CollectedGrammarsCompanion(
      id: id ?? this.id,
      grammarPointId: grammarPointId ?? this.grammarPointId,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
      fsrsStability: fsrsStability ?? this.fsrsStability,
      srsDue: srsDue ?? this.srsDue,
      srsLapses: srsLapses ?? this.srsLapses,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      srsStatus: srsStatus ?? this.srsStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (grammarPointId.present) {
      map['grammar_point_id'] = Variable<String>(grammarPointId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fsrsDifficulty.present) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty.value);
    }
    if (fsrsStability.present) {
      map['fsrs_stability'] = Variable<double>(fsrsStability.value);
    }
    if (srsDue.present) {
      map['srs_due'] = Variable<DateTime>(srsDue.value);
    }
    if (srsLapses.present) {
      map['srs_lapses'] = Variable<int>(srsLapses.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (srsStatus.present) {
      map['srs_status'] = Variable<String>(srsStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectedGrammarsCompanion(')
          ..write('id: $id, ')
          ..write('grammarPointId: $grammarPointId, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('srsDue: $srsDue, ')
          ..write('srsLapses: $srsLapses, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('srsStatus: $srsStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectedGrammarSourcesTable extends CollectedGrammarSources
    with TableInfo<$CollectedGrammarSourcesTable, CollectedGrammarSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectedGrammarSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _collectedGrammarIdMeta =
      const VerificationMeta('collectedGrammarId');
  @override
  late final GeneratedColumn<String> collectedGrammarId =
      GeneratedColumn<String>(
        'collected_grammar_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES collected_grammars (id)',
        ),
      );
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id)',
    ),
  );
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<String> sentenceId = GeneratedColumn<String>(
    'sentence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sentences (id)',
    ),
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minedAtMeta = const VerificationMeta(
    'minedAt',
  );
  @override
  late final GeneratedColumn<DateTime> minedAt = GeneratedColumn<DateTime>(
    'mined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectedGrammarId,
    workId,
    sentenceId,
    mediaType,
    minedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collected_grammar_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectedGrammarSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collected_grammar_id')) {
      context.handle(
        _collectedGrammarIdMeta,
        collectedGrammarId.isAcceptableOrUnknown(
          data['collected_grammar_id']!,
          _collectedGrammarIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectedGrammarIdMeta);
    }
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('mined_at')) {
      context.handle(
        _minedAtMeta,
        minedAt.isAcceptableOrUnknown(data['mined_at']!, _minedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_minedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectedGrammarSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectedGrammarSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collectedGrammarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collected_grammar_id'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      minedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mined_at'],
      )!,
    );
  }

  @override
  $CollectedGrammarSourcesTable createAlias(String alias) {
    return $CollectedGrammarSourcesTable(attachedDatabase, alias);
  }
}

class CollectedGrammarSource extends DataClass
    implements Insertable<CollectedGrammarSource> {
  final int id;
  final String collectedGrammarId;
  final String workId;
  final String sentenceId;
  final String mediaType;
  final DateTime minedAt;
  const CollectedGrammarSource({
    required this.id,
    required this.collectedGrammarId,
    required this.workId,
    required this.sentenceId,
    required this.mediaType,
    required this.minedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collected_grammar_id'] = Variable<String>(collectedGrammarId);
    map['work_id'] = Variable<String>(workId);
    map['sentence_id'] = Variable<String>(sentenceId);
    map['media_type'] = Variable<String>(mediaType);
    map['mined_at'] = Variable<DateTime>(minedAt);
    return map;
  }

  CollectedGrammarSourcesCompanion toCompanion(bool nullToAbsent) {
    return CollectedGrammarSourcesCompanion(
      id: Value(id),
      collectedGrammarId: Value(collectedGrammarId),
      workId: Value(workId),
      sentenceId: Value(sentenceId),
      mediaType: Value(mediaType),
      minedAt: Value(minedAt),
    );
  }

  factory CollectedGrammarSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectedGrammarSource(
      id: serializer.fromJson<int>(json['id']),
      collectedGrammarId: serializer.fromJson<String>(
        json['collectedGrammarId'],
      ),
      workId: serializer.fromJson<String>(json['workId']),
      sentenceId: serializer.fromJson<String>(json['sentenceId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      minedAt: serializer.fromJson<DateTime>(json['minedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectedGrammarId': serializer.toJson<String>(collectedGrammarId),
      'workId': serializer.toJson<String>(workId),
      'sentenceId': serializer.toJson<String>(sentenceId),
      'mediaType': serializer.toJson<String>(mediaType),
      'minedAt': serializer.toJson<DateTime>(minedAt),
    };
  }

  CollectedGrammarSource copyWith({
    int? id,
    String? collectedGrammarId,
    String? workId,
    String? sentenceId,
    String? mediaType,
    DateTime? minedAt,
  }) => CollectedGrammarSource(
    id: id ?? this.id,
    collectedGrammarId: collectedGrammarId ?? this.collectedGrammarId,
    workId: workId ?? this.workId,
    sentenceId: sentenceId ?? this.sentenceId,
    mediaType: mediaType ?? this.mediaType,
    minedAt: minedAt ?? this.minedAt,
  );
  CollectedGrammarSource copyWithCompanion(
    CollectedGrammarSourcesCompanion data,
  ) {
    return CollectedGrammarSource(
      id: data.id.present ? data.id.value : this.id,
      collectedGrammarId: data.collectedGrammarId.present
          ? data.collectedGrammarId.value
          : this.collectedGrammarId,
      workId: data.workId.present ? data.workId.value : this.workId,
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      minedAt: data.minedAt.present ? data.minedAt.value : this.minedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectedGrammarSource(')
          ..write('id: $id, ')
          ..write('collectedGrammarId: $collectedGrammarId, ')
          ..write('workId: $workId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('minedAt: $minedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectedGrammarId,
    workId,
    sentenceId,
    mediaType,
    minedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectedGrammarSource &&
          other.id == this.id &&
          other.collectedGrammarId == this.collectedGrammarId &&
          other.workId == this.workId &&
          other.sentenceId == this.sentenceId &&
          other.mediaType == this.mediaType &&
          other.minedAt == this.minedAt);
}

class CollectedGrammarSourcesCompanion
    extends UpdateCompanion<CollectedGrammarSource> {
  final Value<int> id;
  final Value<String> collectedGrammarId;
  final Value<String> workId;
  final Value<String> sentenceId;
  final Value<String> mediaType;
  final Value<DateTime> minedAt;
  const CollectedGrammarSourcesCompanion({
    this.id = const Value.absent(),
    this.collectedGrammarId = const Value.absent(),
    this.workId = const Value.absent(),
    this.sentenceId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.minedAt = const Value.absent(),
  });
  CollectedGrammarSourcesCompanion.insert({
    this.id = const Value.absent(),
    required String collectedGrammarId,
    required String workId,
    required String sentenceId,
    required String mediaType,
    required DateTime minedAt,
  }) : collectedGrammarId = Value(collectedGrammarId),
       workId = Value(workId),
       sentenceId = Value(sentenceId),
       mediaType = Value(mediaType),
       minedAt = Value(minedAt);
  static Insertable<CollectedGrammarSource> custom({
    Expression<int>? id,
    Expression<String>? collectedGrammarId,
    Expression<String>? workId,
    Expression<String>? sentenceId,
    Expression<String>? mediaType,
    Expression<DateTime>? minedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectedGrammarId != null)
        'collected_grammar_id': collectedGrammarId,
      if (workId != null) 'work_id': workId,
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (mediaType != null) 'media_type': mediaType,
      if (minedAt != null) 'mined_at': minedAt,
    });
  }

  CollectedGrammarSourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? collectedGrammarId,
    Value<String>? workId,
    Value<String>? sentenceId,
    Value<String>? mediaType,
    Value<DateTime>? minedAt,
  }) {
    return CollectedGrammarSourcesCompanion(
      id: id ?? this.id,
      collectedGrammarId: collectedGrammarId ?? this.collectedGrammarId,
      workId: workId ?? this.workId,
      sentenceId: sentenceId ?? this.sentenceId,
      mediaType: mediaType ?? this.mediaType,
      minedAt: minedAt ?? this.minedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectedGrammarId.present) {
      map['collected_grammar_id'] = Variable<String>(collectedGrammarId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (sentenceId.present) {
      map['sentence_id'] = Variable<String>(sentenceId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (minedAt.present) {
      map['mined_at'] = Variable<DateTime>(minedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectedGrammarSourcesCompanion(')
          ..write('id: $id, ')
          ..write('collectedGrammarId: $collectedGrammarId, ')
          ..write('workId: $workId, ')
          ..write('sentenceId: $sentenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('minedAt: $minedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _llmApiKeyMeta = const VerificationMeta(
    'llmApiKey',
  );
  @override
  late final GeneratedColumn<String> llmApiKey = GeneratedColumn<String>(
    'llm_api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _llmExplanationsEnabledMeta =
      const VerificationMeta('llmExplanationsEnabled');
  @override
  late final GeneratedColumn<bool> llmExplanationsEnabled =
      GeneratedColumn<bool>(
        'llm_explanations_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("llm_explanations_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  @override
  List<GeneratedColumn> get $columns => [id, llmApiKey, llmExplanationsEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('llm_api_key')) {
      context.handle(
        _llmApiKeyMeta,
        llmApiKey.isAcceptableOrUnknown(data['llm_api_key']!, _llmApiKeyMeta),
      );
    }
    if (data.containsKey('llm_explanations_enabled')) {
      context.handle(
        _llmExplanationsEnabledMeta,
        llmExplanationsEnabled.isAcceptableOrUnknown(
          data['llm_explanations_enabled']!,
          _llmExplanationsEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      llmApiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}llm_api_key'],
      ),
      llmExplanationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}llm_explanations_enabled'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;

  /// The user's own Anthropic API key (spec §14: "LLM — API key entry"; spec
  /// §2: "BYO", no hosted proxy). Stored in the same local SQLite database
  /// as everything else in this local-first app -- not OS keychain/secure
  /// storage, matching this project's own "local-first, no account, no
  /// cloud" posture; a future pass could move this to a platform secure-
  /// storage API without changing any caller of [SettingsRepository], only
  /// this column's own storage.
  final String? llmApiKey;

  /// Spec §14: "grammar-explanation on/off". Defaults on: layer 3 is meant
  /// to be additive/optional (spec §8: "already fully usable without it"),
  /// so the only real gate on whether it actually runs is whether an API key
  /// is present, not this toggle needing an extra opt-in step too.
  final bool llmExplanationsEnabled;
  const SettingsRow({
    required this.id,
    this.llmApiKey,
    required this.llmExplanationsEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || llmApiKey != null) {
      map['llm_api_key'] = Variable<String>(llmApiKey);
    }
    map['llm_explanations_enabled'] = Variable<bool>(llmExplanationsEnabled);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      llmApiKey: llmApiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(llmApiKey),
      llmExplanationsEnabled: Value(llmExplanationsEnabled),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      llmApiKey: serializer.fromJson<String?>(json['llmApiKey']),
      llmExplanationsEnabled: serializer.fromJson<bool>(
        json['llmExplanationsEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'llmApiKey': serializer.toJson<String?>(llmApiKey),
      'llmExplanationsEnabled': serializer.toJson<bool>(llmExplanationsEnabled),
    };
  }

  SettingsRow copyWith({
    int? id,
    Value<String?> llmApiKey = const Value.absent(),
    bool? llmExplanationsEnabled,
  }) => SettingsRow(
    id: id ?? this.id,
    llmApiKey: llmApiKey.present ? llmApiKey.value : this.llmApiKey,
    llmExplanationsEnabled:
        llmExplanationsEnabled ?? this.llmExplanationsEnabled,
  );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      llmApiKey: data.llmApiKey.present ? data.llmApiKey.value : this.llmApiKey,
      llmExplanationsEnabled: data.llmExplanationsEnabled.present
          ? data.llmExplanationsEnabled.value
          : this.llmExplanationsEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('llmApiKey: $llmApiKey, ')
          ..write('llmExplanationsEnabled: $llmExplanationsEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, llmApiKey, llmExplanationsEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.llmApiKey == this.llmApiKey &&
          other.llmExplanationsEnabled == this.llmExplanationsEnabled);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String?> llmApiKey;
  final Value<bool> llmExplanationsEnabled;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.llmApiKey = const Value.absent(),
    this.llmExplanationsEnabled = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.llmApiKey = const Value.absent(),
    this.llmExplanationsEnabled = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? llmApiKey,
    Expression<bool>? llmExplanationsEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (llmApiKey != null) 'llm_api_key': llmApiKey,
      if (llmExplanationsEnabled != null)
        'llm_explanations_enabled': llmExplanationsEnabled,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? llmApiKey,
    Value<bool>? llmExplanationsEnabled,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      llmExplanationsEnabled:
          llmExplanationsEnabled ?? this.llmExplanationsEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (llmApiKey.present) {
      map['llm_api_key'] = Variable<String>(llmApiKey.value);
    }
    if (llmExplanationsEnabled.present) {
      map['llm_explanations_enabled'] = Variable<bool>(
        llmExplanationsEnabled.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('llmApiKey: $llmApiKey, ')
          ..write('llmExplanationsEnabled: $llmExplanationsEnabled')
          ..write(')'))
        .toString();
  }
}

class $SentenceExplanationsTable extends SentenceExplanations
    with TableInfo<$SentenceExplanationsTable, SentenceExplanationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentenceExplanationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
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
  List<GeneratedColumn> get $columns => [id, explanation, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentence_explanations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentenceExplanationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
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
  SentenceExplanationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentenceExplanationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SentenceExplanationsTable createAlias(String alias) {
    return $SentenceExplanationsTable(attachedDatabase, alias);
  }
}

class SentenceExplanationRow extends DataClass
    implements Insertable<SentenceExplanationRow> {
  final String id;
  final String explanation;
  final DateTime createdAt;
  const SentenceExplanationRow({
    required this.id,
    required this.explanation,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['explanation'] = Variable<String>(explanation);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SentenceExplanationsCompanion toCompanion(bool nullToAbsent) {
    return SentenceExplanationsCompanion(
      id: Value(id),
      explanation: Value(explanation),
      createdAt: Value(createdAt),
    );
  }

  factory SentenceExplanationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentenceExplanationRow(
      id: serializer.fromJson<String>(json['id']),
      explanation: serializer.fromJson<String>(json['explanation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'explanation': serializer.toJson<String>(explanation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SentenceExplanationRow copyWith({
    String? id,
    String? explanation,
    DateTime? createdAt,
  }) => SentenceExplanationRow(
    id: id ?? this.id,
    explanation: explanation ?? this.explanation,
    createdAt: createdAt ?? this.createdAt,
  );
  SentenceExplanationRow copyWithCompanion(SentenceExplanationsCompanion data) {
    return SentenceExplanationRow(
      id: data.id.present ? data.id.value : this.id,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentenceExplanationRow(')
          ..write('id: $id, ')
          ..write('explanation: $explanation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, explanation, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentenceExplanationRow &&
          other.id == this.id &&
          other.explanation == this.explanation &&
          other.createdAt == this.createdAt);
}

class SentenceExplanationsCompanion
    extends UpdateCompanion<SentenceExplanationRow> {
  final Value<String> id;
  final Value<String> explanation;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SentenceExplanationsCompanion({
    this.id = const Value.absent(),
    this.explanation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentenceExplanationsCompanion.insert({
    required String id,
    required String explanation,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       explanation = Value(explanation),
       createdAt = Value(createdAt);
  static Insertable<SentenceExplanationRow> custom({
    Expression<String>? id,
    Expression<String>? explanation,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (explanation != null) 'explanation': explanation,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentenceExplanationsCompanion copyWith({
    Value<String>? id,
    Value<String>? explanation,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SentenceExplanationsCompanion(
      id: id ?? this.id,
      explanation: explanation ?? this.explanation,
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
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
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
    return (StringBuffer('SentenceExplanationsCompanion(')
          ..write('id: $id, ')
          ..write('explanation: $explanation, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $SentencesTable sentences = $SentencesTable(this);
  late final $DictionariesTable dictionaries = $DictionariesTable(this);
  late final $DictionaryTagEntriesTable dictionaryTagEntries =
      $DictionaryTagEntriesTable(this);
  late final $DictionaryTermEntriesTable dictionaryTermEntries =
      $DictionaryTermEntriesTable(this);
  late final $DictionaryTermMetaEntriesTable dictionaryTermMetaEntries =
      $DictionaryTermMetaEntriesTable(this);
  late final $CollectedWordsTable collectedWords = $CollectedWordsTable(this);
  late final $CollectedWordSourcesTable collectedWordSources =
      $CollectedWordSourcesTable(this);
  late final $CollectedGrammarsTable collectedGrammars =
      $CollectedGrammarsTable(this);
  late final $CollectedGrammarSourcesTable collectedGrammarSources =
      $CollectedGrammarSourcesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SentenceExplanationsTable sentenceExplanations =
      $SentenceExplanationsTable(this);
  late final Index idxDictTermHeadword = Index(
    'idx_dict_term_headword',
    'CREATE INDEX idx_dict_term_headword ON dictionary_term_entries (headword)',
  );
  late final Index idxDictTermReadingNormalized = Index(
    'idx_dict_term_reading_normalized',
    'CREATE INDEX idx_dict_term_reading_normalized ON dictionary_term_entries (reading_normalized)',
  );
  late final Index idxDictTermDictionarySequence = Index(
    'idx_dict_term_dictionary_sequence',
    'CREATE INDEX idx_dict_term_dictionary_sequence ON dictionary_term_entries (dictionary_id, sequence)',
  );
  late final Index idxDictTermMetaLookup = Index(
    'idx_dict_term_meta_lookup',
    'CREATE INDEX idx_dict_term_meta_lookup ON dictionary_term_meta_entries (dictionary_id, headword, mode)',
  );
  late final Index idxCollectedWordSourcesWord = Index(
    'idx_collected_word_sources_word',
    'CREATE INDEX idx_collected_word_sources_word ON collected_word_sources (collected_word_id)',
  );
  late final Index idxCollectedGrammarSourcesGrammar = Index(
    'idx_collected_grammar_sources_grammar',
    'CREATE INDEX idx_collected_grammar_sources_grammar ON collected_grammar_sources (collected_grammar_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    chapters,
    sentences,
    dictionaries,
    dictionaryTagEntries,
    dictionaryTermEntries,
    dictionaryTermMetaEntries,
    collectedWords,
    collectedWordSources,
    collectedGrammars,
    collectedGrammarSources,
    settings,
    sentenceExplanations,
    idxDictTermHeadword,
    idxDictTermReadingNormalized,
    idxDictTermDictionarySequence,
    idxDictTermMetaLookup,
    idxCollectedWordSourcesWord,
    idxCollectedGrammarSourcesGrammar,
  ];
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String title,
      required String sourceType,
      required DateTime addedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> sourceType,
      Value<DateTime> addedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChaptersTable, List<ChapterRow>>
  _chaptersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'documents__id__chapters__document_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SentencesTable, List<SentenceRow>>
  _sentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sentences,
    aliasName: 'documents__id__sentences__document_id',
  );

  $$SentencesTableProcessedTableManager get sentencesRefs {
    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CollectedWordSourcesTable,
    List<CollectedWordSource>
  >
  _collectedWordSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectedWordSources,
        aliasName: 'documents__id__collected_word_sources__work_id',
      );

  $$CollectedWordSourcesTableProcessedTableManager
  get collectedWordSourcesRefs {
    final manager = $$CollectedWordSourcesTableTableManager(
      $_db,
      $_db.collectedWordSources,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectedWordSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CollectedGrammarSourcesTable,
    List<CollectedGrammarSource>
  >
  _collectedGrammarSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectedGrammarSources,
        aliasName: 'documents__id__collected_grammar_sources__work_id',
      );

  $$CollectedGrammarSourcesTableProcessedTableManager
  get collectedGrammarSourcesRefs {
    final manager = $$CollectedGrammarSourcesTableTableManager(
      $_db,
      $_db.collectedGrammarSources,
    ).filter((f) => f.workId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectedGrammarSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sentencesRefs(
    Expression<bool> Function($$SentencesTableFilterComposer f) f,
  ) {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectedWordSourcesRefs(
    Expression<bool> Function($$CollectedWordSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedWordSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectedWordSources,
      getReferencedColumn: (t) => t.workId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordSourcesTableFilterComposer(
            $db: $db,
            $table: $db.collectedWordSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectedGrammarSourcesRefs(
    Expression<bool> Function($$CollectedGrammarSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedGrammarSourcesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.workId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableFilterComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sentencesRefs<T extends Object>(
    Expression<T> Function($$SentencesTableAnnotationComposer a) f,
  ) {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectedWordSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedWordSourcesTableAnnotationComposer a) f,
  ) {
    final $$CollectedWordSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedWordSources,
          getReferencedColumn: (t) => t.workId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedWordSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedWordSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> collectedGrammarSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedGrammarSourcesTableAnnotationComposer a)
    f,
  ) {
    final $$CollectedGrammarSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.workId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({
            bool chaptersRefs,
            bool sentencesRefs,
            bool collectedWordSourcesRefs,
            bool collectedGrammarSourcesRefs,
          })
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                title: title,
                sourceType: sourceType,
                addedAt: addedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String sourceType,
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                title: title,
                sourceType: sourceType,
                addedAt: addedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                chaptersRefs = false,
                sentencesRefs = false,
                collectedWordSourcesRefs = false,
                collectedGrammarSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chaptersRefs) db.chapters,
                    if (sentencesRefs) db.sentences,
                    if (collectedWordSourcesRefs) db.collectedWordSources,
                    if (collectedGrammarSourcesRefs) db.collectedGrammarSources,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          ChapterRow
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sentencesRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          SentenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._sentencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).sentencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectedWordSourcesRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          CollectedWordSource
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._collectedWordSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectedWordSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectedGrammarSourcesRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          CollectedGrammarSource
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._collectedGrammarSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectedGrammarSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workId == item.id,
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

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({
        bool chaptersRefs,
        bool sentencesRefs,
        bool collectedWordSourcesRefs,
        bool collectedGrammarSourcesRefs,
      })
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      required String id,
      required String documentId,
      required int chapterIndex,
      Value<String?> title,
      required String blocksJson,
      Value<int> rowid,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> chapterIndex,
      Value<String?> title,
      Value<String> blocksJson,
      Value<int> rowid,
    });

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, ChapterRow> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('chapters__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SentencesTable, List<SentenceRow>>
  _sentencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sentences,
    aliasName: 'chapters__id__sentences__chapter_id',
  );

  $$SentencesTableProcessedTableManager get sentencesRefs {
    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
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

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sentencesRefs(
    Expression<bool> Function($$SentencesTableFilterComposer f) f,
  ) {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
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

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get blocksJson => $composableBuilder(
    column: $table.blocksJson,
    builder: (column) => column,
  );

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sentencesRefs<T extends Object>(
    Expression<T> Function($$SentencesTableAnnotationComposer a) f,
  ) {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          ChapterRow,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (ChapterRow, $$ChaptersTableReferences),
          ChapterRow,
          PrefetchHooks Function({bool documentId, bool sentencesRefs})
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> blocksJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                documentId: documentId,
                chapterIndex: chapterIndex,
                title: title,
                blocksJson: blocksJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int chapterIndex,
                Value<String?> title = const Value.absent(),
                required String blocksJson,
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                documentId: documentId,
                chapterIndex: chapterIndex,
                title: title,
                blocksJson: blocksJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false, sentencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sentencesRefs) db.sentences],
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
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$ChaptersTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$ChaptersTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sentencesRefs)
                    await $_getPrefetchedData<
                      ChapterRow,
                      $ChaptersTable,
                      SentenceRow
                    >(
                      currentTable: table,
                      referencedTable: $$ChaptersTableReferences
                          ._sentencesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ChaptersTableReferences(
                        db,
                        table,
                        p0,
                      ).sentencesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.chapterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      ChapterRow,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (ChapterRow, $$ChaptersTableReferences),
      ChapterRow,
      PrefetchHooks Function({bool documentId, bool sentencesRefs})
    >;
typedef $$SentencesTableCreateCompanionBuilder =
    SentencesCompanion Function({
      required String id,
      required String documentId,
      required String chapterId,
      required int chapterIndex,
      required int blockIndex,
      required int sentenceIndex,
      required String content,
      Value<int> rowid,
    });
typedef $$SentencesTableUpdateCompanionBuilder =
    SentencesCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<String> chapterId,
      Value<int> chapterIndex,
      Value<int> blockIndex,
      Value<int> sentenceIndex,
      Value<String> content,
      Value<int> rowid,
    });

final class $$SentencesTableReferences
    extends BaseReferences<_$AppDatabase, $SentencesTable, SentenceRow> {
  $$SentencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('sentences__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.chapters.createAlias('sentences__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CollectedWordSourcesTable,
    List<CollectedWordSource>
  >
  _collectedWordSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectedWordSources,
        aliasName: 'sentences__id__collected_word_sources__sentence_id',
      );

  $$CollectedWordSourcesTableProcessedTableManager
  get collectedWordSourcesRefs {
    final manager = $$CollectedWordSourcesTableTableManager(
      $_db,
      $_db.collectedWordSources,
    ).filter((f) => f.sentenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectedWordSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CollectedGrammarSourcesTable,
    List<CollectedGrammarSource>
  >
  _collectedGrammarSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectedGrammarSources,
        aliasName: 'sentences__id__collected_grammar_sources__sentence_id',
      );

  $$CollectedGrammarSourcesTableProcessedTableManager
  get collectedGrammarSourcesRefs {
    final manager = $$CollectedGrammarSourcesTableTableManager(
      $_db,
      $_db.collectedGrammarSources,
    ).filter((f) => f.sentenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectedGrammarSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SentencesTableFilterComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableFilterComposer({
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

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentenceIndex => $composableBuilder(
    column: $table.sentenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> collectedWordSourcesRefs(
    Expression<bool> Function($$CollectedWordSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedWordSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectedWordSources,
      getReferencedColumn: (t) => t.sentenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordSourcesTableFilterComposer(
            $db: $db,
            $table: $db.collectedWordSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectedGrammarSourcesRefs(
    Expression<bool> Function($$CollectedGrammarSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedGrammarSourcesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.sentenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableFilterComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SentencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableOrderingComposer({
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

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentenceIndex => $composableBuilder(
    column: $table.sentenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentencesTable> {
  $$SentencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockIndex => $composableBuilder(
    column: $table.blockIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentenceIndex => $composableBuilder(
    column: $table.sentenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> collectedWordSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedWordSourcesTableAnnotationComposer a) f,
  ) {
    final $$CollectedWordSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedWordSources,
          getReferencedColumn: (t) => t.sentenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedWordSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedWordSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> collectedGrammarSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedGrammarSourcesTableAnnotationComposer a)
    f,
  ) {
    final $$CollectedGrammarSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.sentenceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SentencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentencesTable,
          SentenceRow,
          $$SentencesTableFilterComposer,
          $$SentencesTableOrderingComposer,
          $$SentencesTableAnnotationComposer,
          $$SentencesTableCreateCompanionBuilder,
          $$SentencesTableUpdateCompanionBuilder,
          (SentenceRow, $$SentencesTableReferences),
          SentenceRow,
          PrefetchHooks Function({
            bool documentId,
            bool chapterId,
            bool collectedWordSourcesRefs,
            bool collectedGrammarSourcesRefs,
          })
        > {
  $$SentencesTableTableManager(_$AppDatabase db, $SentencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SentencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<int> blockIndex = const Value.absent(),
                Value<int> sentenceIndex = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencesCompanion(
                id: id,
                documentId: documentId,
                chapterId: chapterId,
                chapterIndex: chapterIndex,
                blockIndex: blockIndex,
                sentenceIndex: sentenceIndex,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required String chapterId,
                required int chapterIndex,
                required int blockIndex,
                required int sentenceIndex,
                required String content,
                Value<int> rowid = const Value.absent(),
              }) => SentencesCompanion.insert(
                id: id,
                documentId: documentId,
                chapterId: chapterId,
                chapterIndex: chapterIndex,
                blockIndex: blockIndex,
                sentenceIndex: sentenceIndex,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SentencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                documentId = false,
                chapterId = false,
                collectedWordSourcesRefs = false,
                collectedGrammarSourcesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (collectedWordSourcesRefs) db.collectedWordSources,
                    if (collectedGrammarSourcesRefs) db.collectedGrammarSources,
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
                        if (documentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.documentId,
                                    referencedTable: $$SentencesTableReferences
                                        ._documentIdTable(db),
                                    referencedColumn: $$SentencesTableReferences
                                        ._documentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (chapterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.chapterId,
                                    referencedTable: $$SentencesTableReferences
                                        ._chapterIdTable(db),
                                    referencedColumn: $$SentencesTableReferences
                                        ._chapterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (collectedWordSourcesRefs)
                        await $_getPrefetchedData<
                          SentenceRow,
                          $SentencesTable,
                          CollectedWordSource
                        >(
                          currentTable: table,
                          referencedTable: $$SentencesTableReferences
                              ._collectedWordSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SentencesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectedWordSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sentenceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectedGrammarSourcesRefs)
                        await $_getPrefetchedData<
                          SentenceRow,
                          $SentencesTable,
                          CollectedGrammarSource
                        >(
                          currentTable: table,
                          referencedTable: $$SentencesTableReferences
                              ._collectedGrammarSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SentencesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectedGrammarSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sentenceId == item.id,
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

typedef $$SentencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentencesTable,
      SentenceRow,
      $$SentencesTableFilterComposer,
      $$SentencesTableOrderingComposer,
      $$SentencesTableAnnotationComposer,
      $$SentencesTableCreateCompanionBuilder,
      $$SentencesTableUpdateCompanionBuilder,
      (SentenceRow, $$SentencesTableReferences),
      SentenceRow,
      PrefetchHooks Function({
        bool documentId,
        bool chapterId,
        bool collectedWordSourcesRefs,
        bool collectedGrammarSourcesRefs,
      })
    >;
typedef $$DictionariesTableCreateCompanionBuilder =
    DictionariesCompanion Function({
      required String id,
      required String title,
      required String revision,
      required int formatVersion,
      Value<String?> author,
      Value<String?> url,
      Value<String?> description,
      Value<String?> attribution,
      Value<String?> sourceLanguage,
      Value<String?> targetLanguage,
      Value<String?> frequencyMode,
      Value<bool> sequenced,
      required int priority,
      Value<bool> enabled,
      required DateTime addedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DictionariesTableUpdateCompanionBuilder =
    DictionariesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> revision,
      Value<int> formatVersion,
      Value<String?> author,
      Value<String?> url,
      Value<String?> description,
      Value<String?> attribution,
      Value<String?> sourceLanguage,
      Value<String?> targetLanguage,
      Value<String?> frequencyMode,
      Value<bool> sequenced,
      Value<int> priority,
      Value<bool> enabled,
      Value<DateTime> addedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DictionariesTableReferences
    extends BaseReferences<_$AppDatabase, $DictionariesTable, Dictionary> {
  $$DictionariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $DictionaryTagEntriesTable,
    List<DictionaryTagEntry>
  >
  _dictionaryTagEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dictionaryTagEntries,
        aliasName: 'dictionaries__id__dictionary_tag_entries__dictionary_id',
      );

  $$DictionaryTagEntriesTableProcessedTableManager
  get dictionaryTagEntriesRefs {
    final manager = $$DictionaryTagEntriesTableTableManager(
      $_db,
      $_db.dictionaryTagEntries,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dictionaryTagEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DictionaryTermEntriesTable,
    List<DictionaryTermEntry>
  >
  _dictionaryTermEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dictionaryTermEntries,
        aliasName: 'dictionaries__id__dictionary_term_entries__dictionary_id',
      );

  $$DictionaryTermEntriesTableProcessedTableManager
  get dictionaryTermEntriesRefs {
    final manager = $$DictionaryTermEntriesTableTableManager(
      $_db,
      $_db.dictionaryTermEntries,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dictionaryTermEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DictionaryTermMetaEntriesTable,
    List<DictionaryTermMetaEntry>
  >
  _dictionaryTermMetaEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dictionaryTermMetaEntries,
        aliasName:
            'dictionaries__id__dictionary_term_meta_entries__dictionary_id',
      );

  $$DictionaryTermMetaEntriesTableProcessedTableManager
  get dictionaryTermMetaEntriesRefs {
    final manager = $$DictionaryTermMetaEntriesTableTableManager(
      $_db,
      $_db.dictionaryTermMetaEntries,
    ).filter((f) => f.dictionaryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dictionaryTermMetaEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DictionariesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequencyMode => $composableBuilder(
    column: $table.frequencyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sequenced => $composableBuilder(
    column: $table.sequenced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dictionaryTagEntriesRefs(
    Expression<bool> Function($$DictionaryTagEntriesTableFilterComposer f) f,
  ) {
    final $$DictionaryTagEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dictionaryTagEntries,
      getReferencedColumn: (t) => t.dictionaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionaryTagEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaryTagEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dictionaryTermEntriesRefs(
    Expression<bool> Function($$DictionaryTermEntriesTableFilterComposer f) f,
  ) {
    final $$DictionaryTermEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dictionaryTermEntries,
          getReferencedColumn: (t) => t.dictionaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DictionaryTermEntriesTableFilterComposer(
                $db: $db,
                $table: $db.dictionaryTermEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> dictionaryTermMetaEntriesRefs(
    Expression<bool> Function($$DictionaryTermMetaEntriesTableFilterComposer f)
    f,
  ) {
    final $$DictionaryTermMetaEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dictionaryTermMetaEntries,
          getReferencedColumn: (t) => t.dictionaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DictionaryTermMetaEntriesTableFilterComposer(
                $db: $db,
                $table: $db.dictionaryTermMetaEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DictionariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyMode => $composableBuilder(
    column: $table.frequencyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sequenced => $composableBuilder(
    column: $table.sequenced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionariesTable> {
  $$DictionariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequencyMode => $composableBuilder(
    column: $table.frequencyMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sequenced =>
      $composableBuilder(column: $table.sequenced, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> dictionaryTagEntriesRefs<T extends Object>(
    Expression<T> Function($$DictionaryTagEntriesTableAnnotationComposer a) f,
  ) {
    final $$DictionaryTagEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dictionaryTagEntries,
          getReferencedColumn: (t) => t.dictionaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DictionaryTagEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.dictionaryTagEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> dictionaryTermEntriesRefs<T extends Object>(
    Expression<T> Function($$DictionaryTermEntriesTableAnnotationComposer a) f,
  ) {
    final $$DictionaryTermEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dictionaryTermEntries,
          getReferencedColumn: (t) => t.dictionaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DictionaryTermEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.dictionaryTermEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> dictionaryTermMetaEntriesRefs<T extends Object>(
    Expression<T> Function($$DictionaryTermMetaEntriesTableAnnotationComposer a)
    f,
  ) {
    final $$DictionaryTermMetaEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dictionaryTermMetaEntries,
          getReferencedColumn: (t) => t.dictionaryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DictionaryTermMetaEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.dictionaryTermMetaEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DictionariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionariesTable,
          Dictionary,
          $$DictionariesTableFilterComposer,
          $$DictionariesTableOrderingComposer,
          $$DictionariesTableAnnotationComposer,
          $$DictionariesTableCreateCompanionBuilder,
          $$DictionariesTableUpdateCompanionBuilder,
          (Dictionary, $$DictionariesTableReferences),
          Dictionary,
          PrefetchHooks Function({
            bool dictionaryTagEntriesRefs,
            bool dictionaryTermEntriesRefs,
            bool dictionaryTermMetaEntriesRefs,
          })
        > {
  $$DictionariesTableTableManager(_$AppDatabase db, $DictionariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<String?> sourceLanguage = const Value.absent(),
                Value<String?> targetLanguage = const Value.absent(),
                Value<String?> frequencyMode = const Value.absent(),
                Value<bool> sequenced = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionariesCompanion(
                id: id,
                title: title,
                revision: revision,
                formatVersion: formatVersion,
                author: author,
                url: url,
                description: description,
                attribution: attribution,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                frequencyMode: frequencyMode,
                sequenced: sequenced,
                priority: priority,
                enabled: enabled,
                addedAt: addedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String revision,
                required int formatVersion,
                Value<String?> author = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<String?> sourceLanguage = const Value.absent(),
                Value<String?> targetLanguage = const Value.absent(),
                Value<String?> frequencyMode = const Value.absent(),
                Value<bool> sequenced = const Value.absent(),
                required int priority,
                Value<bool> enabled = const Value.absent(),
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DictionariesCompanion.insert(
                id: id,
                title: title,
                revision: revision,
                formatVersion: formatVersion,
                author: author,
                url: url,
                description: description,
                attribution: attribution,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                frequencyMode: frequencyMode,
                sequenced: sequenced,
                priority: priority,
                enabled: enabled,
                addedAt: addedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DictionariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dictionaryTagEntriesRefs = false,
                dictionaryTermEntriesRefs = false,
                dictionaryTermMetaEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dictionaryTagEntriesRefs) db.dictionaryTagEntries,
                    if (dictionaryTermEntriesRefs) db.dictionaryTermEntries,
                    if (dictionaryTermMetaEntriesRefs)
                      db.dictionaryTermMetaEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dictionaryTagEntriesRefs)
                        await $_getPrefetchedData<
                          Dictionary,
                          $DictionariesTable,
                          DictionaryTagEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._dictionaryTagEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).dictionaryTagEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dictionaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dictionaryTermEntriesRefs)
                        await $_getPrefetchedData<
                          Dictionary,
                          $DictionariesTable,
                          DictionaryTermEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._dictionaryTermEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).dictionaryTermEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dictionaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dictionaryTermMetaEntriesRefs)
                        await $_getPrefetchedData<
                          Dictionary,
                          $DictionariesTable,
                          DictionaryTermMetaEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DictionariesTableReferences
                              ._dictionaryTermMetaEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DictionariesTableReferences(
                                db,
                                table,
                                p0,
                              ).dictionaryTermMetaEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dictionaryId == item.id,
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

typedef $$DictionariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionariesTable,
      Dictionary,
      $$DictionariesTableFilterComposer,
      $$DictionariesTableOrderingComposer,
      $$DictionariesTableAnnotationComposer,
      $$DictionariesTableCreateCompanionBuilder,
      $$DictionariesTableUpdateCompanionBuilder,
      (Dictionary, $$DictionariesTableReferences),
      Dictionary,
      PrefetchHooks Function({
        bool dictionaryTagEntriesRefs,
        bool dictionaryTermEntriesRefs,
        bool dictionaryTermMetaEntriesRefs,
      })
    >;
typedef $$DictionaryTagEntriesTableCreateCompanionBuilder =
    DictionaryTagEntriesCompanion Function({
      Value<int> id,
      required String dictionaryId,
      required String name,
      required String category,
      required int sortOrder,
      required String notes,
      required double score,
    });
typedef $$DictionaryTagEntriesTableUpdateCompanionBuilder =
    DictionaryTagEntriesCompanion Function({
      Value<int> id,
      Value<String> dictionaryId,
      Value<String> name,
      Value<String> category,
      Value<int> sortOrder,
      Value<String> notes,
      Value<double> score,
    });

final class $$DictionaryTagEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DictionaryTagEntriesTable,
          DictionaryTagEntry
        > {
  $$DictionaryTagEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) => db
      .dictionaries
      .createAlias('dictionary_tag_entries__dictionary_id__dictionaries__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<String>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DictionaryTagEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryTagEntriesTable> {
  $$DictionaryTagEntriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTagEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryTagEntriesTable> {
  $$DictionaryTagEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTagEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryTagEntriesTable> {
  $$DictionaryTagEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTagEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryTagEntriesTable,
          DictionaryTagEntry,
          $$DictionaryTagEntriesTableFilterComposer,
          $$DictionaryTagEntriesTableOrderingComposer,
          $$DictionaryTagEntriesTableAnnotationComposer,
          $$DictionaryTagEntriesTableCreateCompanionBuilder,
          $$DictionaryTagEntriesTableUpdateCompanionBuilder,
          (DictionaryTagEntry, $$DictionaryTagEntriesTableReferences),
          DictionaryTagEntry,
          PrefetchHooks Function({bool dictionaryId})
        > {
  $$DictionaryTagEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryTagEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryTagEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryTagEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryTagEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dictionaryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<double> score = const Value.absent(),
              }) => DictionaryTagEntriesCompanion(
                id: id,
                dictionaryId: dictionaryId,
                name: name,
                category: category,
                sortOrder: sortOrder,
                notes: notes,
                score: score,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dictionaryId,
                required String name,
                required String category,
                required int sortOrder,
                required String notes,
                required double score,
              }) => DictionaryTagEntriesCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                name: name,
                category: category,
                sortOrder: sortOrder,
                notes: notes,
                score: score,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DictionaryTagEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dictionaryId = false}) {
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
                    if (dictionaryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dictionaryId,
                                referencedTable:
                                    $$DictionaryTagEntriesTableReferences
                                        ._dictionaryIdTable(db),
                                referencedColumn:
                                    $$DictionaryTagEntriesTableReferences
                                        ._dictionaryIdTable(db)
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

typedef $$DictionaryTagEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryTagEntriesTable,
      DictionaryTagEntry,
      $$DictionaryTagEntriesTableFilterComposer,
      $$DictionaryTagEntriesTableOrderingComposer,
      $$DictionaryTagEntriesTableAnnotationComposer,
      $$DictionaryTagEntriesTableCreateCompanionBuilder,
      $$DictionaryTagEntriesTableUpdateCompanionBuilder,
      (DictionaryTagEntry, $$DictionaryTagEntriesTableReferences),
      DictionaryTagEntry,
      PrefetchHooks Function({bool dictionaryId})
    >;
typedef $$DictionaryTermEntriesTableCreateCompanionBuilder =
    DictionaryTermEntriesCompanion Function({
      Value<int> id,
      required String dictionaryId,
      required String headword,
      required String reading,
      required String readingNormalized,
      Value<String?> definitionTags,
      required String rules,
      required double score,
      required String definitionsJson,
      required int sequence,
      required String termTags,
      required int importOrder,
    });
typedef $$DictionaryTermEntriesTableUpdateCompanionBuilder =
    DictionaryTermEntriesCompanion Function({
      Value<int> id,
      Value<String> dictionaryId,
      Value<String> headword,
      Value<String> reading,
      Value<String> readingNormalized,
      Value<String?> definitionTags,
      Value<String> rules,
      Value<double> score,
      Value<String> definitionsJson,
      Value<int> sequence,
      Value<String> termTags,
      Value<int> importOrder,
    });

final class $$DictionaryTermEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DictionaryTermEntriesTable,
          DictionaryTermEntry
        > {
  $$DictionaryTermEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) => db
      .dictionaries
      .createAlias('dictionary_term_entries__dictionary_id__dictionaries__id');

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<String>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DictionaryTermEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryTermEntriesTable> {
  $$DictionaryTermEntriesTableFilterComposer({
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

  ColumnFilters<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingNormalized => $composableBuilder(
    column: $table.readingNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionsJson => $composableBuilder(
    column: $table.definitionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termTags => $composableBuilder(
    column: $table.termTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importOrder => $composableBuilder(
    column: $table.importOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryTermEntriesTable> {
  $$DictionaryTermEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingNormalized => $composableBuilder(
    column: $table.readingNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionsJson => $composableBuilder(
    column: $table.definitionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termTags => $composableBuilder(
    column: $table.termTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importOrder => $composableBuilder(
    column: $table.importOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryTermEntriesTable> {
  $$DictionaryTermEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get headword =>
      $composableBuilder(column: $table.headword, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get readingNormalized => $composableBuilder(
    column: $table.readingNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rules =>
      $composableBuilder(column: $table.rules, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get definitionsJson => $composableBuilder(
    column: $table.definitionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get termTags =>
      $composableBuilder(column: $table.termTags, builder: (column) => column);

  GeneratedColumn<int> get importOrder => $composableBuilder(
    column: $table.importOrder,
    builder: (column) => column,
  );

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryTermEntriesTable,
          DictionaryTermEntry,
          $$DictionaryTermEntriesTableFilterComposer,
          $$DictionaryTermEntriesTableOrderingComposer,
          $$DictionaryTermEntriesTableAnnotationComposer,
          $$DictionaryTermEntriesTableCreateCompanionBuilder,
          $$DictionaryTermEntriesTableUpdateCompanionBuilder,
          (DictionaryTermEntry, $$DictionaryTermEntriesTableReferences),
          DictionaryTermEntry,
          PrefetchHooks Function({bool dictionaryId})
        > {
  $$DictionaryTermEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryTermEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryTermEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryTermEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryTermEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dictionaryId = const Value.absent(),
                Value<String> headword = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> readingNormalized = const Value.absent(),
                Value<String?> definitionTags = const Value.absent(),
                Value<String> rules = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<String> definitionsJson = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> termTags = const Value.absent(),
                Value<int> importOrder = const Value.absent(),
              }) => DictionaryTermEntriesCompanion(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                reading: reading,
                readingNormalized: readingNormalized,
                definitionTags: definitionTags,
                rules: rules,
                score: score,
                definitionsJson: definitionsJson,
                sequence: sequence,
                termTags: termTags,
                importOrder: importOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dictionaryId,
                required String headword,
                required String reading,
                required String readingNormalized,
                Value<String?> definitionTags = const Value.absent(),
                required String rules,
                required double score,
                required String definitionsJson,
                required int sequence,
                required String termTags,
                required int importOrder,
              }) => DictionaryTermEntriesCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                reading: reading,
                readingNormalized: readingNormalized,
                definitionTags: definitionTags,
                rules: rules,
                score: score,
                definitionsJson: definitionsJson,
                sequence: sequence,
                termTags: termTags,
                importOrder: importOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DictionaryTermEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dictionaryId = false}) {
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
                    if (dictionaryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dictionaryId,
                                referencedTable:
                                    $$DictionaryTermEntriesTableReferences
                                        ._dictionaryIdTable(db),
                                referencedColumn:
                                    $$DictionaryTermEntriesTableReferences
                                        ._dictionaryIdTable(db)
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

typedef $$DictionaryTermEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryTermEntriesTable,
      DictionaryTermEntry,
      $$DictionaryTermEntriesTableFilterComposer,
      $$DictionaryTermEntriesTableOrderingComposer,
      $$DictionaryTermEntriesTableAnnotationComposer,
      $$DictionaryTermEntriesTableCreateCompanionBuilder,
      $$DictionaryTermEntriesTableUpdateCompanionBuilder,
      (DictionaryTermEntry, $$DictionaryTermEntriesTableReferences),
      DictionaryTermEntry,
      PrefetchHooks Function({bool dictionaryId})
    >;
typedef $$DictionaryTermMetaEntriesTableCreateCompanionBuilder =
    DictionaryTermMetaEntriesCompanion Function({
      Value<int> id,
      required String dictionaryId,
      required String headword,
      required String mode,
      Value<String?> reading,
      required String dataJson,
    });
typedef $$DictionaryTermMetaEntriesTableUpdateCompanionBuilder =
    DictionaryTermMetaEntriesCompanion Function({
      Value<int> id,
      Value<String> dictionaryId,
      Value<String> headword,
      Value<String> mode,
      Value<String?> reading,
      Value<String> dataJson,
    });

final class $$DictionaryTermMetaEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DictionaryTermMetaEntriesTable,
          DictionaryTermMetaEntry
        > {
  $$DictionaryTermMetaEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DictionariesTable _dictionaryIdTable(_$AppDatabase db) =>
      db.dictionaries.createAlias(
        'dictionary_term_meta_entries__dictionary_id__dictionaries__id',
      );

  $$DictionariesTableProcessedTableManager get dictionaryId {
    final $_column = $_itemColumn<String>('dictionary_id')!;

    final manager = $$DictionariesTableTableManager(
      $_db,
      $_db.dictionaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dictionaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DictionaryTermMetaEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryTermMetaEntriesTable> {
  $$DictionaryTermMetaEntriesTableFilterComposer({
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

  ColumnFilters<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$DictionariesTableFilterComposer get dictionaryId {
    final $$DictionariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableFilterComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermMetaEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryTermMetaEntriesTable> {
  $$DictionaryTermMetaEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$DictionariesTableOrderingComposer get dictionaryId {
    final $$DictionariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableOrderingComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermMetaEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryTermMetaEntriesTable> {
  $$DictionaryTermMetaEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get headword =>
      $composableBuilder(column: $table.headword, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  $$DictionariesTableAnnotationComposer get dictionaryId {
    final $$DictionariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dictionaryId,
      referencedTable: $db.dictionaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DictionariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dictionaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DictionaryTermMetaEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryTermMetaEntriesTable,
          DictionaryTermMetaEntry,
          $$DictionaryTermMetaEntriesTableFilterComposer,
          $$DictionaryTermMetaEntriesTableOrderingComposer,
          $$DictionaryTermMetaEntriesTableAnnotationComposer,
          $$DictionaryTermMetaEntriesTableCreateCompanionBuilder,
          $$DictionaryTermMetaEntriesTableUpdateCompanionBuilder,
          (DictionaryTermMetaEntry, $$DictionaryTermMetaEntriesTableReferences),
          DictionaryTermMetaEntry,
          PrefetchHooks Function({bool dictionaryId})
        > {
  $$DictionaryTermMetaEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryTermMetaEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryTermMetaEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryTermMetaEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryTermMetaEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dictionaryId = const Value.absent(),
                Value<String> headword = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String?> reading = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
              }) => DictionaryTermMetaEntriesCompanion(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                mode: mode,
                reading: reading,
                dataJson: dataJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dictionaryId,
                required String headword,
                required String mode,
                Value<String?> reading = const Value.absent(),
                required String dataJson,
              }) => DictionaryTermMetaEntriesCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                mode: mode,
                reading: reading,
                dataJson: dataJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DictionaryTermMetaEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dictionaryId = false}) {
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
                    if (dictionaryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dictionaryId,
                                referencedTable:
                                    $$DictionaryTermMetaEntriesTableReferences
                                        ._dictionaryIdTable(db),
                                referencedColumn:
                                    $$DictionaryTermMetaEntriesTableReferences
                                        ._dictionaryIdTable(db)
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

typedef $$DictionaryTermMetaEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryTermMetaEntriesTable,
      DictionaryTermMetaEntry,
      $$DictionaryTermMetaEntriesTableFilterComposer,
      $$DictionaryTermMetaEntriesTableOrderingComposer,
      $$DictionaryTermMetaEntriesTableAnnotationComposer,
      $$DictionaryTermMetaEntriesTableCreateCompanionBuilder,
      $$DictionaryTermMetaEntriesTableUpdateCompanionBuilder,
      (DictionaryTermMetaEntry, $$DictionaryTermMetaEntriesTableReferences),
      DictionaryTermMetaEntry,
      PrefetchHooks Function({bool dictionaryId})
    >;
typedef $$CollectedWordsTableCreateCompanionBuilder =
    CollectedWordsCompanion Function({
      required String id,
      required String dictForm,
      required String reading,
      required String senseIdsJson,
      required DateTime addedAt,
      required DateTime updatedAt,
      Value<double?> fsrsDifficulty,
      Value<double?> fsrsStability,
      required DateTime srsDue,
      required int srsLapses,
      required String srsStatus,
      Value<DateTime?> lastReviewedAt,
      Value<int> rowid,
    });
typedef $$CollectedWordsTableUpdateCompanionBuilder =
    CollectedWordsCompanion Function({
      Value<String> id,
      Value<String> dictForm,
      Value<String> reading,
      Value<String> senseIdsJson,
      Value<DateTime> addedAt,
      Value<DateTime> updatedAt,
      Value<double?> fsrsDifficulty,
      Value<double?> fsrsStability,
      Value<DateTime> srsDue,
      Value<int> srsLapses,
      Value<String> srsStatus,
      Value<DateTime?> lastReviewedAt,
      Value<int> rowid,
    });

final class $$CollectedWordsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectedWordsTable, CollectedWord> {
  $$CollectedWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CollectedWordSourcesTable,
    List<CollectedWordSource>
  >
  _collectedWordSourcesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectedWordSources,
        aliasName:
            'collected_words__id__collected_word_sources__collected_word_id',
      );

  $$CollectedWordSourcesTableProcessedTableManager
  get collectedWordSourcesRefs {
    final manager =
        $$CollectedWordSourcesTableTableManager(
          $_db,
          $_db.collectedWordSources,
        ).filter(
          (f) => f.collectedWordId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _collectedWordSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectedWordsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectedWordsTable> {
  $$CollectedWordsTableFilterComposer({
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

  ColumnFilters<String> get dictForm => $composableBuilder(
    column: $table.dictForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senseIdsJson => $composableBuilder(
    column: $table.senseIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get srsDue => $composableBuilder(
    column: $table.srsDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get srsLapses => $composableBuilder(
    column: $table.srsLapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get srsStatus => $composableBuilder(
    column: $table.srsStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectedWordSourcesRefs(
    Expression<bool> Function($$CollectedWordSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedWordSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectedWordSources,
      getReferencedColumn: (t) => t.collectedWordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordSourcesTableFilterComposer(
            $db: $db,
            $table: $db.collectedWordSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectedWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectedWordsTable> {
  $$CollectedWordsTableOrderingComposer({
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

  ColumnOrderings<String> get dictForm => $composableBuilder(
    column: $table.dictForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senseIdsJson => $composableBuilder(
    column: $table.senseIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get srsDue => $composableBuilder(
    column: $table.srsDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get srsLapses => $composableBuilder(
    column: $table.srsLapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get srsStatus => $composableBuilder(
    column: $table.srsStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectedWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectedWordsTable> {
  $$CollectedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dictForm =>
      $composableBuilder(column: $table.dictForm, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get senseIdsJson => $composableBuilder(
    column: $table.senseIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get srsDue =>
      $composableBuilder(column: $table.srsDue, builder: (column) => column);

  GeneratedColumn<int> get srsLapses =>
      $composableBuilder(column: $table.srsLapses, builder: (column) => column);

  GeneratedColumn<String> get srsStatus =>
      $composableBuilder(column: $table.srsStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  Expression<T> collectedWordSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedWordSourcesTableAnnotationComposer a) f,
  ) {
    final $$CollectedWordSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedWordSources,
          getReferencedColumn: (t) => t.collectedWordId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedWordSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedWordSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CollectedWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectedWordsTable,
          CollectedWord,
          $$CollectedWordsTableFilterComposer,
          $$CollectedWordsTableOrderingComposer,
          $$CollectedWordsTableAnnotationComposer,
          $$CollectedWordsTableCreateCompanionBuilder,
          $$CollectedWordsTableUpdateCompanionBuilder,
          (CollectedWord, $$CollectedWordsTableReferences),
          CollectedWord,
          PrefetchHooks Function({bool collectedWordSourcesRefs})
        > {
  $$CollectedWordsTableTableManager(
    _$AppDatabase db,
    $CollectedWordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dictForm = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> senseIdsJson = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<DateTime> srsDue = const Value.absent(),
                Value<int> srsLapses = const Value.absent(),
                Value<String> srsStatus = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectedWordsCompanion(
                id: id,
                dictForm: dictForm,
                reading: reading,
                senseIdsJson: senseIdsJson,
                addedAt: addedAt,
                updatedAt: updatedAt,
                fsrsDifficulty: fsrsDifficulty,
                fsrsStability: fsrsStability,
                srsDue: srsDue,
                srsLapses: srsLapses,
                srsStatus: srsStatus,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dictForm,
                required String reading,
                required String senseIdsJson,
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                required DateTime srsDue,
                required int srsLapses,
                required String srsStatus,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectedWordsCompanion.insert(
                id: id,
                dictForm: dictForm,
                reading: reading,
                senseIdsJson: senseIdsJson,
                addedAt: addedAt,
                updatedAt: updatedAt,
                fsrsDifficulty: fsrsDifficulty,
                fsrsStability: fsrsStability,
                srsDue: srsDue,
                srsLapses: srsLapses,
                srsStatus: srsStatus,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectedWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectedWordSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectedWordSourcesRefs) db.collectedWordSources,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectedWordSourcesRefs)
                    await $_getPrefetchedData<
                      CollectedWord,
                      $CollectedWordsTable,
                      CollectedWordSource
                    >(
                      currentTable: table,
                      referencedTable: $$CollectedWordsTableReferences
                          ._collectedWordSourcesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectedWordsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectedWordSourcesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectedWordId == item.id,
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

typedef $$CollectedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectedWordsTable,
      CollectedWord,
      $$CollectedWordsTableFilterComposer,
      $$CollectedWordsTableOrderingComposer,
      $$CollectedWordsTableAnnotationComposer,
      $$CollectedWordsTableCreateCompanionBuilder,
      $$CollectedWordsTableUpdateCompanionBuilder,
      (CollectedWord, $$CollectedWordsTableReferences),
      CollectedWord,
      PrefetchHooks Function({bool collectedWordSourcesRefs})
    >;
typedef $$CollectedWordSourcesTableCreateCompanionBuilder =
    CollectedWordSourcesCompanion Function({
      Value<int> id,
      required String collectedWordId,
      required String workId,
      required String sentenceId,
      required String mediaType,
      required DateTime minedAt,
    });
typedef $$CollectedWordSourcesTableUpdateCompanionBuilder =
    CollectedWordSourcesCompanion Function({
      Value<int> id,
      Value<String> collectedWordId,
      Value<String> workId,
      Value<String> sentenceId,
      Value<String> mediaType,
      Value<DateTime> minedAt,
    });

final class $$CollectedWordSourcesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectedWordSourcesTable,
          CollectedWordSource
        > {
  $$CollectedWordSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectedWordsTable _collectedWordIdTable(_$AppDatabase db) =>
      db.collectedWords.createAlias(
        'collected_word_sources__collected_word_id__collected_words__id',
      );

  $$CollectedWordsTableProcessedTableManager get collectedWordId {
    final $_column = $_itemColumn<String>('collected_word_id')!;

    final manager = $$CollectedWordsTableTableManager(
      $_db,
      $_db.collectedWords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectedWordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DocumentsTable _workIdTable(_$AppDatabase db) => db.documents
      .createAlias('collected_word_sources__work_id__documents__id');

  $$DocumentsTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SentencesTable _sentenceIdTable(_$AppDatabase db) => db.sentences
      .createAlias('collected_word_sources__sentence_id__sentences__id');

  $$SentencesTableProcessedTableManager get sentenceId {
    final $_column = $_itemColumn<String>('sentence_id')!;

    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sentenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectedWordSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $CollectedWordSourcesTable> {
  $$CollectedWordSourcesTableFilterComposer({
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

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get minedAt => $composableBuilder(
    column: $table.minedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectedWordsTableFilterComposer get collectedWordId {
    final $$CollectedWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectedWordId,
      referencedTable: $db.collectedWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordsTableFilterComposer(
            $db: $db,
            $table: $db.collectedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableFilterComposer get workId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableFilterComposer get sentenceId {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedWordSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectedWordSourcesTable> {
  $$CollectedWordSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get minedAt => $composableBuilder(
    column: $table.minedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectedWordsTableOrderingComposer get collectedWordId {
    final $$CollectedWordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectedWordId,
      referencedTable: $db.collectedWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordsTableOrderingComposer(
            $db: $db,
            $table: $db.collectedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableOrderingComposer get workId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableOrderingComposer get sentenceId {
    final $$SentencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableOrderingComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedWordSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectedWordSourcesTable> {
  $$CollectedWordSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<DateTime> get minedAt =>
      $composableBuilder(column: $table.minedAt, builder: (column) => column);

  $$CollectedWordsTableAnnotationComposer get collectedWordId {
    final $$CollectedWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectedWordId,
      referencedTable: $db.collectedWords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableAnnotationComposer get workId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableAnnotationComposer get sentenceId {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedWordSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectedWordSourcesTable,
          CollectedWordSource,
          $$CollectedWordSourcesTableFilterComposer,
          $$CollectedWordSourcesTableOrderingComposer,
          $$CollectedWordSourcesTableAnnotationComposer,
          $$CollectedWordSourcesTableCreateCompanionBuilder,
          $$CollectedWordSourcesTableUpdateCompanionBuilder,
          (CollectedWordSource, $$CollectedWordSourcesTableReferences),
          CollectedWordSource,
          PrefetchHooks Function({
            bool collectedWordId,
            bool workId,
            bool sentenceId,
          })
        > {
  $$CollectedWordSourcesTableTableManager(
    _$AppDatabase db,
    $CollectedWordSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectedWordSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectedWordSourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectedWordSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> collectedWordId = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<String> sentenceId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<DateTime> minedAt = const Value.absent(),
              }) => CollectedWordSourcesCompanion(
                id: id,
                collectedWordId: collectedWordId,
                workId: workId,
                sentenceId: sentenceId,
                mediaType: mediaType,
                minedAt: minedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String collectedWordId,
                required String workId,
                required String sentenceId,
                required String mediaType,
                required DateTime minedAt,
              }) => CollectedWordSourcesCompanion.insert(
                id: id,
                collectedWordId: collectedWordId,
                workId: workId,
                sentenceId: sentenceId,
                mediaType: mediaType,
                minedAt: minedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectedWordSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({collectedWordId = false, workId = false, sentenceId = false}) {
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
                        if (collectedWordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.collectedWordId,
                                    referencedTable:
                                        $$CollectedWordSourcesTableReferences
                                            ._collectedWordIdTable(db),
                                    referencedColumn:
                                        $$CollectedWordSourcesTableReferences
                                            ._collectedWordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workId,
                                    referencedTable:
                                        $$CollectedWordSourcesTableReferences
                                            ._workIdTable(db),
                                    referencedColumn:
                                        $$CollectedWordSourcesTableReferences
                                            ._workIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sentenceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sentenceId,
                                    referencedTable:
                                        $$CollectedWordSourcesTableReferences
                                            ._sentenceIdTable(db),
                                    referencedColumn:
                                        $$CollectedWordSourcesTableReferences
                                            ._sentenceIdTable(db)
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

typedef $$CollectedWordSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectedWordSourcesTable,
      CollectedWordSource,
      $$CollectedWordSourcesTableFilterComposer,
      $$CollectedWordSourcesTableOrderingComposer,
      $$CollectedWordSourcesTableAnnotationComposer,
      $$CollectedWordSourcesTableCreateCompanionBuilder,
      $$CollectedWordSourcesTableUpdateCompanionBuilder,
      (CollectedWordSource, $$CollectedWordSourcesTableReferences),
      CollectedWordSource,
      PrefetchHooks Function({
        bool collectedWordId,
        bool workId,
        bool sentenceId,
      })
    >;
typedef $$CollectedGrammarsTableCreateCompanionBuilder =
    CollectedGrammarsCompanion Function({
      required String id,
      required String grammarPointId,
      required DateTime addedAt,
      required DateTime updatedAt,
      Value<double?> fsrsDifficulty,
      Value<double?> fsrsStability,
      required DateTime srsDue,
      required int srsLapses,
      Value<DateTime?> lastReviewedAt,
      required String srsStatus,
      Value<int> rowid,
    });
typedef $$CollectedGrammarsTableUpdateCompanionBuilder =
    CollectedGrammarsCompanion Function({
      Value<String> id,
      Value<String> grammarPointId,
      Value<DateTime> addedAt,
      Value<DateTime> updatedAt,
      Value<double?> fsrsDifficulty,
      Value<double?> fsrsStability,
      Value<DateTime> srsDue,
      Value<int> srsLapses,
      Value<DateTime?> lastReviewedAt,
      Value<String> srsStatus,
      Value<int> rowid,
    });

final class $$CollectedGrammarsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectedGrammarsTable,
          CollectedGrammar
        > {
  $$CollectedGrammarsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CollectedGrammarSourcesTable,
    List<CollectedGrammarSource>
  >
  _collectedGrammarSourcesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.collectedGrammarSources,
    aliasName:
        'collected_grammars__id__collected_grammar_sources__collected_grammar_id',
  );

  $$CollectedGrammarSourcesTableProcessedTableManager
  get collectedGrammarSourcesRefs {
    final manager =
        $$CollectedGrammarSourcesTableTableManager(
          $_db,
          $_db.collectedGrammarSources,
        ).filter(
          (f) => f.collectedGrammarId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _collectedGrammarSourcesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectedGrammarsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectedGrammarsTable> {
  $$CollectedGrammarsTableFilterComposer({
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

  ColumnFilters<String> get grammarPointId => $composableBuilder(
    column: $table.grammarPointId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get srsDue => $composableBuilder(
    column: $table.srsDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get srsLapses => $composableBuilder(
    column: $table.srsLapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get srsStatus => $composableBuilder(
    column: $table.srsStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectedGrammarSourcesRefs(
    Expression<bool> Function($$CollectedGrammarSourcesTableFilterComposer f) f,
  ) {
    final $$CollectedGrammarSourcesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.collectedGrammarId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableFilterComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CollectedGrammarsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectedGrammarsTable> {
  $$CollectedGrammarsTableOrderingComposer({
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

  ColumnOrderings<String> get grammarPointId => $composableBuilder(
    column: $table.grammarPointId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get srsDue => $composableBuilder(
    column: $table.srsDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get srsLapses => $composableBuilder(
    column: $table.srsLapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get srsStatus => $composableBuilder(
    column: $table.srsStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectedGrammarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectedGrammarsTable> {
  $$CollectedGrammarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get grammarPointId => $composableBuilder(
    column: $table.grammarPointId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get srsDue =>
      $composableBuilder(column: $table.srsDue, builder: (column) => column);

  GeneratedColumn<int> get srsLapses =>
      $composableBuilder(column: $table.srsLapses, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get srsStatus =>
      $composableBuilder(column: $table.srsStatus, builder: (column) => column);

  Expression<T> collectedGrammarSourcesRefs<T extends Object>(
    Expression<T> Function($$CollectedGrammarSourcesTableAnnotationComposer a)
    f,
  ) {
    final $$CollectedGrammarSourcesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectedGrammarSources,
          getReferencedColumn: (t) => t.collectedGrammarId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarSourcesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedGrammarSources,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CollectedGrammarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectedGrammarsTable,
          CollectedGrammar,
          $$CollectedGrammarsTableFilterComposer,
          $$CollectedGrammarsTableOrderingComposer,
          $$CollectedGrammarsTableAnnotationComposer,
          $$CollectedGrammarsTableCreateCompanionBuilder,
          $$CollectedGrammarsTableUpdateCompanionBuilder,
          (CollectedGrammar, $$CollectedGrammarsTableReferences),
          CollectedGrammar,
          PrefetchHooks Function({bool collectedGrammarSourcesRefs})
        > {
  $$CollectedGrammarsTableTableManager(
    _$AppDatabase db,
    $CollectedGrammarsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectedGrammarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectedGrammarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectedGrammarsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> grammarPointId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<DateTime> srsDue = const Value.absent(),
                Value<int> srsLapses = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<String> srsStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectedGrammarsCompanion(
                id: id,
                grammarPointId: grammarPointId,
                addedAt: addedAt,
                updatedAt: updatedAt,
                fsrsDifficulty: fsrsDifficulty,
                fsrsStability: fsrsStability,
                srsDue: srsDue,
                srsLapses: srsLapses,
                lastReviewedAt: lastReviewedAt,
                srsStatus: srsStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String grammarPointId,
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                required DateTime srsDue,
                required int srsLapses,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                required String srsStatus,
                Value<int> rowid = const Value.absent(),
              }) => CollectedGrammarsCompanion.insert(
                id: id,
                grammarPointId: grammarPointId,
                addedAt: addedAt,
                updatedAt: updatedAt,
                fsrsDifficulty: fsrsDifficulty,
                fsrsStability: fsrsStability,
                srsDue: srsDue,
                srsLapses: srsLapses,
                lastReviewedAt: lastReviewedAt,
                srsStatus: srsStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectedGrammarsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectedGrammarSourcesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectedGrammarSourcesRefs) db.collectedGrammarSources,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectedGrammarSourcesRefs)
                    await $_getPrefetchedData<
                      CollectedGrammar,
                      $CollectedGrammarsTable,
                      CollectedGrammarSource
                    >(
                      currentTable: table,
                      referencedTable: $$CollectedGrammarsTableReferences
                          ._collectedGrammarSourcesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectedGrammarsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectedGrammarSourcesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectedGrammarId == item.id,
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

typedef $$CollectedGrammarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectedGrammarsTable,
      CollectedGrammar,
      $$CollectedGrammarsTableFilterComposer,
      $$CollectedGrammarsTableOrderingComposer,
      $$CollectedGrammarsTableAnnotationComposer,
      $$CollectedGrammarsTableCreateCompanionBuilder,
      $$CollectedGrammarsTableUpdateCompanionBuilder,
      (CollectedGrammar, $$CollectedGrammarsTableReferences),
      CollectedGrammar,
      PrefetchHooks Function({bool collectedGrammarSourcesRefs})
    >;
typedef $$CollectedGrammarSourcesTableCreateCompanionBuilder =
    CollectedGrammarSourcesCompanion Function({
      Value<int> id,
      required String collectedGrammarId,
      required String workId,
      required String sentenceId,
      required String mediaType,
      required DateTime minedAt,
    });
typedef $$CollectedGrammarSourcesTableUpdateCompanionBuilder =
    CollectedGrammarSourcesCompanion Function({
      Value<int> id,
      Value<String> collectedGrammarId,
      Value<String> workId,
      Value<String> sentenceId,
      Value<String> mediaType,
      Value<DateTime> minedAt,
    });

final class $$CollectedGrammarSourcesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectedGrammarSourcesTable,
          CollectedGrammarSource
        > {
  $$CollectedGrammarSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectedGrammarsTable _collectedGrammarIdTable(
    _$AppDatabase db,
  ) => db.collectedGrammars.createAlias(
    'collected_grammar_sources__collected_grammar_id__collected_grammars__id',
  );

  $$CollectedGrammarsTableProcessedTableManager get collectedGrammarId {
    final $_column = $_itemColumn<String>('collected_grammar_id')!;

    final manager = $$CollectedGrammarsTableTableManager(
      $_db,
      $_db.collectedGrammars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectedGrammarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DocumentsTable _workIdTable(_$AppDatabase db) => db.documents
      .createAlias('collected_grammar_sources__work_id__documents__id');

  $$DocumentsTableProcessedTableManager get workId {
    final $_column = $_itemColumn<String>('work_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SentencesTable _sentenceIdTable(_$AppDatabase db) => db.sentences
      .createAlias('collected_grammar_sources__sentence_id__sentences__id');

  $$SentencesTableProcessedTableManager get sentenceId {
    final $_column = $_itemColumn<String>('sentence_id')!;

    final manager = $$SentencesTableTableManager(
      $_db,
      $_db.sentences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sentenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectedGrammarSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $CollectedGrammarSourcesTable> {
  $$CollectedGrammarSourcesTableFilterComposer({
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

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get minedAt => $composableBuilder(
    column: $table.minedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectedGrammarsTableFilterComposer get collectedGrammarId {
    final $$CollectedGrammarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectedGrammarId,
      referencedTable: $db.collectedGrammars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedGrammarsTableFilterComposer(
            $db: $db,
            $table: $db.collectedGrammars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableFilterComposer get workId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableFilterComposer get sentenceId {
    final $$SentencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableFilterComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedGrammarSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectedGrammarSourcesTable> {
  $$CollectedGrammarSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get minedAt => $composableBuilder(
    column: $table.minedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectedGrammarsTableOrderingComposer get collectedGrammarId {
    final $$CollectedGrammarsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectedGrammarId,
      referencedTable: $db.collectedGrammars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectedGrammarsTableOrderingComposer(
            $db: $db,
            $table: $db.collectedGrammars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DocumentsTableOrderingComposer get workId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableOrderingComposer get sentenceId {
    final $$SentencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableOrderingComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedGrammarSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectedGrammarSourcesTable> {
  $$CollectedGrammarSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<DateTime> get minedAt =>
      $composableBuilder(column: $table.minedAt, builder: (column) => column);

  $$CollectedGrammarsTableAnnotationComposer get collectedGrammarId {
    final $$CollectedGrammarsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.collectedGrammarId,
          referencedTable: $db.collectedGrammars,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectedGrammarsTableAnnotationComposer(
                $db: $db,
                $table: $db.collectedGrammars,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$DocumentsTableAnnotationComposer get workId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SentencesTableAnnotationComposer get sentenceId {
    final $$SentencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sentenceId,
      referencedTable: $db.sentences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SentencesTableAnnotationComposer(
            $db: $db,
            $table: $db.sentences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectedGrammarSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectedGrammarSourcesTable,
          CollectedGrammarSource,
          $$CollectedGrammarSourcesTableFilterComposer,
          $$CollectedGrammarSourcesTableOrderingComposer,
          $$CollectedGrammarSourcesTableAnnotationComposer,
          $$CollectedGrammarSourcesTableCreateCompanionBuilder,
          $$CollectedGrammarSourcesTableUpdateCompanionBuilder,
          (CollectedGrammarSource, $$CollectedGrammarSourcesTableReferences),
          CollectedGrammarSource,
          PrefetchHooks Function({
            bool collectedGrammarId,
            bool workId,
            bool sentenceId,
          })
        > {
  $$CollectedGrammarSourcesTableTableManager(
    _$AppDatabase db,
    $CollectedGrammarSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectedGrammarSourcesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CollectedGrammarSourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectedGrammarSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> collectedGrammarId = const Value.absent(),
                Value<String> workId = const Value.absent(),
                Value<String> sentenceId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<DateTime> minedAt = const Value.absent(),
              }) => CollectedGrammarSourcesCompanion(
                id: id,
                collectedGrammarId: collectedGrammarId,
                workId: workId,
                sentenceId: sentenceId,
                mediaType: mediaType,
                minedAt: minedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String collectedGrammarId,
                required String workId,
                required String sentenceId,
                required String mediaType,
                required DateTime minedAt,
              }) => CollectedGrammarSourcesCompanion.insert(
                id: id,
                collectedGrammarId: collectedGrammarId,
                workId: workId,
                sentenceId: sentenceId,
                mediaType: mediaType,
                minedAt: minedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CollectedGrammarSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                collectedGrammarId = false,
                workId = false,
                sentenceId = false,
              }) {
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
                        if (collectedGrammarId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.collectedGrammarId,
                                    referencedTable:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._collectedGrammarIdTable(db),
                                    referencedColumn:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._collectedGrammarIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workId,
                                    referencedTable:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._workIdTable(db),
                                    referencedColumn:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._workIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sentenceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sentenceId,
                                    referencedTable:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._sentenceIdTable(db),
                                    referencedColumn:
                                        $$CollectedGrammarSourcesTableReferences
                                            ._sentenceIdTable(db)
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

typedef $$CollectedGrammarSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectedGrammarSourcesTable,
      CollectedGrammarSource,
      $$CollectedGrammarSourcesTableFilterComposer,
      $$CollectedGrammarSourcesTableOrderingComposer,
      $$CollectedGrammarSourcesTableAnnotationComposer,
      $$CollectedGrammarSourcesTableCreateCompanionBuilder,
      $$CollectedGrammarSourcesTableUpdateCompanionBuilder,
      (CollectedGrammarSource, $$CollectedGrammarSourcesTableReferences),
      CollectedGrammarSource,
      PrefetchHooks Function({
        bool collectedGrammarId,
        bool workId,
        bool sentenceId,
      })
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String?> llmApiKey,
      Value<bool> llmExplanationsEnabled,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String?> llmApiKey,
      Value<bool> llmExplanationsEnabled,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

  ColumnFilters<String> get llmApiKey => $composableBuilder(
    column: $table.llmApiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get llmExplanationsEnabled => $composableBuilder(
    column: $table.llmExplanationsEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

  ColumnOrderings<String> get llmApiKey => $composableBuilder(
    column: $table.llmApiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get llmExplanationsEnabled => $composableBuilder(
    column: $table.llmExplanationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get llmApiKey =>
      $composableBuilder(column: $table.llmApiKey, builder: (column) => column);

  GeneratedColumn<bool> get llmExplanationsEnabled => $composableBuilder(
    column: $table.llmExplanationsEnabled,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingsRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> llmApiKey = const Value.absent(),
                Value<bool> llmExplanationsEnabled = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                llmApiKey: llmApiKey,
                llmExplanationsEnabled: llmExplanationsEnabled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> llmApiKey = const Value.absent(),
                Value<bool> llmExplanationsEnabled = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                llmApiKey: llmApiKey,
                llmExplanationsEnabled: llmExplanationsEnabled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingsRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingsRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$SentenceExplanationsTableCreateCompanionBuilder =
    SentenceExplanationsCompanion Function({
      required String id,
      required String explanation,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SentenceExplanationsTableUpdateCompanionBuilder =
    SentenceExplanationsCompanion Function({
      Value<String> id,
      Value<String> explanation,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SentenceExplanationsTableFilterComposer
    extends Composer<_$AppDatabase, $SentenceExplanationsTable> {
  $$SentenceExplanationsTableFilterComposer({
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

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SentenceExplanationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SentenceExplanationsTable> {
  $$SentenceExplanationsTableOrderingComposer({
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

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SentenceExplanationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentenceExplanationsTable> {
  $$SentenceExplanationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SentenceExplanationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentenceExplanationsTable,
          SentenceExplanationRow,
          $$SentenceExplanationsTableFilterComposer,
          $$SentenceExplanationsTableOrderingComposer,
          $$SentenceExplanationsTableAnnotationComposer,
          $$SentenceExplanationsTableCreateCompanionBuilder,
          $$SentenceExplanationsTableUpdateCompanionBuilder,
          (
            SentenceExplanationRow,
            BaseReferences<
              _$AppDatabase,
              $SentenceExplanationsTable,
              SentenceExplanationRow
            >,
          ),
          SentenceExplanationRow,
          PrefetchHooks Function()
        > {
  $$SentenceExplanationsTableTableManager(
    _$AppDatabase db,
    $SentenceExplanationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentenceExplanationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SentenceExplanationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SentenceExplanationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentenceExplanationsCompanion(
                id: id,
                explanation: explanation,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String explanation,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SentenceExplanationsCompanion.insert(
                id: id,
                explanation: explanation,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SentenceExplanationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentenceExplanationsTable,
      SentenceExplanationRow,
      $$SentenceExplanationsTableFilterComposer,
      $$SentenceExplanationsTableOrderingComposer,
      $$SentenceExplanationsTableAnnotationComposer,
      $$SentenceExplanationsTableCreateCompanionBuilder,
      $$SentenceExplanationsTableUpdateCompanionBuilder,
      (
        SentenceExplanationRow,
        BaseReferences<
          _$AppDatabase,
          $SentenceExplanationsTable,
          SentenceExplanationRow
        >,
      ),
      SentenceExplanationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$SentencesTableTableManager get sentences =>
      $$SentencesTableTableManager(_db, _db.sentences);
  $$DictionariesTableTableManager get dictionaries =>
      $$DictionariesTableTableManager(_db, _db.dictionaries);
  $$DictionaryTagEntriesTableTableManager get dictionaryTagEntries =>
      $$DictionaryTagEntriesTableTableManager(_db, _db.dictionaryTagEntries);
  $$DictionaryTermEntriesTableTableManager get dictionaryTermEntries =>
      $$DictionaryTermEntriesTableTableManager(_db, _db.dictionaryTermEntries);
  $$DictionaryTermMetaEntriesTableTableManager get dictionaryTermMetaEntries =>
      $$DictionaryTermMetaEntriesTableTableManager(
        _db,
        _db.dictionaryTermMetaEntries,
      );
  $$CollectedWordsTableTableManager get collectedWords =>
      $$CollectedWordsTableTableManager(_db, _db.collectedWords);
  $$CollectedWordSourcesTableTableManager get collectedWordSources =>
      $$CollectedWordSourcesTableTableManager(_db, _db.collectedWordSources);
  $$CollectedGrammarsTableTableManager get collectedGrammars =>
      $$CollectedGrammarsTableTableManager(_db, _db.collectedGrammars);
  $$CollectedGrammarSourcesTableTableManager get collectedGrammarSources =>
      $$CollectedGrammarSourcesTableTableManager(
        _db,
        _db.collectedGrammarSources,
      );
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SentenceExplanationsTableTableManager get sentenceExplanations =>
      $$SentenceExplanationsTableTableManager(_db, _db.sentenceExplanations);
}
