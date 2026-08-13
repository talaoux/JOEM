import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Visionneuse plein écran (fond noir, zoom/pan via `InteractiveViewer`)
/// pour une photo de profil — partagée entre `JobProfileScreen` (photo du
/// candidat connecté) et `ProfileSidePanel` (avatar affiché dans le
/// panneau latéral du dashboard).
class ProfilePhotoViewerScreen extends StatelessWidget {
  const ProfilePhotoViewerScreen({
    super.key,
    this.imageBytes,
    this.fallbackAsset = 'assets/images/avatar_portfolio1.jpg',
  });

  final Uint8List? imageBytes;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imageBytes != null
                    ? Image.memory(imageBytes!)
                    : Image.asset(fallbackAsset),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}