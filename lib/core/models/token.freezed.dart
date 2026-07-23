// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Token {

 String get surface; String? get dictForm; String? get reading; String? get pos; String? get inflection; SourceRect? get sourceRect;
/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenCopyWith<Token> get copyWith => _$TokenCopyWithImpl<Token>(this as Token, _$identity);

  /// Serializes this Token to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Token&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.dictForm, dictForm) || other.dictForm == dictForm)&&(identical(other.reading, reading) || other.reading == reading)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.inflection, inflection) || other.inflection == inflection)&&(identical(other.sourceRect, sourceRect) || other.sourceRect == sourceRect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,surface,dictForm,reading,pos,inflection,sourceRect);

@override
String toString() {
  return 'Token(surface: $surface, dictForm: $dictForm, reading: $reading, pos: $pos, inflection: $inflection, sourceRect: $sourceRect)';
}


}

/// @nodoc
abstract mixin class $TokenCopyWith<$Res>  {
  factory $TokenCopyWith(Token value, $Res Function(Token) _then) = _$TokenCopyWithImpl;
@useResult
$Res call({
 String surface, String? dictForm, String? reading, String? pos, String? inflection, SourceRect? sourceRect
});


$SourceRectCopyWith<$Res>? get sourceRect;

}
/// @nodoc
class _$TokenCopyWithImpl<$Res>
    implements $TokenCopyWith<$Res> {
  _$TokenCopyWithImpl(this._self, this._then);

  final Token _self;
  final $Res Function(Token) _then;

/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? surface = null,Object? dictForm = freezed,Object? reading = freezed,Object? pos = freezed,Object? inflection = freezed,Object? sourceRect = freezed,}) {
  return _then(_self.copyWith(
surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,dictForm: freezed == dictForm ? _self.dictForm : dictForm // ignore: cast_nullable_to_non_nullable
as String?,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,pos: freezed == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as String?,inflection: freezed == inflection ? _self.inflection : inflection // ignore: cast_nullable_to_non_nullable
as String?,sourceRect: freezed == sourceRect ? _self.sourceRect : sourceRect // ignore: cast_nullable_to_non_nullable
as SourceRect?,
  ));
}
/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourceRectCopyWith<$Res>? get sourceRect {
    if (_self.sourceRect == null) {
    return null;
  }

  return $SourceRectCopyWith<$Res>(_self.sourceRect!, (value) {
    return _then(_self.copyWith(sourceRect: value));
  });
}
}


/// Adds pattern-matching-related methods to [Token].
extension TokenPatterns on Token {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Token value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Token() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Token value)  $default,){
final _that = this;
switch (_that) {
case _Token():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Token value)?  $default,){
final _that = this;
switch (_that) {
case _Token() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String surface,  String? dictForm,  String? reading,  String? pos,  String? inflection,  SourceRect? sourceRect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Token() when $default != null:
return $default(_that.surface,_that.dictForm,_that.reading,_that.pos,_that.inflection,_that.sourceRect);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String surface,  String? dictForm,  String? reading,  String? pos,  String? inflection,  SourceRect? sourceRect)  $default,) {final _that = this;
switch (_that) {
case _Token():
return $default(_that.surface,_that.dictForm,_that.reading,_that.pos,_that.inflection,_that.sourceRect);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String surface,  String? dictForm,  String? reading,  String? pos,  String? inflection,  SourceRect? sourceRect)?  $default,) {final _that = this;
switch (_that) {
case _Token() when $default != null:
return $default(_that.surface,_that.dictForm,_that.reading,_that.pos,_that.inflection,_that.sourceRect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Token implements Token {
  const _Token({required this.surface, this.dictForm, this.reading, this.pos, this.inflection, this.sourceRect});
  factory _Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

@override final  String surface;
@override final  String? dictForm;
@override final  String? reading;
@override final  String? pos;
@override final  String? inflection;
@override final  SourceRect? sourceRect;

/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenCopyWith<_Token> get copyWith => __$TokenCopyWithImpl<_Token>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Token&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.dictForm, dictForm) || other.dictForm == dictForm)&&(identical(other.reading, reading) || other.reading == reading)&&(identical(other.pos, pos) || other.pos == pos)&&(identical(other.inflection, inflection) || other.inflection == inflection)&&(identical(other.sourceRect, sourceRect) || other.sourceRect == sourceRect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,surface,dictForm,reading,pos,inflection,sourceRect);

@override
String toString() {
  return 'Token(surface: $surface, dictForm: $dictForm, reading: $reading, pos: $pos, inflection: $inflection, sourceRect: $sourceRect)';
}


}

/// @nodoc
abstract mixin class _$TokenCopyWith<$Res> implements $TokenCopyWith<$Res> {
  factory _$TokenCopyWith(_Token value, $Res Function(_Token) _then) = __$TokenCopyWithImpl;
@override @useResult
$Res call({
 String surface, String? dictForm, String? reading, String? pos, String? inflection, SourceRect? sourceRect
});


@override $SourceRectCopyWith<$Res>? get sourceRect;

}
/// @nodoc
class __$TokenCopyWithImpl<$Res>
    implements _$TokenCopyWith<$Res> {
  __$TokenCopyWithImpl(this._self, this._then);

  final _Token _self;
  final $Res Function(_Token) _then;

/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? surface = null,Object? dictForm = freezed,Object? reading = freezed,Object? pos = freezed,Object? inflection = freezed,Object? sourceRect = freezed,}) {
  return _then(_Token(
surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,dictForm: freezed == dictForm ? _self.dictForm : dictForm // ignore: cast_nullable_to_non_nullable
as String?,reading: freezed == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as String?,pos: freezed == pos ? _self.pos : pos // ignore: cast_nullable_to_non_nullable
as String?,inflection: freezed == inflection ? _self.inflection : inflection // ignore: cast_nullable_to_non_nullable
as String?,sourceRect: freezed == sourceRect ? _self.sourceRect : sourceRect // ignore: cast_nullable_to_non_nullable
as SourceRect?,
  ));
}

/// Create a copy of Token
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourceRectCopyWith<$Res>? get sourceRect {
    if (_self.sourceRect == null) {
    return null;
  }

  return $SourceRectCopyWith<$Res>(_self.sourceRect!, (value) {
    return _then(_self.copyWith(sourceRect: value));
  });
}
}

// dart format on
