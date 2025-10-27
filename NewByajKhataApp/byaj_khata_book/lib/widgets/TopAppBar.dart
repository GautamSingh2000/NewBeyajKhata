import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:byaj_khata_book/core/theme/AppColors.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double height;

  const TopAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.height = kToolbarHeight + 8,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // avoid duplicate back icon
      backgroundColor: AppColors.primaryColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      centerTitle: false,
      leadingWidth: 56, // ✅ keeps spacing consistent

      // ✅ Leading icon (menu/back)
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
              Scaffold.of(context).openDrawer();
            }
          },
        ),
      ),

      // ✅ Title (flexible width)
      title: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth * 0.7, // keeps text safe
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),

      // ✅ Compact actions (fixed padding, safe in narrow screens)
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
          [const SizedBox(width: 8)],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
