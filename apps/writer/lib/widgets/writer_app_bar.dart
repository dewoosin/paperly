import 'package:flutter/material.dart';
import '../theme/writer_theme.dart';

class WriterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const WriterAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: WriterTheme.titleStyle.copyWith(
          color: foregroundColor ?? WriterTheme.neutralGray900,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? WriterTheme.neutralGray900,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1,
      floating: true,
      snap: true,
      leading: leading ?? (showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: WriterTheme.neutralGray200,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class SimpleWriterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SimpleWriterAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: WriterTheme.titleStyle.copyWith(
          color: foregroundColor ?? WriterTheme.neutralGray900,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? WriterTheme.neutralGray900,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: leading ?? (showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: WriterTheme.neutralGray200,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}