import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/services/maps/emoji_marker_converter.dart';
import 'package:flutter/material.dart';

/// Model representing a Group in Firestore.
class Group {
  /// Firestore document ID
  final String? id;
  /// ID of the map this group belongs to
  final String mapId;
  /// Name of the group
  final String name;
  /// Optional description of the group
  final String? description;
  /// Emoji used as the group's icon
  final String emoji;
  /// Runtime-only flag to indicate if the group is active
  final bool active;
  
  // Cache for the converted marker icon
  BitmapDescriptor? _markerIcon;

  Group({
    this.id,
    required this.mapId,
    required this.emoji,
    required this.name,
    this.description,
    this.active = true,
  });

  /// Get the marker icon for this group
  Future<BitmapDescriptor> getMarkerIcon({
    double size = 100,
    bool forceRefresh = false,
    Color borderColor = Colors.black,
    double borderWidth = 2,
  }) async {
    if (_markerIcon != null && !forceRefresh) {
      return _markerIcon!;
    }

    _markerIcon = await EmojiMarkerConverter.convertEmojiToMarkerIcon(
      emoji,
      size: size,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
    return _markerIcon!;
  }

  /// Creates a copy of this Group with the given fields replaced with new values
  Group copyWith({
    String? id,
    String? mapId,
    String? emoji,
    String? name,
    String? description,
    bool? active,
  }) {
    return Group(
      id: id ?? this.id,
      mapId: mapId ?? this.mapId,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
    );
  }

  /// Creates a Group from Firestore data
  factory Group.fromFirestore(Map<String, dynamic> data, String id) {
    return Group(
      id: id,
      mapId: data['map_id'] as String,
      emoji: data['emoji'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
    );
  }

  /// Converts this Group to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'map_id': mapId,
      'name': name,
      'description': description,
      'emoji': emoji,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Async factory to create a Group and generate its marker icon
  static Future<Group> createWithIcon({
    String? id,
    required String mapId,
    required String emoji,
    required String name,
    String? description,
    bool active = true,
    double size = 100,
    Color borderColor = Colors.black,
    double borderWidth = 2,
  }) async {
    final group = Group(
      id: id,
      mapId: mapId,
      emoji: emoji,
      name: name,
      description: description,
      active: active,
    );
    group._markerIcon = await EmojiMarkerConverter.convertEmojiToMarkerIcon(
      emoji,
      size: size,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
    return group;
  }

  /// Async factory to create a Group from Firestore and generate its marker icon
  static Future<Group> fromFirestoreAsync(Map<String, dynamic> data, String id) async {
    return await Group.createWithIcon(
      id: id,
      mapId: data['map_id'] as String,
      emoji: data['emoji'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          id == other.id &&
          mapId == other.mapId &&
          name == other.name &&
          description == other.description &&
          emoji == other.emoji;

  @override
  int get hashCode =>
      id.hashCode ^
      mapId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      emoji.hashCode;

  @override
  String toString() {
    return 'Group{id: $id, mapId: $mapId, name: $name, description: $description, emoji: $emoji, active: $active}';
  }
} 