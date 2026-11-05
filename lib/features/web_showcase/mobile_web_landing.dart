import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing page displayed on mobile web (< 900px) instead of the full app.
/// Highlights key app details from the desktop edition's left pane and provides
/// a direct download link to the GitHub release APK.
class MobileWebLanding extends StatefulWidget {
  final Widget? previewChild;

  const MobileWebLanding({super.key, this.previewChild});

  static const String githubReleaseUrl =
      'https://github.com/RanjanKiran707/youtube-video-organizer/releases/tag/v1.0.0';
  static const String apkDownloadUrl =
      'https://github.com/RanjanKiran707/youtube-video-organizer/releases/download/v1.0.0/app-release.apk';
  static const String githubRepoUrl =
      'https://github.com/RanjanKiran707/youtube-video-organizer';

  @override
  State<MobileWebLanding> createState() => _MobileWebLandingState();
}

class _MobileWebLandingState extends State<MobileWebLanding> {
  bool _showWebPreview = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebPreview && widget.previewChild != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0C0E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141417),
          title: const Text(
            'Interactive Web Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _showWebPreview = false),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Get APK'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A54),
              ),
              onPressed: () => _openUrl(MobileWebLanding.apkDownloadUrl),
            ),
          ],
        ),
        body: widget.previewChild!,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildHeadline(),
                  const SizedBox(height: 14),
                  _buildDescription(),
                  const SizedBox(height: 28),
                  _buildDownloadCard(),
                  const SizedBox(height: 32),
                  _buildFeatureSection(),
                  const SizedBox(height: 32),
                  _buildHowItWorks(),
                  if (widget.previewChild != null) ...[
                    const SizedBox(height: 28),
                    _buildPreviewBanner(),
                  ],
                  const SizedBox(height: 36),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5A54).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/app_icon.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF111111),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YT Playlist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Android App · v1.0.0 Release',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'GitHub Repository',
          icon: const Icon(Icons.code_rounded, color: Color(0xFF8E8E93)),
          onPressed: () => _openUrl(MobileWebLanding.githubRepoUrl),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return const Text(
      'Organize YouTube.\nZero distractions.',
      style: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.6,
      ),
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Save YouTube videos into custom nested folders, queue them up, '
      'and watch them in order — with no algorithmic recommendations, '
      'no comment sections, and no rabbit holes.',
      style: TextStyle(
        fontSize: 15,
        height: 1.55,
        color: Color(0xFFA1A1AA),
      ),
    );
  }

  Widget _buildDownloadCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26262B)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5A54).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A54).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.android_rounded,
                  color: Color(0xFFFF5A54),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Get YT Playlist for Android',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Direct APK · 56 MB · Android 8.0+',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A54),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Download APK (v1.0.0)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            onPressed: () => _openUrl(MobileWebLanding.apkDownloadUrl),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2C2C33)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text(
              'View GitHub Release Notes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            onPressed: () => _openUrl(MobileWebLanding.githubReleaseUrl),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Color(0xFF71717A),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'After downloading, open the APK and choose "Install". If prompted by your browser, enable "Install unknown apps".',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Features',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71717A),
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 14),
        _FeatureTile(
          icon: Icons.folder_copy_outlined,
          title: 'Custom Nested Folders',
          description:
              'Group study materials, music playlists, or video series into organized hierarchies to any depth.',
        ),
        SizedBox(height: 12),
        _FeatureTile(
          icon: Icons.playlist_play_rounded,
          title: 'Continuous Playback',
          description:
              'Auto-advances to the next video when finished. Queue your videos and play seamlessly.',
        ),
        SizedBox(height: 12),
        _FeatureTile(
          icon: Icons.visibility_off_outlined,
          title: 'Distraction-Free Player',
          description:
              'No algorithm-driven recommendations, sidebar rabbit holes, or distracting comments.',
        ),
        SizedBox(height: 12),
        _FeatureTile(
          icon: Icons.storage_rounded,
          title: 'Local-First SQLite Storage',
          description:
              'Private, lightning-fast on-device database powered by Drift. No account or cloud sync required.',
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222226)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 14),
          _StepRow(
            number: '1',
            title: 'Share from YouTube',
            subtitle:
                'Tap Share on any YouTube video and choose YT Playlist from the Android share sheet.',
          ),
          SizedBox(height: 12),
          _StepRow(
            number: '2',
            title: 'Pick your folder',
            subtitle:
                'Choose an existing folder or create a new nested folder on the spot.',
          ),
          SizedBox(height: 12),
          _StepRow(
            number: '3',
            title: 'Watch distraction-free',
            subtitle:
                'Open YT Playlist to watch your saved videos sequentially with full queue control.',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161619),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF26262B)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.laptop_chromebook_rounded,
            size: 20,
            color: Color(0xFF8E8E93),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Desktop Interactive Demo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'For phone mockup & sample demo, visit on desktop.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              foregroundColor: const Color(0xFFFF5A54),
            ),
            child: const Text('Preview', style: TextStyle(fontSize: 12)),
            onPressed: () => setState(() => _showWebPreview = true),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _Badge(label: 'Flutter'),
            _Badge(label: 'SQLite / Drift'),
            _Badge(label: 'Clean Architecture'),
            _Badge(label: '93 Tests'),
            _Badge(label: 'MIT License'),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _openUrl(MobileWebLanding.githubRepoUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.link_rounded, size: 14, color: Color(0xFF71717A)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'github.com/RanjanKiran707/youtube-video-organizer',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF71717A),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222226)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2C2C32)),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFFF5A54)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5A54).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF5A54),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161619),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF26262B)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF71717A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
