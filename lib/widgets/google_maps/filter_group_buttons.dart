import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:first_maps_project/widgets/models/group.dart';
import 'package:first_maps_project/providers/maps/map_providers.dart';

class FilterGroupButtons extends ConsumerStatefulWidget {
  const FilterGroupButtons({Key? key}) : super(key: key);

  @override
  ConsumerState<FilterGroupButtons> createState() => _FilterGroupButtonsState();
}

class _FilterGroupButtonsState extends ConsumerState<FilterGroupButtons> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _onGroupTap(List<Group> groups, Group tapped) async {
    debugPrint('[GroupFilter] Tap on group: emoji=${tapped.emoji}, id=${tapped.id}, active=${tapped.active}');
    final activeGroupsBefore = groups.where((g) => g.active).toList();
    debugPrint('[GroupFilter] Active groups before tap: ${activeGroupsBefore.map((g) => g.emoji).join(", ")}');
    final notifier = ref.read(groupsStateProvider.notifier);
    // If all groups are active, deactivate all and activate only tapped
    if (activeGroupsBefore.length == groups.length) {
      for (final g in groups) {
        notifier.toggleGroupActive(g.id!);
      }
      notifier.toggleGroupActive(tapped.id!); // Activate tapped
    } else if (tapped.active) {
      // If tapped group is active
      if (activeGroupsBefore.length == 1) {
        // If it was the only active group, activate all others except this one
        for (final g in groups) {
          if (g.id != tapped.id) {
            notifier.toggleGroupActive(g.id!);
          }
        }
        notifier.toggleGroupActive(tapped.id!); // Deactivate tapped
      } else {
        notifier.toggleGroupActive(tapped.id!); // Deactivate tapped
      }
    } else {
      // If tapped group is inactive, activate it
      notifier.toggleGroupActive(tapped.id!);
    }
    // After toggling, update the filter
    final updatedGroups = ref.read(groupsStateProvider).maybeWhen(
      data: (g) => g,
      orElse: () => <Group>[],
    );
    final activeIds = updatedGroups.where((g) => g.active).map((g) => g.id!).toList();
    debugPrint('[GroupFilter] Active groups after tap: ${updatedGroups.where((g) => g.active).map((g) => g.emoji).join(", ")}');
    debugPrint('[GroupFilter] Calling groupFilter with active group ids: $activeIds');
    await ref.read(googleMapMarkersProvider.notifier).groupFilter();
    // Log pins count after filter
    final pinsCount = ref.read(googleMapMarkersProvider).maybeWhen(
      data: (pins) => pins.length,
      orElse: () => 0,
    );
    debugPrint('[GroupFilter] Pins shown after filter: $pinsCount');
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStateProvider);
    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();
        final expandedHeight = 48.0 + (_expanded ? groups.length * 60.0 : 0.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: expandedHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Main button (filter or plus) - painted at the bottom
              GestureDetector(
                onTap: _toggleExpand,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
                      child: _expanded
                          ? const Icon(Icons.add, key: ValueKey('plus'), size: 24, color: Colors.black87)
                          : const Icon(Icons.filter_alt, key: ValueKey('filter'), size: 24, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              // Group buttons (expand upwards) - painted on top
              ...List.generate(groups.length, (i) {
                final group = groups[i];
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  bottom: _expanded ? (60.0 * (i + 1)) : 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _expanded ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !_expanded,
                      child: _GroupCircleButton(
                        emoji: group.emoji,
                        active: group.active,
                        onTap: () => _onGroupTap(groups, group),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _GroupCircleButton extends StatelessWidget {
  final String emoji;
  final bool active;
  final VoidCallback onTap;

  const _GroupCircleButton({
    required this.emoji,
    required this.active,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.orange : Colors.grey.shade300,
          border: Border.all(
            color: active ? Colors.orange : Colors.grey,
            width: 2,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 24,
            color: active ? Colors.black : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 