import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/workshop_ui.dart';

class AccountIntro extends StatelessWidget {
  const AccountIntro({
    super.key,
    required this.art,
    required this.title,
    required this.description,
  });
  final WorkshopArt art;
  final String title, description;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
        WorkshopIllustration(art, height: 152),
        const SizedBox(height: 24),
      ],
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        description,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.primary),
      ),
    ],
  );
}

class AccountNotice extends StatelessWidget {
  const AccountNotice({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.mail_outline,
    this.tinted = false,
  });
  final String title, description;
  final IconData icon;
  final bool tinted;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: tinted ? AppColors.blueSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.blueBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(description),
            ],
          ),
        ),
      ],
    ),
  );
}

class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    required this.label,
    required this.email,
  });
  final String label, email;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 142,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              bottom: 20,
              child: ClipPath(
                clipper: _AccountHeaderWave(),
                child: const ColoredBox(color: AppColors.secondary),
              ),
            ),
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 41,
                backgroundColor: AppColors.blueSurface,
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.secondary,
                  size: 62,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SelectableText(email, textAlign: TextAlign.center),
      ),
      const SizedBox(height: 24),
    ],
  );
}

class _AccountHeaderWave extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .82)
    ..cubicTo(
      size.width * .3,
      size.height * .54,
      size.width * .68,
      size.height * 1.18,
      size.width,
      size.height * .8,
    )
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(_AccountHeaderWave oldClipper) => false;
}
