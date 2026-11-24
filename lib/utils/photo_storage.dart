import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String photoBucket = 'pod_images';
const int _signedUrlTtlSeconds = 3600;
const Duration _refreshMargin = Duration(minutes: 5);

const _publicMarker = '/storage/v1/object/public/$photoBucket/';
const _signMarker = '/storage/v1/object/sign/$photoBucket/';

/// Mengubah nilai yang tersimpan (path storage, URL publik lama, URL signed)
/// menjadi path di bucket. Null jika bukan referensi storage.
String? storagePathFromValue(String? v) {
  if (v == null || v.isEmpty) return null;
  if (v.startsWith('http')) {
    for (final marker in [_publicMarker, _signMarker]) {
      final i = v.indexOf(marker);
      if (i >= 0) {
        var path = v.substring(i + marker.length);
        final q = path.indexOf(RegExp(r'[?#]'));
        if (q >= 0) path = path.substring(0, q);
        if (path.isEmpty) return null;
        return Uri.decodeComponent(path);
      }
    }
    return null;
  }
  if (v.startsWith('/') || v.startsWith('file://')) return null;
  return v;
}

/// True jika nilai adalah file lokal (perlu diupload).
bool isLocalFile(String? v) =>
    v != null && (v.startsWith('/') || v.startsWith('file://'));

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
}

/// Resolver signed URL dengan cache memori dan dedupe request.
class SignedUrlResolver {
  SignedUrlResolver._();
  static final SignedUrlResolver instance = SignedUrlResolver._();

  final Map<String, _CachedUrl> _cache = {};
  final Map<String, Future<String>> _inflight = {};

  Future<String> resolve(String path) {
    final cached = _cache[path];
    if (cached != null &&
        DateTime.now().isBefore(cached.expiresAt.subtract(_refreshMargin))) {
      return Future.value(cached.url);
    }
    return _inflight[path] ??= _fetch(path).whenComplete(() => _inflight.remove(path));
  }

  Future<String> _fetch(String path) async {
    final url = await Supabase.instance.client.storage
        .from(photoBucket)
        .createSignedUrl(path, _signedUrlTtlSeconds);
    _cache[path] = _CachedUrl(
        url, DateTime.now().add(const Duration(seconds: _signedUrlTtlSeconds)));
    return url;
  }

  void clear() {
    _cache.clear();
  }
}

/// Menampilkan foto dari nilai tersimpan: file lokal atau path/URL storage.
class StoragePhoto extends StatefulWidget {
  final String value;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const StoragePhoto({
    super.key,
    required this.value,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<StoragePhoto> createState() => _StoragePhotoState();
}

class _StoragePhotoState extends State<StoragePhoto> {
  Future<String>? _future;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(StoragePhoto old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _prepare();
  }

  void _prepare() {
    final path = isLocalFile(widget.value) ? null : storagePathFromValue(widget.value);
    _future = path == null ? null : SignedUrlResolver.instance.resolve(path);
  }

  Widget get _error => widget.errorWidget ??
      const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey));

  Widget get _loading => widget.placeholder ??
      const Center(
          child: SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    if (isLocalFile(v)) {
      final path = v.startsWith('file://') ? Uri.parse(v).toFilePath() : v;
      return Image.file(File(path),
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, _, _) => _error);
    }
    final future = _future;
    if (future == null) return _error;
    return FutureBuilder<String>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return _error;
        if (!snap.hasData) return _loading;
        return Image(
          image: NetworkImage(snap.data!),
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          loadingBuilder: (_, child, progress) => progress == null ? child : _loading,
          errorBuilder: (_, _, _) => _error,
        );
      },
    );
  }
}
