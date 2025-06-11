// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$markersHash() => r'1b872b5c6d62bf632d8bf9d4ea27ffa49eb4d6f6';

/// See also [Markers].
@ProviderFor(Markers)
final markersProvider =
    AutoDisposeAsyncNotifierProvider<Markers, List<MapMarker>>.internal(
  Markers.new,
  name: r'markersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$markersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Markers = AutoDisposeAsyncNotifier<List<MapMarker>>;
String _$selectedPlaceHash() => r'72580ca231c9395aa58a137ddc047c68dd4b4903';

/// ─────────────────── 1. Notifier para el lugar seleccionado ───────────────────
///
/// Copied from [SelectedPlace].
@ProviderFor(SelectedPlace)
final selectedPlaceProvider =
    AutoDisposeNotifierProvider<SelectedPlace, PlaceInformation?>.internal(
  SelectedPlace.new,
  name: r'selectedPlaceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPlaceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedPlace = AutoDisposeNotifier<PlaceInformation?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
