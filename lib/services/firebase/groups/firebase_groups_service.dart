import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:flutter/foundation.dart';

/// Service to manage Group records in Firestore.
/// Collection: 'groups'
class FirebaseGroupsService {
  final CollectionReference _groupsRef =
      FirebaseFirestore.instance.collection('groups');

  /// Adds a new Group document in 'groups'.
  Future<String> addGroup(Group group) async {
    try {
      final docRef = await _groupsRef.add({
        'map_id': group.mapId,
        'name': group.name,
        'emoji': group.emoji,
        'description': group.description,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (error) {
      print('Error adding group: $error');
      rethrow;
    }
  }

  /// Deletes a group by its ID.
  Future<void> removeGroup(String groupId) async {
    try {
      await _groupsRef.doc(groupId).delete();
    } catch (error) {
      print('Error removing group $groupId: $error');
      rethrow;
    }
  }

  /// Updates a group
  Future<void> updateGroup(Group group) async {
    if (group.id == null) {
      throw ArgumentError('Cannot update a group without an ID');
    }
    try {
      await _groupsRef.doc(group.id!).update({
        'name': group.name,
        'emoji': group.emoji,
        'description': group.description,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error updating group ${group.id}: $error');
      rethrow;
    }
  }

  /// Retrieves a single Group by its ID, or null if not found
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _groupsRef.doc(groupId).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return Group.fromFirestore(data, doc.id);
    } catch (error) {
      print('Error getting group $groupId: $error');
      rethrow;
    }
  }

  /// Retrieves all groups associated with a given mapId
  Future<List<Group>> getGroupsByMapId(String mapId) async {
    try {
      debugPrint('[FirebaseGroupsService] getGroupsByMapId: querying for mapId=$mapId');
      final snapshot = await _groupsRef
          .where('map_id', isEqualTo: mapId)
          .get();
      
      debugPrint('[FirebaseGroupsService] getGroupsByMapId: got ${snapshot.docs.length} results');
      
      final groups = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('[FirebaseGroupsService] getGroupsByMapId: doc=${doc.id} data=$data');
        return await Group.fromFirestoreAsync(data, doc.id);
      }));

      debugPrint('[FirebaseGroupsService] getGroupsByMapId: returning groups=$groups');
      return groups;
    } catch (error) {
      debugPrint('[FirebaseGroupsService] getGroupsByMapId: error getting groups for map $mapId: $error');
      rethrow;
    }
  }

  /// Stream of groups for a given map
  Stream<List<Group>> streamGroupsByMapId(String mapId) {
    return _groupsRef
        .where('map_id', isEqualTo: mapId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Group.fromFirestore(data, doc.id);
            }).toList());
  }
} 