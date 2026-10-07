import 'package:youtube_saver/core/errors/failure.dart';
import 'package:youtube_saver/core/errors/result.dart';
import 'package:youtube_saver/data/folder/folder_model.dart';

const int maxFolderNameLength = 60;

/// Trims [raw] and checks it against the folder rules. [siblings] are the
/// folders in the same parent; [exceptId] is the folder being renamed, so it
/// does not clash with itself.
Result<String> validateFolderName(
  String raw,
  List<FolderModel> siblings, {
  String? exceptId,
}) {
  final name = raw.trim();
  if (name.isEmpty) return const Err(ValidationFailure('name_required'));
  if (name.length > maxFolderNameLength) {
    return const Err(ValidationFailure('name_too_long'));
  }
  final taken = siblings.any(
    (f) => f.id != exceptId && f.name.toLowerCase() == name.toLowerCase(),
  );
  if (taken) return const Err(ValidationFailure('name_taken'));
  return Ok(name);
}
