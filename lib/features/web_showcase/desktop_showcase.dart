import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_saver/features/web_showcase/phone_bezel.dart';

class DesktopShowcase extends StatefulWidget {
  final Widget child;

  const DesktopShowcase({super.key, required this.child});

  @override
  State<DesktopShowcase> createState() => _DesktopShowcaseState();
}

class _DesktopShowcaseState extends State<DesktopShowcase> {
  String? _copiedUrl;

  final List<_SampleVideo> _samples = const [
    _SampleVideo(
      title: 'Ambient Relaxing Music',
      channel: 'Soothing Relaxation',
      url: 'https://www.youtube.com/watch?v=2OEL4P1Rz04',
      icon: Icons.music_note_rounded,
    ),
    _SampleVideo(
      title: 'Big Buck Bunny 4K',
      channel: 'Blender Foundation',
      url: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
      icon: Icons.movie_filter_rounded,
    ),
    _SampleVideo(
      title: 'Sintel (Open Movie)',
      channel: 'Blender Foundation',
      url: 'https://www.youtube.com/watch?v=eRsGyueVLvQ',
      icon: Icons.animation_rounded,
    ),
  ];

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    setState(() => _copiedUrl = url);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Link copied! Click "+ Add video" inside the phone to paste it.',
            ),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _copiedUrl == url) {
        setState(() => _copiedUrl = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      body: Row(
        children: [
          // Left Pane: App details, branding, features and sample videos.
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF1E1E22), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildHeadline(),
                        const SizedBox(height: 16),
                        _buildDescription(),
                        const SizedBox(height: 24),
                        _buildDownloadCta(),
                        const SizedBox(height: 32),
                        _buildFeatureGrid(),
                        const SizedBox(height: 36),
                        _buildSampleVideosCard(),
                        const SizedBox(height: 36),
                        _buildFooterBadges(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Pane: Live interactive phone bezel.
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF09090B),
              padding: const EdgeInsets.all(28),
              child: PhoneBezel(child: widget.child),
            ),
          ),
        ],
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
        Column(
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
                  'Interactive Web Demo',
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
      ],
    );
  }

  Widget _buildHeadline() {
    return const Text(
      'Organize YouTube.\nZero distractions.',
      style: TextStyle(
        fontSize: 34,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.8,
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
        height: 1.6,
        color: Color(0xFFA1A1AA),
      ),
    );
  }

  Widget _buildDownloadCta() {
    const apkUrl =
        'https://github.com/RanjanKiran707/youtube-video-organizer/releases/download/v1.0.0/app-release.apk';
    const releaseUrl =
        'https://github.com/RanjanKiran707/youtube-video-organizer/releases/tag/v1.0.0';

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A54),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text(
            'Download APK (v1.0.0)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          onPressed: () => launchUrl(
            Uri.parse(apkUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2C2C33)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text(
            'GitHub Release',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          onPressed: () => launchUrl(
            Uri.parse(releaseUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      children: const [
        _FeatureRow(
          icon: Icons.folder_copy_outlined,
          title: 'Custom Nested Folders',
          description:
              'Group your study materials, music playlists, or video series into organized folders.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.playlist_play_rounded,
          title: 'Continuous Playback',
          description:
              'Auto-advances to the next video when finished. Drag-and-drop or reorder on the fly.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.visibility_off_outlined,
          title: 'Distraction-Free Player',
          description:
              'Only your saved videos. Stripped of distracting comments, sidebars, and autoplay recommendations.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: Icons.storage_rounded,
          title: 'Local-First SQLite Storage',
          description:
              'Fast and private local database powered by Drift and SQLite WebAssembly.',
        ),
      ],
    );
  }

  Widget _buildSampleVideosCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26262B)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.touch_app_rounded, color: Color(0xFFFF5A54), size: 18),
              SizedBox(width: 8),
              Text(
                'Try the live demo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Copy a sample link below, then click "+ Add video" inside the phone preview to save it:',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
          ),
          const SizedBox(height: 16),
          Column(
            children: _samples.map((sample) {
              final isCopied = _copiedUrl == sample.url;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCopied
                        ? const Color(0xFFFF5A54).withValues(alpha: 0.6)
                        : const Color(0xFF2A2A30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(sample.icon, size: 20, color: const Color(0xFFFF5A54)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sample.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            sample.channel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: isCopied
                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                            : const Color(0xFF27272A),
                        foregroundColor: isCopied
                            ? const Color(0xFF22C55E)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 14,
                      ),
                      label: Text(
                        isCopied ? 'Copied' : 'Copy link',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _copyUrl(sample.url),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _Badge(label: 'Flutter Web'),
        _Badge(label: 'SQLite Wasm'),
        _Badge(label: 'Drift 2.31'),
        _Badge(label: 'Clean Architecture'),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFFF5A54)),
        ),
        const SizedBox(width: 14),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleVideo {
  final String title;
  final String channel;
  final String url;
  final IconData icon;

  const _SampleVideo({
    required this.title,
    required this.channel,
    required this.url,
    required this.icon,
  });
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
