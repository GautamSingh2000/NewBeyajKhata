import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:byaj_khata_book/core/theme/AppColors.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;

  /// NEW → allows parent to override what happens when menu is tapped
  final VoidCallback? onMenuTap;

  const TopAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.height = kToolbarHeight + 8,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primaryColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      centerTitle: false,
      leadingWidth: 56,

      // ---------------- LEADING ICON ----------------
      leading: Builder(
        builder: (context) => IconButton(
          icon: SvgPicture.asset(
            showBackButton
                ? "assets/icons/left_icon.svg"
                : "assets/icons/menu_icon.svg",
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),

          onPressed: () {
            if (showBackButton) {
              Navigator.pop(context);
            } else {
              // If GlobalScreen passes a menu handler → use it
              if (onMenuTap != null) {
                onMenuTap!();
              } else {
                // default behaviour → open drawer safely
                Scaffold.of(context).openDrawer();
              }
            }
          },
        ),
      ),

      // ---------------- TITLE ----------------
      title: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * 0.7,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),

      // ---------------- ACTIONS ----------------
      actions: actions
          ?.map(
            (w) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 36),
            child: FittedBox(child: w),
          ),
        ),
      )
          .toList() ??
          [
            const SizedBox(width: 8),
          ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
