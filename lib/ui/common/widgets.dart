import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/app_data.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

final Map<String, Uint8List> _imageCache = {};

Uint8List? decodePhoto(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  final key = '${base64Str.length}:${base64Str.hashCode}';
  return _imageCache.putIfAbsent(key, () {
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return Uint8List(0);
    }
  });
}

/// Foto do pet ou ilustração padrão por espécie.
class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.pet, this.size = 56, this.radius = 16});
  final Pet? pet;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = decodePhoto(pet?.fotoBase64);
    Widget content;
    if (bytes != null && bytes.isNotEmpty) {
      content = Image.memory(bytes, fit: BoxFit.cover, width: size, height: size, gaplessPlayback: true);
    } else {
      final especie = pet?.especie ?? Species.outro;
      final bg = switch (especie) {
        Species.cachorro => AppColors.beige,
        Species.gato => AppColors.sageLight,
        Species.outro => AppColors.lilac,
      };
      content = Container(
        color: bg,
        alignment: Alignment.center,
        child: Icon(
          especie == Species.gato ? Icons.pets_outlined : Icons.pets,
          size: size * 0.45,
          color: AppColors.sageDark,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: content),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 44});
  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.sage,
      child: Text(user?.initials ?? '?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * 0.38)),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  factory StatusChip.appointment(AppointmentStatus s) => StatusChip(label: s.label, color: s.color);
  factory StatusChip.payment(PaymentStatus s) => StatusChip(label: s.label, color: s.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.height = 6});
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: AppColors.beige.withOpacity(0.6),
        valueColor: const AlwaysStoppedAnimation(AppColors.sage),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.sageLight, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: AppColors.sageDark),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 18});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = value >= i + 1
            ? Icons.star_rounded
            : (value > i ? Icons.star_half_rounded : Icons.star_outline_rounded);
        return Icon(icon, size: size, color: AppColors.warning);
      }),
    );
  }
}

class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Ruim', 'Regular', 'Bom', 'Muito bom', 'Excelente'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return IconButton(
              iconSize: 40,
              tooltip: '${i + 1} estrela${i == 0 ? '' : 's'}',
              onPressed: () => onChanged(i + 1),
              icon: Icon(value > i ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.warning),
            );
          }),
        ),
        Text(value == 0 ? 'Toque para avaliar' : labels[value - 1],
            style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.subtitle,
    this.onTap,
  });
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
                  if (icon != null) Icon(icon, size: 18, color: AppColors.sageDark),
                ],
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.ink)),
              ),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.sage),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color = AppColors.sageLight,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: danger ? AppColors.danger.withOpacity(0.1) : color, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: danger ? AppColors.danger : AppColors.sageDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: danger ? AppColors.danger : AppColors.ink)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (!danger) const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Grade responsiva simples: 2 colunas no celular, mais em telas largas.
int responsiveColumns(BuildContext context, {double itemWidth = 180}) {
  final w = MediaQuery.of(context).size.width.clamp(0, 1100).toDouble();
  return (w / itemWidth).floor().clamp(2, 5).toInt();
}

/// Badge de não lidas para ícones da barra de navegação.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      backgroundColor: AppColors.danger,
      child: Icon(icon),
    );
  }
}
