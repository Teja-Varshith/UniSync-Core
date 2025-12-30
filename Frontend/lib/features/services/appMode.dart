
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/models/user_model.dart';

enum AppMode { campus, career, builder }

final AppModeProvider = StateProvider<AppMode>((ref) => AppMode.campus);


class AvatarSlideToggle extends ConsumerStatefulWidget {
  final ValueChanged<AppMode>? onModeChanged;
  final AppMode currentMode;
  final UserModel user;
  final List<AppMode> menu;

  const AvatarSlideToggle({
    super.key,
    this.onModeChanged,
    required this.currentMode,
    required this.user,
    required this.menu
  });

  @override
  ConsumerState<AvatarSlideToggle> createState() => _AvatarSlideToggleState();
}

class _AvatarSlideToggleState extends ConsumerState<AvatarSlideToggle> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        
        
        // Mode Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppMode>(
              value: widget.currentMode,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
              dropdownColor: Colors.black,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              items: widget.menu.map((mode) {
                return DropdownMenuItem<AppMode>(
                  value: mode,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode == AppMode.campus ? Icons.school : (mode == AppMode.career) ? Icons.work : Icons.build,


                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode == AppMode.campus ? 'Campus' : (mode == AppMode.career) ? 'Career' : 'Builder',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (AppMode? newMode) {
                if (newMode != null) {
                  widget.onModeChanged?.call(newMode);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}