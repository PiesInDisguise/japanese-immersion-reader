// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sentence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Sentence {

 String get id; int get index; List<Token> get tokens;
/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SentenceCopyWith<Sentence> get copyWith => _$SentenceCopyWithImpl<Sentence>(this as Sentence, _$identity);

  /// Serializes this Sentence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sentence&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&const DeepCollectionEquality().equals(other.tokens, tokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,index,const DeepCollectionEquality().hash(tokens));

@override
String toString() {
  return 'Sentence(id: $id, index: $index, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class $SentenceCopyWith<$Res>  {
  factory $SentenceCopyWith(Sentence value, $Res Function(Sentence) _then) = _$SentenceCopyWithImpl;
@useResult
$Res call({
 String id, int index, List<Token> tokens
});




}
/// @nodoc
class _$SentenceCopyWithImpl<$Res>
    implements $SentenceCopyWith<$Res> {
  _$SentenceCopyWithImpl(this._self, this._then);

  final Sentence _self;
  final $Res Function(Sentence) _then;

/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? index = null,Object? tokens = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as List<Token>,
  ));
}

}


/// Adds pattern-matching-related methods to [Sentence].
extension SentencePatterns on Sentence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sentence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sentence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sentence value)  $default,){
final _that = this;
switch (_that) {
case _Sentence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sentence value)?  $default,){
final _that = this;
switch (_that) {
case _Sentence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int index,  List<Token> tokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sentence() when $default != null:
return $default(_that.id,_that.index,_that.tokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int index,  List<Token> tokens)  $default,) {final _that = this;
switch (_that) {
case _Sentence():
return $default(_that.id,_that.index,_that.tokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int index,  List<Token> tokens)?  $default,) {final _that = this;
switch (_that) {
case _Sentence() when $default != null:
return $default(_that.id,_that.index,_that.tokens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sentence extends Sentence {
  const _Sentence({required this.id, required this.index, required final  List<Token> tokens}): _tokens = tokens,super._();
  factory _Sentence.fromJson(Map<String, dynamic> json) => _$SentenceFromJson(json);

@override final  String id;
@override final  int index;
 final  List<Token> _tokens;
@override List<Token> get tokens {
  if (_tokens is EqualUnmodifiableListView) return _tokens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tokens);
}


/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SentenceCopyWith<_Sentence> get copyWith => __$SentenceCopyWithImpl<_Sentence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SentenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sentence&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&const DeepCollectionEquality().equals(other._tokens, _tokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,index,const DeepCollectionEquality().hash(_tokens));

@override
String toString() {
  return 'Sentence(id: $id, index: $index, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class _$SentenceCopyWith<$Res> implements $SentenceCopyWith<$Res> {
  factory _$SentenceCopyWith(_Sentence value, $Res Function(_Sentence) _then) = __$SentenceCopyWithImpl;
@override @useResult
$Res call({
 String id, int index, List<Token> tokens
});




}
/// @nodoc
class __$SentenceCopyWithImpl<$Res>
    implements _$SentenceCopyWith<$Res> {
  __$SentenceCopyWithImpl(this._self, this._then);

  final _Sentence _self;
  final $Res Function(_Sentence) _then;

/// Create a copy of Sentence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? index = null,Object? tokens = null,}) {
  return _then(_Sentence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,tokens: null == tokens ? _self._tokens : tokens // ignore: cast_nullable_to_non_nullable
as List<Token>,
  ));
}


}

// dart format on
