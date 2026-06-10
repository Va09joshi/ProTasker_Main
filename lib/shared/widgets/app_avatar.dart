import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/theme.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isOnline;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isVerified;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.backgroundColor,
    this.textColor,
    this.isVerified = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.accent.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );

    List<Widget> stackChildren = [avatar];

    if (showOnlineIndicator) {
      stackChildren.add(
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.textTertiary,
              border: Border.all(color: Colors.white, width: size > 50 ? 2 : 1.5),
            ),
          ),
        ),
      );
    }

    if (isVerified) {
      stackChildren.add(
        Positioned(
          left: -2,
          top: -2,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified, 
              color: Colors.blueAccent, 
              size: size * 0.35,
            ),
          ),
        ),
      );
    }

    Widget finalWidget = stackChildren.length > 1 
      ? Stack(clipBehavior: Clip.none, children: stackChildren) 
      : avatar;

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: finalWidget);
    }
    return finalWidget;
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.accent,
        ),
      ),
    );
  }
}
