import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Text that other apps share to this one (a YouTube link, usually).
abstract interface class ShareSource {
  /// The text that started the app, if it was opened by a share.
  Future<String?> initialText();

  /// Text shared while the app is running.
  Stream<String> texts();
}

class ReceiveSharingIntentShareSource implements ShareSource {
  @override
  Future<String?> initialText() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    // Mark it handled, so a restart of the app does not open it again.
    await ReceiveSharingIntent.instance.reset();
    return _firstText(files);
  }

  @override
  Stream<String> texts() {
    return ReceiveSharingIntent.instance
        .getMediaStream()
        .map(_firstText)
        .where((text) => text != null)
        .cast<String>();
  }

  String? _firstText(List<SharedMediaFile> files) {
    for (final file in files) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        return file.path;
      }
    }
    return null;
  }
}

/// A source that never shares anything, for tests and platforms without sharing.
class NoShareSource implements ShareSource {
  const NoShareSource();

  @override
  Future<String?> initialText() async => null;

  @override
  Stream<String> texts() => const Stream.empty();
}
