import 'dart:typed_data';

import 'package:app_frontend/core/api/api_exception.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_models.dart';
import 'package:app_frontend/core/wanderbook/wanderbook_service.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/common.dart';
import 'package:app_frontend/features/08_wanderbook/widgets/place_fields.dart';
import 'package:app_frontend/global_utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _maxPhotos = 10;

/// Same as the backend's limit (goawaygo.media.max-photo-bytes).
const _maxPhotoBytes = 20000000;

class _Selected {
  _Selected(this.bytes, this.name);

  final Uint8List bytes;
  final String name;
  Photo? photo;
  String? error;

  bool get uploading => photo == null && error == null;
}

/// New post: 1 to 10 photos (uploaded as the original files, one by one, while you write), a caption and a place
/// tag filled in from the first photo's location.
class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _caption = TextEditingController();
  final _selected = <_Selected>[];
  PlaceTag? _place;
  bool _placeFromPhoto = false;
  bool _placeTouched = false;
  bool _posting = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final room = _maxPhotos - _selected.length;
    // No resizing or recompression: the files come exactly as they are.
    final files = await ImagePicker().pickMultiImage(
      limit: room < 2 ? 2 : room,
    );
    if (files.isEmpty) return;
    if (files.length > room && mounted) {
      showError(context, 'A post has up to $_maxPhotos photos.');
    }
    final batch = <_Selected>[];
    for (final file in files.take(room)) {
      batch.add(_Selected(await file.readAsBytes(), file.name));
    }
    setState(() => _selected.addAll(batch));
    // One at a time: originals can be large.
    for (final item in batch) {
      if (item.bytes.length > _maxPhotoBytes) {
        setState(() => item.error = 'Photos can be up to 20 MB.');
        continue;
      }
      try {
        final uploaded = await WanderbookService.uploadPhoto(
          item.bytes,
          item.name,
        );
        if (!mounted) return;
        setState(() {
          item.photo = uploaded.photo;
          if (uploaded.suggestedPlace != null && !_placeTouched) {
            _placeTouched = true;
            _place = uploaded.suggestedPlace;
            _placeFromPhoto = true;
          }
        });
      } on ApiException catch (error) {
        if (mounted) setState(() => item.error = error.message);
      }
    }
  }

  Future<void> _share() async {
    setState(() => _posting = true);
    try {
      await WanderbookService.createPost(
        photoIds: [
          for (final item in _selected)
            if (item.photo != null) item.photo!.id,
        ],
        caption: _caption.text.trim(),
        place: _place,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) {
        showError(context, error);
        setState(() => _posting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _selected.where((item) => item.photo != null).length;
    final busy = _selected.any((item) => item.uploading);
    return Scaffold(
      backgroundColor: ColorsUtil.primary,
      appBar: AppBar(
        backgroundColor: ColorsUtil.primary,
        foregroundColor: Colors.white,
        title: const Text('New post'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final item in _selected)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(item.bytes, fit: BoxFit.cover),
                      ),
                      if (item.photo == null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black54,
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              item.error ?? 'Uploading…',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton.filled(
                          tooltip: 'Remove ${item.name}',
                          iconSize: 16,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                              setState(() => _selected.remove(item)),
                        ),
                      ),
                    ],
                  ),
                if (_selected.length < _maxPhotos)
                  OutlinedButton(
                    onPressed: _pick,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo),
                        Text(_selected.isEmpty ? 'Add photos' : 'Add more'),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Photos are kept exactly as they are. Their hidden location data is removed; only the place name '
              'below is shown.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              maxLength: 2200,
              maxLines: 6,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write about this trip…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            PlaceFields(
              value: _place,
              fromPhoto: _placeFromPhoto,
              onChanged: (place) => setState(() {
                _placeTouched = true;
                _placeFromPhoto = false;
                _place = place;
              }),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: _posting
                  ? 'Posting…'
                  : busy
                  ? 'Uploading photos…'
                  : 'Share',
              onPressed: ready == 0 || busy || _posting ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}
