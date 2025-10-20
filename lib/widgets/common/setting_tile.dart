import 'package:flutter/material.dart';

/// 설정 타일 위젯
class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: enabled 
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      subtitle: subtitle != null
        ? Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: enabled 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          )
        : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}
