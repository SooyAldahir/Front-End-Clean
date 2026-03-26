import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../core/utils/url_helper.dart';
import '../../tools/fullscreen_image_viewer.dart';

// ─── ResponsiveContent ────────────────────────────────────────────────────────
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveContent({super.key, required this.child, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

// ─── NetworkImageWithFallback ─────────────────────────────────────────────────
/// Carga una imagen de red con fallback a un asset local.
/// Nunca lanza excepción ni desborda el layout.
class NetworkImageWithFallback extends StatelessWidget {
  final String? url;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageWithFallback({
    super.key,
    required this.url,
    required this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final absUrl = toAbsoluteUrl(url);
    if (absUrl.isEmpty) {
      return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
    }
    return Image.network(
      absUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          Image.asset(fallbackAsset, width: width, height: height, fit: fit),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(fallbackAsset, width: width, height: height, fit: fit),
            child,
          ],
        );
      },
    );
  }
}

// ─── AvatarWidget ─────────────────────────────────────────────────────────────
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String fallbackAsset;
  final String? heroTag;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 30,
    this.fallbackAsset = 'assets/img/7141724.png',
    this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final absUrl = toAbsoluteUrl(imageUrl);
    final tag    = heroTag ?? 'avatar_${imageUrl.hashCode}';

    final ImageProvider provider = absUrl.isNotEmpty
        ? NetworkImage(absUrl)
        : AssetImage(fallbackAsset) as ImageProvider;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image(
          image: provider,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            fallbackAsset,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    if (heroTag != null) avatar = Hero(tag: tag, child: avatar);

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }
}

// ─── AppButton ────────────────────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width ?? double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor ?? Colors.black,
                  ),
                ),
        ),
      );
}

// ─── ScrollHideAppBarScaffold ─────────────────────────────────────────────────
class ScrollHideAppBarScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool automaticallyImplyLeading;

  const ScrollHideAppBarScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.backgroundColor = AppColors.primary,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              title: Text(title),
              backgroundColor: backgroundColor,
              elevation: 0,
              floating: true,
              snap: true,
              actions: actions,
              automaticallyImplyLeading: automaticallyImplyLeading,
            ),
          ],
          body: body,
        ),
      );
}
