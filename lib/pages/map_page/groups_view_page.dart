import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import 'package:first_maps_project/widgets/models/group.dart';

/// Displays all group icons (pinIcon) for the active map and allows adding the given place to a group.
/// Returns [MapMarker] when a group is selected or created, or null on cancel.
class GroupsViewPage extends ConsumerWidget {
  final MapMarker? currentMarker;

  const GroupsViewPage({
    super.key,
    this.currentMarker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener grupos y marcadores
    final groupsAsync = ref.watch(groupsStateProvider);
    final markersAsync = ref.watch(markersStateProvider);
    final currentMarker = this.currentMarker;

    // Solo observamos si el mapa y lugar existen, no sus valores completos
    final hasRequiredData = ref.watch(
      Provider.autoDispose((ref) {
        final hasMap = ref.watch(activeMapProvider.select((map) => map != null));
        final hasPlace = ref.watch(selectedPlaceProvider.select((place) => place != null));
        return hasMap && hasPlace;
      })
    );

    if (!hasRequiredData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign to Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: groupsAsync.when(
        data: (groups) {
          return markersAsync.when(
            data: (markers) {
              // Armar lista de grupos con cantidad de lugares
              final groupEntries = groups.map((group) {
                final count = markers.where((m) => m.groupId == group.id).length;
                final isCurrent = currentMarker?.groupId == group.id;
                return MapEntry(group, _GroupInfo(count: count, name: group.name, emoji: group.emoji, isCurrent: isCurrent));
              }).toList();

              return ListView.separated(
                itemCount: groupEntries.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Create & Add New Group'),
                      onTap: () => _createAndAddGroup(context, ref),
                    );
                  }
                  final entry = groupEntries[index - 1];
                  final group = entry.key;
                  final info = entry.value;
                  return ListTile(
                    leading: Text(info.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(info.name),
                    subtitle: Text('${info.count} ${info.count == 1 ? 'place' : 'places'}'),
                    selected: info.isCurrent,
                    selectedTileColor: Colors.lightBlueAccent.withOpacity(0.3),
                    enabled: !info.isCurrent,
                    onTap: info.isCurrent ? null : () => _addToGroup(context, ref, group.id!),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _addToGroup(BuildContext context, WidgetRef ref, String groupId) async {
    final activeMap = ref.read(activeMapProvider);
    final selectedPlace = ref.read(selectedPlaceProvider);

    if (activeMap == null || selectedPlace == null) {
      Navigator.pop(context);
      return;
    }

    if (currentMarker != null && currentMarker!.markerId != null) {
      // Update existing marker
      final updated = currentMarker!.copyWith(groupId: groupId);
      await ref.read(markersStateProvider.notifier).updateMarker(updated);
      if (!context.mounted) return;
      Navigator.pop(context, updated);
    } else {
      // Create a new marker
      final marker = MapMarker(
        markerId: null,
        detailsId: selectedPlace.placeId,
        mapId: activeMap.id!,
        groupId: groupId,
        information: selectedPlace,
      );
      await ref.read(markersStateProvider.notifier).addMarker(marker);
      if (!context.mounted) return;
      Navigator.pop(context, marker);
    }
  }

  Future<void> _createAndAddGroup(BuildContext context, WidgetRef ref) async {
    String? selectedEmoji;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool _showErrors = false;

    try {
      final result = await showDialog<Map<String, String>?>(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Create New Group'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: _showErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji Selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showErrors && selectedEmoji == null ? Colors.red : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Group Emoji',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (_showErrors && selectedEmoji == null) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  '(Required)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final emoji = await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 4,
                                        width: 40,
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      Expanded(
                                        child: EmojiPicker(
                                          onEmojiSelected: (category, emoji) {
                                            Navigator.pop(context, emoji.emoji);
                                          },
                                          config: Config(
                                            columns: 7,
                                            emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                                            verticalSpacing: 0,
                                            horizontalSpacing: 0,
                                            initCategory: Category.SMILEYS,
                                            bgColor: Theme.of(context).scaffoldBackgroundColor,
                                            indicatorColor: Theme.of(context).colorScheme.primary,
                                            iconColor: Colors.grey,
                                            iconColorSelected: Theme.of(context).colorScheme.primary,
                                            buttonMode: ButtonMode.MATERIAL,
                                            enableSkinTones: true,
                                            recentTabBehavior: RecentTabBehavior.RECENT,
                                            recentsLimit: 28,
                                            noRecents: const Text(
                                              'No Recents',
                                              style: TextStyle(fontSize: 20, color: Colors.black26),
                                              textAlign: TextAlign.center,
                                            ),
                                            loadingIndicator: const CircularProgressIndicator(),
                                            tabIndicatorAnimDuration: kTabScrollDuration,
                                            categoryIcons: const CategoryIcons(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (emoji != null) {
                                setState(() => selectedEmoji = emoji);
                              }
                            },
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: selectedEmoji != null
                                  ? Text(
                                      selectedEmoji!,
                                      style: const TextStyle(fontSize: 32),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                          'Tap to select emoji',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g. Favorite Restaurants',
                        helperText: 'Max 20 characters',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a group name';
                        }
                        if (value.length > 20) {
                          return 'Name must be 20 characters or less';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Group Description (Optional)',
                        hintText: 'e.g. My favorite places to eat',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (selectedEmoji == null) {
                          setState(() => _showErrors = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an emoji'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() => _showErrors = true);
                        if (formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          try {
                            Navigator.pop(context, {
                              'emoji': selectedEmoji!,
                              'name': nameController.text.trim(),
                              'description': descriptionController.text.trim(),
                            });
                          } finally {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Group'),
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        // Crear el grupo en Firestore y obtener el ID
        final activeMap = ref.read(activeMapProvider);
        final groupsNotifier = ref.read(groupsStateProvider.notifier);
        final newGroup = Group(
          id: null,
          mapId: activeMap!.id!,
          emoji: result['emoji']!,
          name: result['name']!,
          description: result['description'],
        );
        final groupId = await groupsNotifier.addGroupAndReturnId(newGroup);
        await _addToGroup(context, ref, groupId);
      }
    } finally {
      nameController.dispose();
      descriptionController.dispose();
    }
  }
}

class _GroupInfo {
  final int count;
  final String name;
  final String emoji;
  final bool isCurrent;

  _GroupInfo({required this.count, required this.name, required this.emoji, required this.isCurrent});
}
