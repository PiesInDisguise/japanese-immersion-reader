// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TokenizerError {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenizerError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TokenizerError()';
}


}

/// @nodoc
class $TokenizerErrorCopyWith<$Res>  {
$TokenizerErrorCopyWith(TokenizerError _, $Res Function(TokenizerError) __);
}


/// Adds pattern-matching-related methods to [TokenizerError].
extension TokenizerErrorPatterns on TokenizerError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TokenizerError_DictionaryLoad value)?  dictionaryLoad,TResult Function( TokenizerError_Tokenization value)?  tokenization,TResult Function( TokenizerError_NotInitialized value)?  notInitialized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad() when dictionaryLoad != null:
return dictionaryLoad(_that);case TokenizerError_Tokenization() when tokenization != null:
return tokenization(_that);case TokenizerError_NotInitialized() when notInitialized != null:
return notInitialized(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TokenizerError_DictionaryLoad value)  dictionaryLoad,required TResult Function( TokenizerError_Tokenization value)  tokenization,required TResult Function( TokenizerError_NotInitialized value)  notInitialized,}){
final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad():
return dictionaryLoad(_that);case TokenizerError_Tokenization():
return tokenization(_that);case TokenizerError_NotInitialized():
return notInitialized(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TokenizerError_DictionaryLoad value)?  dictionaryLoad,TResult? Function( TokenizerError_Tokenization value)?  tokenization,TResult? Function( TokenizerError_NotInitialized value)?  notInitialized,}){
final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad() when dictionaryLoad != null:
return dictionaryLoad(_that);case TokenizerError_Tokenization() when tokenization != null:
return tokenization(_that);case TokenizerError_NotInitialized() when notInitialized != null:
return notInitialized(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String field0)?  dictionaryLoad,TResult Function( String field0)?  tokenization,TResult Function()?  notInitialized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad() when dictionaryLoad != null:
return dictionaryLoad(_that.field0);case TokenizerError_Tokenization() when tokenization != null:
return tokenization(_that.field0);case TokenizerError_NotInitialized() when notInitialized != null:
return notInitialized();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String field0)  dictionaryLoad,required TResult Function( String field0)  tokenization,required TResult Function()  notInitialized,}) {final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad():
return dictionaryLoad(_that.field0);case TokenizerError_Tokenization():
return tokenization(_that.field0);case TokenizerError_NotInitialized():
return notInitialized();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String field0)?  dictionaryLoad,TResult? Function( String field0)?  tokenization,TResult? Function()?  notInitialized,}) {final _that = this;
switch (_that) {
case TokenizerError_DictionaryLoad() when dictionaryLoad != null:
return dictionaryLoad(_that.field0);case TokenizerError_Tokenization() when tokenization != null:
return tokenization(_that.field0);case TokenizerError_NotInitialized() when notInitialized != null:
return notInitialized();case _:
  return null;

}
}

}

/// @nodoc


class TokenizerError_DictionaryLoad extends TokenizerError {
  const TokenizerError_DictionaryLoad(this.field0): super._();
  

 final  String field0;

/// Create a copy of TokenizerError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenizerError_DictionaryLoadCopyWith<TokenizerError_DictionaryLoad> get copyWith => _$TokenizerError_DictionaryLoadCopyWithImpl<TokenizerError_DictionaryLoad>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenizerError_DictionaryLoad&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TokenizerError.dictionaryLoad(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TokenizerError_DictionaryLoadCopyWith<$Res> implements $TokenizerErrorCopyWith<$Res> {
  factory $TokenizerError_DictionaryLoadCopyWith(TokenizerError_DictionaryLoad value, $Res Function(TokenizerError_DictionaryLoad) _then) = _$TokenizerError_DictionaryLoadCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$TokenizerError_DictionaryLoadCopyWithImpl<$Res>
    implements $TokenizerError_DictionaryLoadCopyWith<$Res> {
  _$TokenizerError_DictionaryLoadCopyWithImpl(this._self, this._then);

  final TokenizerError_DictionaryLoad _self;
  final $Res Function(TokenizerError_DictionaryLoad) _then;

/// Create a copy of TokenizerError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TokenizerError_DictionaryLoad(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TokenizerError_Tokenization extends TokenizerError {
  const TokenizerError_Tokenization(this.field0): super._();
  

 final  String field0;

/// Create a copy of TokenizerError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenizerError_TokenizationCopyWith<TokenizerError_Tokenization> get copyWith => _$TokenizerError_TokenizationCopyWithImpl<TokenizerError_Tokenization>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenizerError_Tokenization&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'TokenizerError.tokenization(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $TokenizerError_TokenizationCopyWith<$Res> implements $TokenizerErrorCopyWith<$Res> {
  factory $TokenizerError_TokenizationCopyWith(TokenizerError_Tokenization value, $Res Function(TokenizerError_Tokenization) _then) = _$TokenizerError_TokenizationCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$TokenizerError_TokenizationCopyWithImpl<$Res>
    implements $TokenizerError_TokenizationCopyWith<$Res> {
  _$TokenizerError_TokenizationCopyWithImpl(this._self, this._then);

  final TokenizerError_Tokenization _self;
  final $Res Function(TokenizerError_Tokenization) _then;

/// Create a copy of TokenizerError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(TokenizerError_Tokenization(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TokenizerError_NotInitialized extends TokenizerError {
  const TokenizerError_NotInitialized(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenizerError_NotInitialized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TokenizerError.notInitialized()';
}


}




// dart format on
