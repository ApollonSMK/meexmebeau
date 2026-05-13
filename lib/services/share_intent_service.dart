import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Handles incoming share intents from other apps (e.g. M7 Scanner)
class ShareIntentService {
  StreamSubscription? _mediaSubscription;
  StreamSubscription? _textSubscription;

  /// Callback when shared data is received
  final void Function(SharedData data)? onDataReceived;

  ShareIntentService({this.onDataReceived});

  /// Initialize listeners for incoming shares
  void initialize() {
    // Listen for shared media/files while app is running
    _mediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
      onError: (err) {
        debugPrint('ShareIntent media error: $err');
      },
    );

    // Get initial media if app was launched by share
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleSharedMedia);
  }

  void _handleSharedMedia(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    for (final file in files) {
      final path = file.path;
      final mimeType = file.mimeType ?? '';
      final type = file.type;

      debugPrint('Received shared file: $path (type: $type, mime: $mimeType)');

      if (type == SharedMediaType.text || file.path.isEmpty) {
        // Text content shared
        onDataReceived?.call(
          SharedData(
            type: SharedDataType.text,
            content: file.message ?? file.path,
          ),
        );
      } else if (mimeType.contains('pdf') || path.endsWith('.pdf')) {
        // PDF file shared
        onDataReceived?.call(
          SharedData(type: SharedDataType.pdf, filePath: path),
        );
      } else if (type == SharedMediaType.image || mimeType.contains('image')) {
        // Image file shared
        _handleImage(path);
      } else {
        // Unknown file - try to read as text
        _handleGenericFile(path);
      }
    }

    // Reset sharing intent
    ReceiveSharingIntent.instance.reset();
  }

  void _handleImage(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final base64 = base64Encode(bytes);
        onDataReceived?.call(
          SharedData(
            type: SharedDataType.image,
            filePath: path,
            base64Content: base64,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reading image: $e');
    }
  }

  void _handleGenericFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        onDataReceived?.call(
          SharedData(
            type: SharedDataType.text,
            content: content,
            filePath: path,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reading file as text: $e');
      // If can't read as text, send as binary
      onDataReceived?.call(
        SharedData(type: SharedDataType.unknown, filePath: path),
      );
    }
  }

  void dispose() {
    _mediaSubscription?.cancel();
    _textSubscription?.cancel();
  }
}

enum SharedDataType { text, pdf, image, unknown }

class SharedData {
  final SharedDataType type;
  final String? content;
  final String? filePath;
  final String? base64Content;

  SharedData({
    required this.type,
    this.content,
    this.filePath,
    this.base64Content,
  });

  bool get isText => type == SharedDataType.text;
  bool get isPdf => type == SharedDataType.pdf;
  bool get isImage => type == SharedDataType.image;

  @override
  String toString() =>
      'SharedData(type: $type, hasContent: ${content != null}, hasFile: ${filePath != null})';
}
