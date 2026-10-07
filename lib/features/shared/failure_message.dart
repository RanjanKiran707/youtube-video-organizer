import 'package:youtube_saver/core/errors/failure.dart';

/// The text shown to the user for a failure, chosen from its type and code.
String messageFor(Failure failure) {
  return switch (failure) {
    ValidationFailure(:final message) => switch (message) {
      'name_required' => 'Enter a name.',
      'name_too_long' => 'That name is too long (60 characters at most).',
      'name_taken' => 'A folder with that name already exists here.',
      'title_required' => 'Enter a title.',
      'move_into_itself' => "A folder can't be moved into itself.",
      'reorder_mismatch' => 'The list changed. Try again.',
      'not_a_youtube_video' => "That isn't a link to a YouTube video.",
      _ => 'That is not allowed.',
    },
    NetworkFailure() => 'No connection. Try again.',
    StorageFailure() => "Couldn't read or save your library. Try again.",
    UnexpectedFailure() => 'Something went wrong. Try again.',
  };
}
