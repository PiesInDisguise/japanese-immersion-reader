# vendor/

Local copies of third-party packages patched for this project's specific
Android toolchain combination, pulled in via `dependency_overrides` in the
top-level `pubspec.yaml`. (The Rust `sudachi` crate has its own,
separately-documented vendor copy at `rust/vendor/` -- see that directory's
own README.)

## file_picker

Copy of `file_picker` 11.0.2 (from pub.dev's cache, `example/` dropped),
with one file patched: `android/build.gradle`.

This project builds Android with `android.builtInKotlin=false` (see
`android/gradle.properties`'s own comment for the full reasoning --
short version: AGP9's built-in Kotlin conflicts with `audioplayers_android`
5.3.0, an unrelated plugin also used here, which applies the separate
Kotlin plugin unconditionally). Upstream `file_picker` 11.0.2 detects AGP9+
and skips applying that same plugin, assuming built-in Kotlin is doing the
work instead -- under this project's `builtInKotlin=false`, that means
nothing ever compiles `FilePickerPlugin.kt`, and the build fails with
"cannot find symbol class FilePickerPlugin". Patched
`android/build.gradle` to always apply `org.jetbrains.kotlin.android`
(file_picker's own pre-11.0.0 behavior), matching what
`audioplayers_android` already expects.

Re-vendor if bumping the `file_picker` version: re-copy from pub cache,
reapply this same change (always-apply the Kotlin plugin, drop the
`isAgp9OrAbove` conditional), and check whether AGP9/builtInKotlin support
across this project's actual plugin set has stabilized enough that this
whole workaround (and `android.builtInKotlin=false`) can be dropped instead.
