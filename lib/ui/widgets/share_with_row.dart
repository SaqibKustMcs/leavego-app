import 'package:flutter/material.dart';
import 'package:leavego_app/models/users_response.dart';

class ShareWithRow extends StatelessWidget {
  const ShareWithRow({
    super.key,
    required this.usersLoading,
    required this.usersAvailable,
    required this.selectedUsers,
    required this.onTap,
    this.label = 'Share with',
  });

  final bool usersLoading;
  final bool usersAvailable;
  final List<AppUserItem> selectedUsers;
  final VoidCallback? onTap;
  final String label;

  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFEEF4F2);

  static const List<Color> _avatarColors = <Color>[
    Color(0xFF7986CB),
    Color(0xFF4DB6AC),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
  ];

  Color _avatarColor(int id) => _avatarColors[id % _avatarColors.length];

  String _initial(AppUserItem user) {
    final name = user.name.trim();
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final extraCount = selectedUsers.length > 1 ? selectedUsers.length - 1 : 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _fieldBorder, width: 0.5),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E6E6E),
                ),
              ),
              const Spacer(),
              if (usersLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                )
              else if (selectedUsers.isNotEmpty) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _avatarColor(selectedUsers.first.id),
                      child: Text(
                        _initial(selectedUsers.first),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (extraCount > 0)
                      Positioned(
                        right: -20,
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFE5F1FE),
                              child: Text(
                                '+$extraCount',
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ] else
                Text(
                  usersAvailable ? 'Select' : 'No users',
                  style: const TextStyle(color: Color(0xFF6A778B), fontSize: 14),
                ),
              const SizedBox(width: 17),
              const Icon(Icons.chevron_right_rounded, color: _primary),
            ],
          ),
        ),
      ),
    );
  }
}
