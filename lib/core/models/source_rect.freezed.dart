// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_rect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SourceRect {

 int get pageIndex; double get x; double get y; double get width; double get height; double get pageWidth; double get pageHeight;
/// Create a copy of SourceRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceRectCopyWith<SourceRect> get copyWith => _$SourceRectCopyWithImpl<SourceRect>(this as SourceRect, _$identity);

  /// Serializes this SourceRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceRect&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.pageWidth, pageWidth) || other.pageWidth == pageWidth)&&(identical(other.pageHeight, pageHeight) || other.pageHeight == pageHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageIndex,x,y,width,height,pageWidth,pageHeight);

@override
String toString() {
  return 'SourceRect(pageIndex: $pageIndex, x: $x, y: $y, width: $width, height: $height, pageWidth: $pageWidth, pageHeight: $pageHeight)';
}


}

/// @nodoc
abstract mixin class $SourceRectCopyWith<$Res>  {
  factory $SourceRectCopyWith(SourceRect value, $Res Function(SourceRect) _then) = _$SourceRectCopyWithImpl;
@useResult
$Res call({
 int pageIndex, double x, double y, double width, double height, double pageWidth, double pageHeight
});




}
/// @nodoc
class _$SourceRectCopyWithImpl<$Res>
    implements $SourceRectCopyWith<$Res> {
  _$SourceRectCopyWithImpl(this._self, this._then);

  final SourceRect _self;
  final $Res Function(SourceRect) _then;

/// Create a copy of SourceRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageIndex = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? pageWidth = null,Object? pageHeight = null,}) {
  return _then(_self.copyWith(
pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,pageWidth: null == pageWidth ? _self.pageWidth : pageWidth // ignore: cast_nullable_to_non_nullable
as double,pageHeight: null == pageHeight ? _self.pageHeight : pageHeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceRect].
extension SourceRectPatterns on SourceRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceRect value)  $default,){
final _that = this;
switch (_that) {
case _SourceRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceRect value)?  $default,){
final _that = this;
switch (_that) {
case _SourceRect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pageIndex,  double x,  double y,  double width,  double height,  double pageWidth,  double pageHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceRect() when $default != null:
return $default(_that.pageIndex,_that.x,_that.y,_that.width,_that.height,_that.pageWidth,_that.pageHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pageIndex,  double x,  double y,  double width,  double height,  double pageWidth,  double pageHeight)  $default,) {final _that = this;
switch (_that) {
case _SourceRect():
return $default(_that.pageIndex,_that.x,_that.y,_that.width,_that.height,_that.pageWidth,_that.pageHeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pageIndex,  double x,  double y,  double width,  double height,  double pageWidth,  double pageHeight)?  $default,) {final _that = this;
switch (_that) {
case _SourceRect() when $default != null:
return $default(_that.pageIndex,_that.x,_that.y,_that.width,_that.height,_that.pageWidth,_that.pageHeight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceRect implements SourceRect {
  const _SourceRect({required this.pageIndex, required this.x, required this.y, required this.width, required this.height, required this.pageWidth, required this.pageHeight});
  factory _SourceRect.fromJson(Map<String, dynamic> json) => _$SourceRectFromJson(json);

@override final  int pageIndex;
@override final  double x;
@override final  double y;
@override final  double width;
@override final  double height;
@override final  double pageWidth;
@override final  double pageHeight;

/// Create a copy of SourceRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceRectCopyWith<_SourceRect> get copyWith => __$SourceRectCopyWithImpl<_SourceRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceRect&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.pageWidth, pageWidth) || other.pageWidth == pageWidth)&&(identical(other.pageHeight, pageHeight) || other.pageHeight == pageHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageIndex,x,y,width,height,pageWidth,pageHeight);

@override
String toString() {
  return 'SourceRect(pageIndex: $pageIndex, x: $x, y: $y, width: $width, height: $height, pageWidth: $pageWidth, pageHeight: $pageHeight)';
}


}

/// @nodoc
abstract mixin class _$SourceRectCopyWith<$Res> implements $SourceRectCopyWith<$Res> {
  factory _$SourceRectCopyWith(_SourceRect value, $Res Function(_SourceRect) _then) = __$SourceRectCopyWithImpl;
@override @useResult
$Res call({
 int pageIndex, double x, double y, double width, double height, double pageWidth, double pageHeight
});




}
/// @nodoc
class __$SourceRectCopyWithImpl<$Res>
    implements _$SourceRectCopyWith<$Res> {
  __$SourceRectCopyWithImpl(this._self, this._then);

  final _SourceRect _self;
  final $Res Function(_SourceRect) _then;

/// Create a copy of SourceRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageIndex = null,Object? x = null,Object? y = null,Object? width = null,Object? height = null,Object? pageWidth = null,Object? pageHeight = null,}) {
  return _then(_SourceRect(
pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,pageWidth: null == pageWidth ? _self.pageWidth : pageWidth // ignore: cast_nullable_to_non_nullable
as double,pageHeight: null == pageHeight ? _self.pageHeight : pageHeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
